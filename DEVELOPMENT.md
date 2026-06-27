# Development Guide

This document covers the developer workflow for the `pacto-dev-env` repository, including the agent skills, tools, and harness setup used day-to-day.

## Agent skills (no setup required)

This repository ships agent skills from [skills.sh](https://skills.sh/) under version control so every contributor gets the same guidance automatically.

- `.claude/skills/` — discovered by **Claude Code**
- `.agents/skills/` — discovered by **Cursor** and by Oh My Pi's `agents` provider
- `.omp/skills/` — discovered natively by **Oh My Pi (omp)**
- `skills-lock.json` — reproducible manifest of installed skills

The skills are **vendored** (installed with `npx skills add ... --copy`). You do **not** need to run `npx skills`, `npm install`, or any other package manager to use them. Just check out the branch and open the repository in Claude Code, Cursor, or `omp`.

### Installed skills

| Skill | Source | When it helps |
|---|---|---|
| `rust-best-practices` | `apollographql/skills` | Writing or reviewing idiomatic Rust |
| `rust-async-patterns` | `wshobson/agents` | Tokio, async traits, concurrency |
| `rust-testing` | `affaan-m/everything-claude-code` | Unit, integration, async, property-based, and snapshot testing |
| `rust-patterns` | `affaan-m/everything-claude-code` | Common Rust design patterns |
| `m15-anti-pattern` | `zhanghandong/rust-skills` | Anti-patterns and code-smell detection |
| `cargo-fuzz` | `trailofbits/skills` | Fuzzing with `cargo-fuzz` |
| `cargo-nextest` | `laurigates/claude-plugins` | Fast, structured test runs |
| `ce-compound` | `everyinc/compound-engineering-plugin` | Documenting solved problems and project vocabulary in `docs/solutions/` |
| `ce-compound-refresh` | `everyinc/compound-engineering-plugin` | Auditing and refreshing stale learnings |

### If a harness does not pick up skills

1. Confirm you are on the correct branch (the skills live on the feature branch until the PR is merged).
2. Restart the agent / reload the window:
   - Claude Code: restart the session
   - Cursor: reload the window (`Developer: Reload Window`)
   - OMP: run `/reload-plugins` or restart `omp`
3. Check that the skill directory for your harness exists:
   ```bash
   ls .claude/skills .agents/skills .omp/skills
   ```

### Adding or updating skills

Only needed when you want to change the skill set:

```bash
# Install a new skill for all three harnesses
npx skills add <owner/repo@skill> -a claude-code -a cursor -a pi -y --copy

# Copy it into the OMP-native directory
rsync -a .agents/skills/<skill-name>/ .omp/skills/<skill-name>/

# Update all installed skills
npx skills update -y
```

Then commit the changed skill directories and `skills-lock.json`.

## Rust toolchain and feedback-loop tools

The host setup scripts install Rust with `rustfmt` and `clippy`. For the fastest feedback loop on Rust code in this repo (especially `docker/nostr-relay.Dockerfile` and any sibling Rust projects), install these optional tools locally:

```bash
# Faster, structured test runner (used by the cargo-nextest skill)
cargo install cargo-nextest

# Auto-run tests/checks on file changes
cargo install cargo-watch   # or cargo install bacon

# Snapshot testing
cargo install cargo-insta

# Fuzzing (only if you are writing fuzz targets)
cargo install cargo-fuzz
```

Recommended per-project settings for any Rust crate in the ecosystem:

- `Cargo.toml` workspace lint config:
  ```toml
  [workspace.lints.clippy]
  all = "warn"
  pedantic = "warn"
  perf = "warn"
  ```
- Run checks before committing:
  ```bash
  cargo fmt --check
  cargo clippy --all-targets --all-features --locked -- -D warnings
  cargo nextest run
  ```

## MCP servers and agents

This repository does not require any additional MCP servers or custom agents beyond what the harness already provides:

- **LSP / rust-analyzer** is available through the harness's LSP tool for code intelligence, hover, references, and refactors.
- **Docker Compose** provides the backing services (`nostr-relay`, `anvil`, optional `aztec-sandbox`, optional `nip46-bunker`).

If you add an MCP server for a specific workflow, document it in this section and commit the configuration (e.g., `.cursor/mcp.json`, `.claude/CLAUDE.md`, or OMP's equivalent) so the rest of the team gets it automatically.

## Local service stack

See `README.md` for the full quick-start. The typical loop is:

```bash
mkdir -p data/relay
docker compose up -d --build
```

Use optional profiles as needed:

```bash
docker compose --profile aztec up -d --build
docker compose --profile bunker up -d --build
```

## Testing & QA

There is no automated test suite in this repository. Validate changes by:

1. Running the host setup script on a clean machine or in the provided test Dockerfiles (`test/ubuntu-24.04.Dockerfile`, `test/ubuntu-26.04.Dockerfile`).
2. Building and starting the Docker Compose stack.
3. Following the debugging playbook in `AGENTS.md` to verify service health.

When modifying a Dockerfile or setup script, test the affected path end-to-end on the target platform before considering it done.
