#!/usr/bin/env bash
#
# Refresh the <TOOL>_SHA256_{AMD64,ARM64} ARGs in the mixin Dockerfiles from
# the versions currently pinned there. Hosted Renovate can't run this
# (postUpgradeTasks needs self-hosted), so run it on Renovate PR branches.
#
# GitHub release assets are hashed by the release API's `digest` field (via
# gh); anything else, or an asset without one, is downloaded and hashed.
#
# Usage: scripts/update-checksums.sh [TOOL...]   (default: every tool below)
set -euo pipefail
cd "$(dirname "$0")/.."

# TOOL | URL template | amd64 token | arm64 token
# {v} is the pinned version; {a} is the per-arch token.
TABLE=$(cat <<'EOF'
SFW|https://github.com/SocketDev/sfw-free/releases/download/v{v}/sfw-free-linux-{a}|x86_64|arm64
BUN|https://github.com/oven-sh/bun/releases/download/bun-v{v}/bun-linux-{a}.zip|x64|aarch64
RG|https://github.com/BurntSushi/ripgrep/releases/download/{v}/ripgrep-{v}-{a}-unknown-linux-musl.tar.gz|x86_64|aarch64
FD|https://github.com/sharkdp/fd/releases/download/v{v}/fd-v{v}-{a}-unknown-linux-musl.tar.gz|x86_64|aarch64
BAT|https://github.com/sharkdp/bat/releases/download/v{v}/bat-v{v}-{a}-unknown-linux-musl.tar.gz|x86_64|aarch64
EZA|https://github.com/eza-community/eza/releases/download/v{v}/eza_{a}-unknown-linux-gnu.tar.gz|x86_64|aarch64
FZF|https://github.com/junegunn/fzf/releases/download/v{v}/fzf-{v}-linux_{a}.tar.gz|amd64|arm64
GH|https://github.com/cli/cli/releases/download/v{v}/gh_{v}_linux_{a}.tar.gz|amd64|arm64
GITLFS|https://github.com/git-lfs/git-lfs/releases/download/v{v}/git-lfs-linux-{a}-v{v}.tar.gz|amd64|arm64
YQ|https://github.com/mikefarah/yq/releases/download/v{v}/yq_linux_{a}|amd64|arm64
DELTA|https://github.com/dandavison/delta/releases/download/{v}/delta-{v}-{a}-unknown-linux-gnu.tar.gz|x86_64|aarch64
MOLD|https://github.com/rui314/mold/releases/download/v{v}/mold-{v}-{a}-linux.tar.gz|x86_64|aarch64
BEADS|https://github.com/gastownhall/beads/releases/download/v{v}/beads_{v}_linux_{a}.tar.gz|amd64|arm64
PREK|https://github.com/j178/prek/releases/download/v{v}/prek-{a}-unknown-linux-musl.tar.gz|x86_64|aarch64
CARGO_BINSTALL|https://github.com/cargo-bins/cargo-binstall/releases/download/v{v}/cargo-binstall-{a}-unknown-linux-musl.tgz|x86_64|aarch64
CARGO_CACHE|https://github.com/cargo-bins/cargo-quickinstall/releases/download/cargo-cache-{v}/cargo-cache-{v}-{a}-unknown-linux-gnu.tar.gz|x86_64|aarch64
EOF
)

# sha256_of URL: the asset's GitHub-published digest, else download and hash.
sha256_of() {
  local url="$1" sha=""
  if [[ "$url" =~ ^https://github.com/([^/]+/[^/]+)/releases/download/([^/]+)/([^/]+)$ ]] && command -v gh >/dev/null; then
    sha=$(gh api "repos/${BASH_REMATCH[1]}/releases/tags/${BASH_REMATCH[2]}" \
      --jq ".assets[] | select(.name == \"${BASH_REMATCH[3]}\") | .digest // empty" 2>/dev/null || true)
    sha=${sha#sha256:}
  fi
  [ -n "$sha" ] || sha=$(curl -fsSL "$url" | sha256sum | awk '{print $1}')
  echo "$sha"
}

only=" $* "
while IFS='|' read -r tool tmpl amd64 arm64; do
  [ $# -eq 0 ] || [[ "$only" == *" $tool "* ]] || continue
  dockerfile=$(grep -l "^ARG ${tool}_VERSION=" mixins/*/*.dockerfile)
  version=$(grep -oP "^ARG ${tool}_VERSION=\K.*" "$dockerfile")
  for arch in AMD64 ARM64; do
    token=$([ "$arch" = AMD64 ] && echo "$amd64" || echo "$arm64")
    url=${tmpl//\{v\}/$version}
    sha=$(sha256_of "${url//\{a\}/$token}")
    sed -i "s/^ARG ${tool}_SHA256_${arch}=.*/ARG ${tool}_SHA256_${arch}=${sha}/" "$dockerfile"
  done
  echo "${tool} ${version}: updated (${dockerfile})"
done <<< "$TABLE"
