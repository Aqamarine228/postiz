# n8n with PostgreSQL

This folder runs `n8n` with PostgreSQL in a dedicated Docker Compose project.

## Start

1. Copy the example environment file:

   ```sh
   cd n8n
   cp .env.example .env
   ```

2. Edit `.env` and set:

   - `POSTGRES_PASSWORD`
   - `N8N_ENCRYPTION_KEY`
   - `N8N_HOST`, `N8N_EDITOR_BASE_URL`, and `WEBHOOK_URL` if you will expose n8n outside localhost

3. Boot the stack:

   ```sh
   docker compose up -d
   ```

4. Open `http://localhost:5678` and finish the first-run owner setup.

## Stop

```sh
cd n8n
docker compose down
```

The PostgreSQL data and n8n data stay in Docker volumes:

- `n8n-postgres-data`
- `n8n-data`

## Migrating flows from localhost

If your current localhost instance is also `n8n`, the cleanest migration path is:

1. Reuse the same encryption key.

   - If your old instance already sets `N8N_ENCRYPTION_KEY`, copy that value into this folder's `.env`.
   - If it does not, check your old local n8n config under `~/.n8n` and keep that key value. Without the same key, saved credentials cannot be decrypted.

2. Export workflows from the old instance.

   - You can export from the n8n UI as JSON, or use the n8n CLI on the old instance.
   - If you only care about flows, exporting workflow JSON is enough.

3. Import workflows into the new stack.

   - Open the new n8n UI and import the workflow JSON files.
   - Recreate credentials manually, or migrate them only after you have confirmed the encryption key matches.

4. Move credentials carefully.

   - Credentials are encrypted.
   - If the old and new instances use the same `N8N_ENCRYPTION_KEY`, you can migrate credentials.
   - If the keys differ, plan to recreate credentials manually in the new instance.

## Full migration option

If you want a near-complete move instead of importing JSON one workflow at a time:

1. Stop your old localhost n8n instance.
2. Keep the same `N8N_ENCRYPTION_KEY`.
3. Export workflows and credentials from the old instance.
4. Start this PostgreSQL-backed stack.
5. Import workflows first, then credentials.
6. Re-test webhook URLs because they usually change when moving away from localhost.

## Notes

- `WEBHOOK_URL` should be your public base URL if external systems call your flows.
- `N8N_EDITOR_BASE_URL` should match the URL you use in the browser.
- For production, put n8n behind HTTPS and do not leave the default example secrets in place.
