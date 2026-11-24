# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# Content recipe for the tools mixin (descriptor: tools.yaml). Upstream
# release binaries pinned by version + SHA256 (scripts/update-checksums.sh
# refreshes the hashes), staged in throwaway stages and copied onto scratch.

# --- release binaries --------------------------------------------------------
FROM docker.io/library/debian:trixie-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
# renovate: datasource=github-releases depName=BurntSushi/ripgrep
ARG RG_VERSION=15.2.0
ARG RG_SHA256_AMD64=33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c
ARG RG_SHA256_ARM64=800b1e7206afe799dfb5a6901f23147cfaabe0e52210538100f61e86e1740915
# renovate: datasource=github-releases depName=sharkdp/fd
ARG FD_VERSION=10.5.2
ARG FD_SHA256_AMD64=7e2d07fa2b8807642aaec67b7e2972a9fbe4db26fcb340a7372392db42b26694
ARG FD_SHA256_ARM64=63ea52cb31586e6d98efa2f06d73d542f16c7d0c4af0f07b579aaf9714cf907a
# renovate: datasource=github-releases depName=sharkdp/bat
ARG BAT_VERSION=0.26.1
ARG BAT_SHA256_AMD64=0dcd8ac79732c0d5b136f11f4ee00e581440e16a44eab5b3105b611bbf2cf191
ARG BAT_SHA256_ARM64=6369242c584065f195fb20cb36fbd7cb63ae690605bbe89868a7596b596c2c23
# renovate: datasource=github-releases depName=eza-community/eza
ARG EZA_VERSION=0.23.5
ARG EZA_SHA256_AMD64=35c70c5c43c29108075e58b893234c67ef585f0b53a7eaf8e9e7d4eec9f339b4
ARG EZA_SHA256_ARM64=40b87ae8628aa2ff0f0d2dc24ab52f689631366385c3da630bae745671fd71ec
# renovate: datasource=github-releases depName=junegunn/fzf
ARG FZF_VERSION=0.75.0
ARG FZF_SHA256_AMD64=0d6640f83582d991cf429754baad64b07e3a4e439a6019670f4b91da1314141c
ARG FZF_SHA256_ARM64=bd0717badb6a5620387e014bb94209aac4d9eab6ab77b5348eabb0833aeb4d59
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.105.0
ARG GH_SHA256_AMD64=79e7ab5db738c48777b696e374f8b428f0647debfb424f44d2f426370407fe2f
ARG GH_SHA256_ARM64=b1278c75107423d818f1937fd92cafc9e5e9b606631568f68d7fb816f5885a02
# renovate: datasource=github-releases depName=git-lfs/git-lfs
ARG GITLFS_VERSION=3.8.1
ARG GITLFS_SHA256_AMD64=e72cf723a4a660438862282e8aecf3885fc8123e88bfcad534cf6b941a354b75
ARG GITLFS_SHA256_ARM64=67895dd77b63329796bc5efdd47b57f218e1f7b98717ebaf936a8238dbcaec0f
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=4.54.3
ARG YQ_SHA256_AMD64=129534601871538efe0ba4c5e62a34fb1d5f469bcb975c4fddeb467d82974973
ARG YQ_SHA256_ARM64=89f69310b61b68d1245065a1241d1fc843f7a36cd6103ffd77ad987613bd1b67
# renovate: datasource=github-releases depName=dandavison/delta
ARG DELTA_VERSION=0.20.1
ARG DELTA_SHA256_AMD64=50f08c879f84c81ceb220e476491a7f492d2c9c671e79918cc44badf961a6240
ARG DELTA_SHA256_ARM64=da7f4338f593572ff426ae153e0870e2fdc72729416eff551b40cdeb67940db8
# renovate: datasource=github-releases depName=rui314/mold
ARG MOLD_VERSION=3.0.0
ARG MOLD_SHA256_AMD64=6c90d4a474c7c0409dfb575be03a5345878ac14fdba18de8b40fa58c60121189
ARG MOLD_SHA256_ARM64=52c759d3689babaea4c42af2f31062a74ab83e17ffb5a8090232534c67b70577
# renovate: datasource=github-releases depName=gastownhall/beads
ARG BEADS_VERSION=1.3.4
ARG BEADS_SHA256_AMD64=175c26904bde3ff9168d2282ff6b56f17b17f60c22fa5acb3dacc9fb3465303a
ARG BEADS_SHA256_ARM64=f4ee6eb3ec79bb2d7eb9d717c73efbcb6fa763cc70f726b4d055b72afdd68ad5
# renovate: datasource=github-releases depName=j178/prek
ARG PREK_VERSION=0.5.11
ARG PREK_SHA256_AMD64=e9e283683dae28716652a4c172bc4fb053eecd28b8938132d576af266f8dfecb
ARG PREK_SHA256_ARM64=bb8aa2339f983f7aba8d2d298ce8ef53719388dc58f7868f4c755b9f48abb319

RUN <<EOF
#!/usr/bin/env bash
set -euo pipefail

case "$TARGETARCH" in
  amd64) A=x86_64 ;;
  arm64) A=aarch64 ;;
  *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;;
esac

# fetch NAME URL: download to /tmp/NAME, check against ${NAME}_SHA256_<ARCH>.
fetch() {
  local sha_var="${1}_SHA256_${TARGETARCH^^}"
  curl -fsSL "$2" -o "/tmp/$1"
  echo "${!sha_var}  /tmp/$1" | sha256sum -c -
}

