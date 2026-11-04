# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# Content recipe for the sfw mixin (descriptor: sfw.yaml).
FROM docker.io/library/debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4 AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
# renovate: datasource=github-releases depName=SocketDev/sfw-free
ARG SFW_VERSION=1.16.0
ARG SFW_SHA256_AMD64=1f24d2628aeb3995f1f2651509e37641c7c41d07749ac68594ecb5bb2dd44d8a
ARG SFW_SHA256_ARM64=474cdb684e42d33d4b697dedd7d90c159d71380be0e53c496f0e7097c3617a6c

RUN <<EOF
#!/usr/bin/env bash
set -euo pipefail
case "$TARGETARCH" in
  amd64) SFW_A=x86_64; SFW_SHA256="$SFW_SHA256_AMD64" ;;
  arm64) SFW_A=arm64;  SFW_SHA256="$SFW_SHA256_ARM64" ;;
  *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;;
esac
curl -fsSL "https://github.com/SocketDev/sfw-free/releases/download/v${SFW_VERSION}/sfw-free-linux-${SFW_A}" -o /tmp/sfw
echo "${SFW_SHA256}  /tmp/sfw" | sha256sum -c -
install -D -m 0755 /tmp/sfw /out/opt/socket/bin/sfw

# Shims for the workload's package managers (sfw.yaml requires them).
# /usr/local/bin precedes /usr/bin on the workload PATH; a mixin can't prepend
# a directory of its own. npm, bun and cargo wrap themselves in their own
# mixins.
mkdir -p /out/usr/local/bin
for cmd in uv uvx; do
  printf '#!/bin/sh\nexec /opt/socket/bin/sfw /usr/bin/%s "$@"\n' "$cmd" > "/out/usr/local/bin/$cmd"
  chmod 0755 "/out/usr/local/bin/$cmd"
done
# pip goes through uv's pip-compatible interface.
for cmd in pip pip3; do
  printf '#!/bin/sh\nexec /opt/socket/bin/sfw /usr/bin/uv pip "$@"\n' > "/out/usr/local/bin/$cmd"
  chmod 0755 "/out/usr/local/bin/$cmd"
done
EOF

FROM scratch
COPY --from=build --chown=0:0 /out /
