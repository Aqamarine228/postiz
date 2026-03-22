# Postiz Deployment Layout

This repository is split into two Docker Compose projects:

- `infra/` holds stateful services and backups.
- `app/` holds the frequently updated Postiz application containers.

Start them in this order:

```sh
cd infra && docker compose up -d --build
cd ../app && docker compose up -d
```

Stop only the application stack when updating Postiz:

```sh
cd app && docker compose pull && docker compose up -d
```

`docker compose down -v` no longer removes PostgreSQL, Redis, Elasticsearch, config, or uploads because they now live in bind-mounted paths under `infra/data/`.

To restore from S3 backups:

1. Download the backup archives from the configured S3 bucket and prefix.
2. Restore PostgreSQL with `gunzip -c <file>.sql.gz | psql ...`.
3. Extract `postiz-config` and `postiz-uploads` archives back into `infra/data/postiz/`.
