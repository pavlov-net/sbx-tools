# syntax=docker/dockerfile:1
# Content recipe for the bun mixin (descriptor: bun.yaml).
FROM docker.io/library/debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4 AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
# renovate: datasource=npm depName=bun
ARG BUN_VERSION=1.4.4
ARG BUN_SHA256_AMD64=bf8ccbfb2b0b80159e0f9a6d15c55317add8077534dbc6130a3edb52fccb395c
ARG BUN_SHA256_ARM64=baa6bb36f51d6e58561e02bbea825038a9df454f673d6d776e8bbf86f8c7850e

RUN <<EOF
#!/usr/bin/env bash
set -euo pipefail
case "$TARGETARCH" in
  amd64) BUN_A=x64;     BUN_SHA256="$BUN_SHA256_AMD64" ;;
  arm64) BUN_A=aarch64; BUN_SHA256="$BUN_SHA256_ARM64" ;;
  *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;;
esac
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-${BUN_A}.zip" -o /tmp/bun.zip
echo "${BUN_SHA256}  /tmp/bun.zip" | sha256sum -c -
mkdir -p /out/opt/bun/bin
unzip -q -j /tmp/bun.zip "bun-linux-${BUN_A}/bun" -d /out/opt/bun/bin
EOF

FROM scratch
COPY --from=build --chown=0:0 /out /

# Entry points: through Socket Firewall when the sfw mixin is present.
COPY --chmod=0755 <<'EOF' /usr/local/bin/bun
#!/bin/sh
[ -x /opt/socket/bin/sfw ] && exec /opt/socket/bin/sfw /opt/bun/bin/bun "$@"
exec /opt/bun/bin/bun "$@"
EOF
COPY --chmod=0755 <<'EOF' /usr/local/bin/bunx
#!/bin/sh
exec /usr/local/bin/bun x "$@"
EOF

# Appended to the workload's PATH: where `bun install -g` puts executables.
ENV PATH=/home/agent/.bun/bin
