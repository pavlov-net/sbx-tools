# sbx-tools

Kits for [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) (`sbx`) that add current CLI tools, Rust, Python tooling, a C/C++ toolchain and [Socket Firewall](https://github.com/SocketDev/sfw-free) to Docker's Claude Code and Codex kits.

## Quick start

Requires `sbx` 0.51 or newer.

```bash
scripts/sbx-up setup          # once: allow kits from ghcr.io
scripts/sbx-up create .       # Claude Code sandbox for the current directory
```

`sbx-up create` prints the sandbox name; attach with `sbx run --name <name>`.

## Options

```bash
scripts/sbx-up create -a codex .                       # Codex instead of Claude Code
scripts/sbx-up create --no-python --no-cxx .           # skip kits you don't need
scripts/sbx-up create --bun .                          # add bun
scripts/sbx-up create --ssh-agent-proxy HOST[:PORT] .  # sign commits via ssh-agent-proxy
scripts/sbx-up create --kit docker.io/sbx/playwright .  # any other mixin
scripts/sbx-up create --name NAME .                    # choose the sandbox name
```

Run `scripts/sbx-up create --help` for the full list.

## What's included

Every sandbox starts from Docker's `sbx/claude` or `sbx/codex` kit, which already has the agent, git, gh, make, Python with pip and uv, jq, tmux and a Docker engine. On top of that:

| Kit | Adds | Default |
|---|---|---|
| `tools` | rg, fd, bat, eza, fzf, a current gh, git-lfs, yq, delta, mold, bd, prek; Node 26 with npm; typescript-language-server; git/tmux config | always |
| `sfw` | Socket Firewall in front of uv and uvx, and npm, npx, bun and cargo when present; pip and pip3 run `uv pip` | always |
| `rust` | stable Rust via rustup, rust-analyzer, clippy, rustfmt, cargo-binstall, cargo-cache; gcc (installed at create) | on |
| `python` | pyright; PyPI network access; notes steering the agent to uv | on |
| `cxx` | g++, clang/libclang, cmake, pkg-config, OpenSSL headers (installed at create) | on |
| `bun` | bun | off |
| `ssh-agent-proxy` | git commit signing through [ssh-agent-proxy](https://github.com/pavlov-net/ssh-agent-proxy) on the host | off |

The shell is bash. Package installs through the wrapped package managers are checked by Socket Firewall. The agent is told not to bypass it.

## Without sbx-up

The kits are ordinary `sbx` references:

```bash
R=ghcr.io/pavlov-net/sbx-tools
sbx create claude . --kit $R/sfw:latest --kit $R/tools:latest --kit $R/rust:latest
```

A local checkout works too: `--kit ./mixins/rust`. The `python` kit needs `tools`, which provides Node.

## Maintaining

- **Layout:** `mixins/<kit>/` holds each kit's descriptor (`<kit>.yaml`) and, for most kits, a build recipe (`<kit>.dockerfile`).
- **Tool updates:** Renovate opens PRs for version bumps. Those labelled `needs-checksums` need `scripts/update-checksums.sh` run on the branch.
- **Base kits:** `sbx` resolves `claude` and `codex` to Docker's `latest`, so they aren't pinned here. `sbx-up` passes `--pull always`.
- **Checking a kit locally:** `sbx kit validate ./mixins/<kit>` builds and validates it.
- **CI** builds every kit, and pushes and signs them on push to `main`.

[sbx-templates](https://github.com/pavlov-net/sbx-templates) is the older `--template`-based version of these images.
