# NanoClaw → Hermes switch (runbook)

This folder is a **safe, reversible runbook** for deactivating NanoClaw and
bringing up the Hermes agent on your **Mac mini**.

## Important: where this has to run

The Claude Code web/cloud session that generated this runs in an ephemeral
**Linux** container that **cannot see your Mac mini's Docker daemon** (verified:
no `/var/run/docker.sock`, host is `Linux vm`, not macOS). So the *switch itself*
must run **on the Mac mini** — either:

- in **Terminal** on the Mac mini, or
- in a **Claude Code / Claude desktop session running locally on the Mac mini**
  (that one can actually reach Docker and your Obsidian vault).

## Files

| File | What it does |
|---|---|
| `switch-to-hermes.sh` | Stops + disables NanoClaw (keeps it for rollback), starts Hermes, verifies. Idempotent. |
| `rollback-to-nanoclaw.sh` | Undoes the switch: stops Hermes, restarts NanoClaw. |
| `docker-compose.hermes.yml` | **Template** for the Hermes container — fill in the `TODO_` markers. |

## Steps

1. Copy this `hermes-setup/` folder onto the Mac mini.
2. Find your real container/image names first:
   ```sh
   docker ps -a
   ```
3. Edit `docker-compose.hermes.yml` — replace every `TODO_...` with real values
   (Hermes image, ports matching NanoClaw, env, volumes). Create a `.env` for secrets.
4. If NanoClaw's container isn't literally named `nanoclaw`, pass the real name:
   ```sh
   chmod +x switch-to-hermes.sh rollback-to-nanoclaw.sh
   NANOCLAW_NAME=your-nanoclaw-name ./switch-to-hermes.sh
   ```
5. Verify: the script prints `docker ps` and how to tail Hermes logs.
6. If anything looks wrong:
   ```sh
   NANOCLAW_NAME=your-nanoclaw-name ./rollback-to-nanoclaw.sh
   ```

## What "safe + reversible" means here

- NanoClaw is **stopped and its auto-restart removed**, never `docker rm`'d.
  Your data/volumes are untouched. Rollback brings it straight back.
- Nothing here deletes images or volumes.

## To make me do this *for* you next time

This session couldn't touch the Mac mini. For a future session to actually run
the switch and read your Obsidian vault, one of these needs to be true:

- Run Claude Code **on the Mac mini** (local Docker + filesystem access), or
- Attach the **Obsidian MCP connector** and **SSH access** to the cloud
  environment (it currently has Figma/Canva/Vercel/Supabase/Google Drive/
  Gmail/Exa/Context7/GitHub — but **no Obsidian connector and no SSH host**).

Paste me your real NanoClaw run command + Hermes image details and I'll
replace every `TODO_` with precise values.
