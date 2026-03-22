# Postiz Deployment Layout

This repository is split into two Docker Compose projects:

- `infra/` holds stateful services and backups.
- `app/` holds the frequently updated Postiz application containers.

Create the durable Docker volumes once before first boot:

```sh
./infra/init-volumes.sh
```

Start them in this order:

```sh
cd infra && docker compose up -d --build
cd ../app && docker compose up -d
```

Stop only the application stack when updating Postiz:

```sh
cd app && docker compose pull && docker compose up -d
```

`docker compose down -v` no longer removes PostgreSQL, Redis, Elasticsearch, config, or uploads because they now live in external Docker volumes.

To restore from S3 backups:

1. Download the backup archives from the configured S3 bucket and prefix.
2. Restore PostgreSQL with `gunzip -c <file>.sql.gz | psql ...`.
3. Restore `postiz-config` and `postiz-uploads` into the corresponding Docker volumes.
