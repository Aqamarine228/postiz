#!/usr/bin/env sh
set -eu

create_volume() {
  name="$1"
  if docker volume inspect "$name" >/dev/null 2>&1; then
    echo "volume exists: $name"
    return
  fi

  echo "creating volume: $name"
  docker volume create "$name" >/dev/null
}

create_volume postiz-postgres-data
create_volume postiz-redis-data
create_volume temporal-elasticsearch-data
create_volume temporal-postgres-data
create_volume postiz-config
create_volume postiz-uploads

echo "done"
