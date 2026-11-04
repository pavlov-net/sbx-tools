# Before first release

All local until "Publishing". From a scratch directory, with `K=~/Builds/sbx-tools/mixins`.

## Compose and launch

- [ ] `sbx create --name sbxt claude . --kit $K/sfw --kit $K/tools --kit $K/rust --kit $K/python`
  - [x] create succeeds, and gcc installs (note how long create takes)
  - [ ] the sandbox shows as agent `claude`
  - [ ] `sbx run --name sbxt` comes up logged in with your subscription, without `/login` (failed on 10/22)
  - [x] `sbx exec sbxt bash -lc 'command -v npm pip uv cargo node pyright'`: all in `/usr/local/bin`
  - [x] `sbx exec sbxt bash -lc 'cd /tmp && cargo new t && cd t && cargo add itoa && cargo build && cargo clippy'`
  - [x] `sbx exec sbxt bash -lc 'mkdir -p /tmp/p && cd /tmp/p && npm init -y >/dev/null && npm install left-pad'`
  - [x] `sbx exec sbxt bash -lc 'cd /tmp && uv venv v && . v/bin/activate && uv pip install idna && pip --version && pyright --version'`
  - [ ] plain `pip install idna` in a venv works under sfw (only `uv pip` has been tried, and pip uses its own CA settings)
  - [x] sfw is really in the path: `sbx exec sbxt bash -lc 'echo plain; env | grep -i -E "proxy|_ca"; echo sfw; /opt/socket/bin/sfw /usr/bin/env | grep -i -E "proxy|_ca"'` shows different values
  - [ ] `/etc/sandbox-persistent.sh` has the `# sfw: shims first` PATH line
  - [x] Claude sees the sbx-tools, Socket Firewall, Rust and Python notes
  - [ ] pasting an image works (`sbx settings set clipboard.imagePaste true` first)
- [ ] Recreate on Node 26 (the checks above ran on 24): `node --version`, then rerun the npm and pyright checks, plus `typescript-language-server --version`
- [ ] Same with `codex`
- [ ] `sbx kit add` on a running sandbox: start without `rust`, add it, confirm `cargo build` works

## Docker's base

- [ ] `docker run --rm hello-world` inside: does the engine run, and is it worth noting in the README?
- [ ] Session history: `sbx rm` loses it. Decide whether to add Docker's `claude-sessions` as an opt-in flag.

## C/C++ toolchain

- [ ] Add `--kit $K/cxx`: create installs g++, clang and cmake
- [ ] A crate using `cc` for C++, or bindgen, builds
- [ ] `--kit-arg extraPackages="libsqlite3-dev"` installs the extra package

## ssh-agent-proxy

- [ ] Add `--kit $K/ssh-agent-proxy --kit-arg host=<tailscale host> --kit-arg port=7221`
  - [ ] create asks to approve `<host>:7221`
  - [ ] other kits accept the shared `--kit-arg` values
  - [ ] after boot, `git config --global commit.gpgsign` is `true` and a commit is signed
- [ ] Try Docker's `docker.io/sbx/git-ssh-sign` against the Windows 1Password agent from WSL (`ssh.agentSocketPath` may be involved). If it works, it can replace this kit.

## Publishing

- [ ] Push to GitHub and let CI publish to ghcr.io
- [ ] `scripts/sbx-up setup`, then `scripts/sbx-up create .` from the published kits
- [ ] `scripts/sbx-up create -a codex --no-rust --no-python --no-cxx --bun .`
- [ ] `--pull always` refreshes both Docker's kit and ours

## Cleanup

- [ ] `sbx settings unset platform.images.useDHI` (left over from 10/22)
