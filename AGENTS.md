# Repository Guidelines

## Project Overview

`pacto-dev-env` is the local development-environment repository for the Pacto / Covenant Gov ecosystem. It provides containerized backing services (Nostr relay, Anvil EVM testnet, optional Aztec sandbox, optional NIP-46 bunker) and OS-specific one-shot host setup scripts so contributors can build and test the sibling application repositories.

## Architecture & Data Flow

This repository is a **service orchestration layer**, not an application.

- **Default stack** starts two services:
  - `nostr-relay` on `ws://localhost:7000`
  - `anvil` EVM testnet on `http://localhost:8545` (chain 31337)
- **Optional Compose profiles** extend the stack:
  - `--profile aztec` adds `aztec-sandbox` (`http://localhost:8080`, admin `http://localhost:8880`); it waits for Anvil to be healthy and deploys rollup contracts to it.
  - `--profile bunker` adds `nip46-bunker` (`http://127.0.0.1:3001`) backed by Postgres and Redis.
- **Host setup scripts** install Docker, Rust, Node/pnpm, Foundry, Aztec CLI, and clone the ecosystem repos into `~/src/covenant-gov/`.
- Sibling application repos (e.g., `pacto-app`, `pacto-gov`) connect to these localhost endpoints during local development.

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `docker/` | Local Dockerfiles for `nostr-relay`, `anvil`, `aztec-sandbox`, and `nip46-bunker`. |
| `data/` | Runtime data volumes mounted into containers (`data/relay`, `data/aztec`, `data/nip46-bunker-db`). |

## Development Commands

### Host setup

Apple Silicon:

```bash
./setup-macos-arm64.sh [base-dir]
```

Ubuntu 24.04/24.10/26.04 LTS:

```bash
sudo ./setup-ubuntu-lts.sh [base-dir]
```

Both default to cloning repos into `~/src/covenant-gov/`. After running, open a new shell so PATH changes take effect.

### Start local services

```bash
mkdir -p data/relay
docker compose up -d --build
```

### Optional profiles

Aztec sandbox:

```bash
docker compose --profile aztec up -d --build
```

NIP-46 bunker (generate real secrets first):

```bash
cat > .env <<EOF
JWT_SECRET=$(openssl rand -base64 48)
JWT_REFRESH_SECRET=$(openssl rand -base64 48)
ENCRYPTION_KEY=$(openssl rand -base64 48)
EOF
docker compose --profile bunker up -d --build
```

## Code Conventions & Common Patterns

- **Bash setup scripts**
  - `setup-ubuntu-lts.sh` is idempotent: checks `dpkg` status, tests `command -v`, and uses `append_if_missing` for shell rc edits.
  - `setup-macos-arm64.sh` checks command existence before installing but re-appends the environment block to the shell rc on every run.
  - Both append `~/.cargo/bin`, `~/.foundry/bin`, and `~/.aztec/bin` to PATH.
- **Docker builds**
  - Prefer source builds for native architecture (arm64 on Apple Silicon, x86_64 on Linux) instead of `platform:` pinning or Rosetta emulation.
  - Multi-stage Dockerfiles with dedicated runtime images (`debian:bookworm-slim` or `node:24-slim`).
  - Services run as non-root users where applicable (`relay` uid 1000, `bunker` uid 1001).
- **Compose patterns**
  - Use profiles (`aztec`, `bunker`) to keep heavy services opt-in.
  - Healthchecks gate service dependencies (e.g., Aztec waits for Anvil; bunker waits for Postgres and Redis).
- **Configuration**
  - `relay-config.toml` is mounted read-only into the relay container.
  - Bunker secrets are injected via `.env`; default placeholders are insecure and must be overridden.

## Important Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service definitions, profiles, ports, volumes, and healthchecks. |
| `relay-config.toml` | Nostr relay runtime config (SQLite, allow-listed event kinds). |
| `setup-macos-arm64.sh` | Host setup for Apple Silicon. |
| `setup-ubuntu-lts.sh` | Host setup for Ubuntu LTS (run with `sudo`). |
| `docker/nostr-relay.Dockerfile` | Builds `nostr-rs-relay` v0.9.0 from source. |
| `docker/anvil.Dockerfile` | Builds Foundry v1.7.1 (`anvil`, `cast`, `forge`, `chisel`) from source. |
| `docker/aztec-sandbox.Dockerfile` | Wraps the upstream Aztec arm64 image, adds `curl` for healthchecks. |
| `docker/nip46-bunker.Dockerfile` | Builds Bunker46 server (no UI) from source with Node 24/pnpm. |
| `README.md` | Quick-start and port reference. |
| `GETTING_STARTED.md` | Full developer guide with per-project workflows. |

## Runtime/Tooling Preferences

- **Container runtime**: Docker Engine + Docker Compose plugin.
- **Shell**: Bash; setup scripts target `zsh`/`bash` rc files.
- **Host toolchains installed by setup scripts**:
  - Rust (stable) with `rustfmt` and `clippy`
  - Node 20 / pnpm
  - Foundry (`anvil`, `cast`, `forge`)
  - Aztec sandbox version manager
- **Architecture**: Native arm64/amd64 builds; avoid `platform: linux/amd64` pinning.

## Testing & QA

- There is no automated test suite in this repository.
- Setup script health is checked by `verify_install()` at the end of each script, which prints versions of Docker, Docker Compose, Rust, Node, pnpm, Foundry, and Aztec.
- Service health is verified through Docker Compose healthchecks and the port reference in `README.md`.
- When modifying a Dockerfile or setup script, test the affected path end-to-end on the target platform before considering it done.
