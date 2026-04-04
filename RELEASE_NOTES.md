# Release Notes

## v1.2.0 — Skill Dependency Management (2026-04-04)

### New features

- **`task dep:add -- <clawhub-url>`** — Add a ClaWHub skill to your local dependency manifest with one command. Installs the skill in a throwaway container, parses its `SKILL.md` for required npm packages, resolves latest versions, and updates `db/deps.json` automatically.
- **`deps.default.json`** — Empty skill manifest template shipped in the repo. Seeded into `db/deps.json` automatically on first `task build:runtime`.
- **`db/deps.json`** — Personal skill manifest (gitignored). Tracks ClaWHub skills and their npm dependencies. Edit manually or via `task dep:add`.
- **Two-pass `build-runtime`** — After interactive onboarding (`podman commit` pass 1), a second non-interactive pass runs `install-deps` and commits again. Skills and their binaries are baked into the image.
- **`scripts/install-deps.sh`** — Runs inside the container during build. Installs `core.npm` packages, then ClaWHub skills, then each skill's npm dependencies.
- **`scripts/entrypoint.sh`** — Runs inside the container on every `task run`. Calls `clawhub update` per skill before handing off to `openclaw gateway`. No-op for other commands (onboard, install-deps, shell).
- **ClaWHub in base image** — `clawhub@latest` is now installed in `Dockerfile.base` via npm, guaranteeing it is present regardless of onboarding choices.
- **Weekly CI builds** — GitHub Actions now rebuilds `megaclaw-base` on a Monday 03:00 UTC schedule, ensuring OpenClaw and ClaWHub are always on their latest versions.
- **Versioned image tags** — Published images are tagged `latest`, `1.0.YYYYMMDD`, and `sha-<commit>`. The date tag lets you pin to a specific weekly build.

---

## v1.1.0 — CI, GHCR, Multi-platform, Polish (2026-03-29 – 2026-04-01)

### New features

- **GitHub Actions CI** — `Dockerfile.base` is built and pushed to GHCR on every relevant push to `main` and on `workflow_dispatch`.
- **GHCR publishing** — `megaclaw-base` is published to `ghcr.io/lovato/megaclaw-base`. Pull with `task pull:base`.
- **Multi-platform images** — CI builds for `linux/amd64` and `linux/arm64` in a single manifest. `podman pull` automatically selects the correct variant (Raspberry Pi 5 gets arm64).
- **Multi-stage Homebrew** — `Dockerfile.base` copies `/home/linuxbrew` from the official `homebrew/brew:latest` image instead of running install scripts. Reliable in CI and compatible with the Playwright base.
- **`task pull:base`** — Pulls the pre-built base image from GHCR and tags it locally. Use this on a Pi instead of building locally.
- **`task db:wipe` / `task db:backup` / `task db:restore`** — Database tasks renamed to a consistent `db:` namespace.
- **`task db:backup` / `task db:restore`** — Zip-based backup/restore for `db/` (your OpenClaw config and tokens). Optional password support.
- **`task purge`** — Force-remove a stuck container without restarting.
- **`task stop`** — Now also removes the container after stopping (not just stops it).
- **Stale container fix** — `scripts/run.sh` removes any leftover `megaclaw` container before starting. `task run` always works after a ctrl-c.
- **Control UI access docs** — README documents both the simple localhost path and all four steps required for remote/LAN access.
- **`task ssh:runtime`** — Open a shell in the running container. Useful for `openclaw dashboard` to find the Control UI URL.
- **Vim** — Added to `megaclaw-base` for in-container editing.

### Breaking changes

- Task names `wipe`, `backup:create`, `backup:restore` renamed to `db:wipe`, `db:backup`, `db:restore`.
- Image names `openclaw-base` / `openclaw-runtime` renamed to `megaclaw-base` / `megaclaw-runtime`.

---

## v1.0.0 — Initial Release (2026-02-24)

### Features

- **Two-layer container setup** — `megaclaw-base` (Homebrew + Playwright + OpenClaw) and `megaclaw-runtime` (base + interactive onboarding baked in via `podman commit`).
- **Rootless Podman** — Runs entirely without root. UID is preserved from the host, avoiding the permission errors common with the official OpenClaw Podman setup.
- **Bundled browser** — Playwright base image ships Chromium. No separate browser install required.
- **Onboarding bypass** — `build-runtime.sh` runs `openclaw onboard` once and commits the result. Subsequent `task run` invocations start the gateway directly.
- **`task build:base`** — Build the base image locally.
- **`task build:runtime`** — Run interactive onboarding and bake config into the runtime image.
- **`task run`** — Start the OpenClaw gateway container.
- **`task stop`** — Stop the running container.
- **`task ssh:base` / `task ssh:runtime`** — Shell into either image for debugging.
- **`task test`** — Smoke test suite: bash syntax check on all scripts, YAML lint on the taskfile, Dockerfile non-empty check.
- **AGENTS.md** — Project documentation and AI agent guidelines.
