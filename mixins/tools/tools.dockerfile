# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# Content recipe for the tools mixin (descriptor: tools.yaml). Upstream
# release binaries pinned by version + SHA256 (scripts/update-checksums.sh
# refreshes the hashes), staged in throwaway stages and copied onto scratch.

# --- release binaries --------------------------------------------------------
FROM docker.io/library/debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
# renovate: datasource=github-releases depName=BurntSushi/ripgrep
ARG RG_VERSION=15.2.0
ARG RG_SHA256_AMD64=33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c
ARG RG_SHA256_ARM64=800b1e7206afe799dfb5a6901f23147cfaabe0e52210538100f61e86e1740915
# renovate: datasource=github-releases depName=sharkdp/fd
ARG FD_VERSION=10.5.1
ARG FD_SHA256_AMD64=f6c95edb190c241df6fddc815a5bab4051444993ac5d92ddc6eec0e0dc2342c7
ARG FD_SHA256_ARM64=64c20b9b154c9d4b36d4b7df3521de771c499c4768b4b5b045ef6b01532117be
# renovate: datasource=github-releases depName=sharkdp/bat
ARG BAT_VERSION=0.26.1
ARG BAT_SHA256_AMD64=0dcd8ac79732c0d5b136f11f4ee00e581440e16a44eab5b3105b611bbf2cf191
ARG BAT_SHA256_ARM64=6369242c584065f195fb20cb36fbd7cb63ae690605bbe89868a7596b596c2c23
# renovate: datasource=github-releases depName=eza-community/eza
ARG EZA_VERSION=0.23.5
ARG EZA_SHA256_AMD64=35c70c5c43c29108075e58b893234c67ef585f0b53a7eaf8e9e7d4eec9f339b4
ARG EZA_SHA256_ARM64=40b87ae8628aa2ff0f0d2dc24ab52f689631366385c3da630bae745671fd71ec
# renovate: datasource=github-releases depName=junegunn/fzf
ARG FZF_VERSION=0.74.5
ARG FZF_SHA256_AMD64=d47d7f882972c7d674dbbba998ffa4116e68379616ffac7695d0671e9a722c5f
ARG FZF_SHA256_ARM64=cf058001da21724a469b714a29cf4aab9cbe860d218a0d6c1b5b661efad7784c
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.103.3
ARG GH_SHA256_AMD64=4c806978ffce1cec70853302a56d70ac6da4f19bae7adca4e1a8ab00633dd91d
ARG GH_SHA256_ARM64=ee32df2323c8847f5fac6cb6b4b69ca75828e9329a8f22f677021f7b3306ce63
# renovate: datasource=github-releases depName=git-lfs/git-lfs
ARG GITLFS_VERSION=3.8.1
ARG GITLFS_SHA256_AMD64=e72cf723a4a660438862282e8aecf3885fc8123e88bfcad534cf6b941a354b75
ARG GITLFS_SHA256_ARM64=67895dd77b63329796bc5efdd47b57f218e1f7b98717ebaf936a8238dbcaec0f
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=4.54.1
ARG YQ_SHA256_AMD64=8e34fc298390875de416e6a4afcb8cabeceb25d9aa8506c1a2f9353cf702ea5f
ARG YQ_SHA256_ARM64=189088da0c6429ec5178dfaab1a114805f6cab0b61b165ab236efedf1d57a71b
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
ARG PREK_VERSION=0.5.10
ARG PREK_SHA256_AMD64=c70a639cb98c90feafa213c23fb487644af73c906c5a6cee757403090f253c30
ARG PREK_SHA256_ARM64=352b97c18cc1659786232f3fde9e75b5ec96279893563f6b31b36f2d43dca00f

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
FROM docker.io/library/node:26-trixie-slim@sha256:e4db4c914bf8ad241bd24804fc25d272d89bad97e68cdc8a1414862790a02c39 AS node
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
