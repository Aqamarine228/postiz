#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[backup] %s\n' "$*"
}

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    log "missing required env: ${name}"
    exit 1
  fi
}

aws_cp() {
  local source_file="$1"
  local destination_key="$2"

  if [[ -n "${AWS_ENDPOINT_URL:-}" ]]; then
    aws --endpoint-url "${AWS_ENDPOINT_URL}" s3 cp "${source_file}" "s3://${BACKUP_S3_BUCKET}/${destination_key}"
    return
  fi

  aws s3 cp "${source_file}" "s3://${BACKUP_S3_BUCKET}/${destination_key}"
}

dump_cluster() {
  local name="$1"
  local host="$2"
  local user="$3"
  local password="$4"
  local output_file="$5"

  log "dumping ${name} cluster"
  PGPASSWORD="${password}" pg_dumpall \
    --clean \
    --if-exists \
    -h "${host}" \
    -U "${user}" | gzip -9 > "${output_file}"
}

archive_path() {
  local name="$1"
  local source_path="$2"
  local output_file="$3"

  if [[ ! -d "${source_path}" ]]; then
    log "skipping ${name}, path not found: ${source_path}"
    return
  fi

  log "archiving ${name}"
  tar -C "${source_path}" -czf "${output_file}" .
}

backup_once() {
  local timestamp workdir prefix
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  prefix="${BACKUP_S3_PREFIX%/}/${timestamp}"
  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir}"' RETURN

  dump_cluster "postiz" \
    "${POSTIZ_POSTGRES_HOST}" \
    "${POSTIZ_POSTGRES_USER}" \
    "${POSTIZ_POSTGRES_PASSWORD}" \
    "${workdir}/postiz-postgres.sql.gz"

  dump_cluster "temporal" \
    "${TEMPORAL_POSTGRES_HOST}" \
    "${TEMPORAL_POSTGRES_USER}" \
    "${TEMPORAL_POSTGRES_PASSWORD}" \
    "${workdir}/temporal-postgres.sql.gz"

  archive_path "postiz config" "${POSTIZ_CONFIG_PATH}" "${workdir}/postiz-config.tar.gz"
  archive_path "postiz uploads" "${POSTIZ_UPLOADS_PATH}" "${workdir}/postiz-uploads.tar.gz"

  for artifact in "${workdir}"/*; do
    [[ -f "${artifact}" ]] || continue
    aws_cp "${artifact}" "${prefix}/$(basename "${artifact}")"
  done

  log "backup uploaded to s3://${BACKUP_S3_BUCKET}/${prefix}/"
}

main() {
  require_var BACKUP_S3_BUCKET
  require_var POSTIZ_POSTGRES_HOST
  require_var POSTIZ_POSTGRES_USER
  require_var POSTIZ_POSTGRES_PASSWORD
  require_var TEMPORAL_POSTGRES_HOST
  require_var TEMPORAL_POSTGRES_USER
  require_var TEMPORAL_POSTGRES_PASSWORD
  require_var AWS_ACCESS_KEY_ID
  require_var AWS_SECRET_ACCESS_KEY
  require_var AWS_DEFAULT_REGION

  if [[ "${BACKUP_ENABLED:-true}" != "true" ]]; then
    log "backup disabled, sleeping"
    exec tail -f /dev/null
  fi

  while true; do
    if ! backup_once; then
      log "backup run failed"
    fi

    log "sleeping for ${BACKUP_INTERVAL_SECONDS:-86400} seconds"
    sleep "${BACKUP_INTERVAL_SECONDS:-86400}"
  done
}

main "$@"