BIN=/out/usr/local/bin
mkdir -p "$BIN" /out/opt

fetch RG "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${A}-unknown-linux-musl.tar.gz"
tar -xzf /tmp/RG -C "$BIN" --strip-components=1 "ripgrep-${RG_VERSION}-${A}-unknown-linux-musl/rg"

fetch FD "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${A}-unknown-linux-musl.tar.gz"
tar -xzf /tmp/FD -C "$BIN" --strip-components=1 "fd-v${FD_VERSION}-${A}-unknown-linux-musl/fd"

fetch BAT "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-${A}-unknown-linux-musl.tar.gz"
tar -xzf /tmp/BAT -C "$BIN" --strip-components=1 "bat-v${BAT_VERSION}-${A}-unknown-linux-musl/bat"

# eza has no aarch64 musl build; gnu matches DHI's glibc on both arches.
fetch EZA "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${A}-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/EZA -C "$BIN" ./eza

fetch FZF "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${TARGETARCH}.tar.gz"
tar -xzf /tmp/FZF -C "$BIN" fzf

fetch GH "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz"
tar -xzf /tmp/GH -C "$BIN" --strip-components=2 "gh_${GH_VERSION}_linux_${TARGETARCH}/bin/gh"

fetch GITLFS "https://github.com/git-lfs/git-lfs/releases/download/v${GITLFS_VERSION}/git-lfs-linux-${TARGETARCH}-v${GITLFS_VERSION}.tar.gz"
tar -xzf /tmp/GITLFS -C "$BIN" --strip-components=1 "git-lfs-${GITLFS_VERSION}/git-lfs"

fetch YQ "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}"
install -m 0755 /tmp/YQ "$BIN/yq"

# delta has no aarch64 musl build; gnu on both arches.
fetch DELTA "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-${A}-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/DELTA -C "$BIN" --strip-components=1 "delta-${DELTA_VERSION}-${A}-unknown-linux-gnu/delta"

# mold finds its wrapper/driver files relative to itself, so keep the
# tarball layout under /opt/mold and symlink the entry points.
fetch MOLD "https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-${A}-linux.tar.gz"
tar -xzf /tmp/MOLD -C /out/opt
mv "/out/opt/mold-${MOLD_VERSION}-${A}-linux" /out/opt/mold
ln -s /opt/mold/bin/mold "$BIN/mold"
ln -s /opt/mold/bin/ld.mold "$BIN/ld.mold"

fetch BEADS "https://github.com/gastownhall/beads/releases/download/v${BEADS_VERSION}/beads_${BEADS_VERSION}_linux_${TARGETARCH}.tar.gz"
tar -xzf /tmp/BEADS -C "$BIN" bd

fetch PREK "https://github.com/j178/prek/releases/download/v${PREK_VERSION}/prek-${A}-unknown-linux-musl.tar.gz"
tar -xzf /tmp/PREK -C "$BIN" --strip-components=1 "prek-${A}-unknown-linux-musl/prek"

EOF

# --- node and language servers -----------------------------------------------
# The workload has no node. Exact language server versions are in package.json,
# integrity hashes in package-lock.json. The .bin links are relative and resolve
# inside /opt/lsp.
FROM docker.io/library/node:26-trixie-slim@sha256:e6bedef217677b276c591795e169840edd9096dbf13f29df8ef8d1856b8820bc AS node
COPY package.json package-lock.json /out/opt/lsp/
RUN cd /out/opt/lsp \
 && npm ci --omit=dev --no-audit --no-fund \
 && mkdir -p /out/usr/local/bin /out/opt/node/bin /out/opt/node/lib \
 && cp -a /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /out/opt/node/bin/ \
 && cp -a /usr/local/lib/node_modules /out/opt/node/lib/ \
 && ln -s /opt/node/bin/node /out/usr/local/bin/ \
 && for b in typescript-language-server tsc tsserver; do \
      ln -s "/opt/lsp/node_modules/.bin/$b" "/out/usr/local/bin/$b"; \
    done

# --- the overlay -------------------------------------------------------------
# Tarballs carry the packer's uid, so ownership is reset on copy.
FROM scratch
COPY --from=node  --chown=0:0 /out /
COPY --from=build --chown=0:0 /out /
# files/ mirrors the root filesystem. Plain COPY keeps the tree's modes;
# --chmod would also stamp its mode on the parent dirs it creates (/etc),
# and the overlay would replace the workload's /etc entry with it.
COPY files/ /

# Entry points: through Socket Firewall when the sfw mixin is present.
COPY --chmod=0755 <<'EOF' /usr/local/bin/npm
#!/bin/sh
[ -x /opt/socket/bin/sfw ] && exec /opt/socket/bin/sfw /opt/node/bin/npm "$@"
exec /opt/node/bin/npm "$@"
EOF
COPY --chmod=0755 <<'EOF' /usr/local/bin/npx
#!/bin/sh
[ -x /opt/socket/bin/sfw ] && exec /opt/socket/bin/sfw /opt/node/bin/npx "$@"
exec /opt/node/bin/npx "$@"
EOF

# Additive at assembly.
ENV SHELL=/bin/bash \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    COLORTERM=truecolor
