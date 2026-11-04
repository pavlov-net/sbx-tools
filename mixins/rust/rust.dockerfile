# syntax=docker/dockerfile:1
# Content recipe for the rust mixin (descriptor: rust.yaml). rustup and the
# toolchain live under /opt/rust, owned by the agent so `rustup update` and
# `cargo install` work without root. The toolchain and the cargo extras are
# separate stages so bumping one doesn't refetch the other.
FROM docker.io/library/debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4 AS base
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
ENV RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo

FROM base AS toolchain
# renovate: datasource=github-releases depName=rust-lang/rust
ARG RUST_VERSION=1.99.1
RUN curl -fsSL https://sh.rustup.rs -o /tmp/rustup-init.sh \
 && sh /tmp/rustup-init.sh -y --no-modify-path --profile minimal --default-toolchain "${RUST_VERSION}" \
 && "$CARGO_HOME/bin/rustup" component add rust-analyzer clippy rustfmt \
 && chown -R 1000:1000 /opt/rust

FROM base AS extras
ARG TARGETARCH
# renovate: datasource=github-releases depName=cargo-bins/cargo-binstall
ARG CARGO_BINSTALL_VERSION=1.26.2
ARG CARGO_BINSTALL_SHA256_AMD64=9e0e064f189a9abb9f8df5fb93c3c810ef5cc19e7212d998c7a64c9e4d3527d5
ARG CARGO_BINSTALL_SHA256_ARM64=a235250cd684af9bf1e3a1e4c216b1d36e6c553553d5d789744f27689d81c2d6
# renovate: datasource=crate depName=cargo-cache
ARG CARGO_CACHE_VERSION=0.8.3
ARG CARGO_CACHE_SHA256_AMD64=d15a838e33b52fbc50b991ad46414ac68dd2c5eb01e2bbd19a5712188998864e
ARG CARGO_CACHE_SHA256_ARM64=f73d3057c23d72c5210e1fd855a7f58568b9ba35c5c5cf3ba3b3d6482d3a7bd8
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
BIN=/out/opt/rust/cargo/bin
mkdir -p "$BIN"

# cargo-binstall: prebuilt crate binaries instead of compiling from source.
fetch CARGO_BINSTALL "https://github.com/cargo-bins/cargo-binstall/releases/download/v${CARGO_BINSTALL_VERSION}/cargo-binstall-${A}-unknown-linux-musl.tgz"
tar -xzf /tmp/CARGO_BINSTALL -C "$BIN" cargo-binstall

# cargo-cache: upstream ships no binaries; this is the cargo-quickinstall rebuild.
fetch CARGO_CACHE "https://github.com/cargo-bins/cargo-quickinstall/releases/download/cargo-cache-${CARGO_CACHE_VERSION}/cargo-cache-${CARGO_CACHE_VERSION}-${A}-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/CARGO_CACHE -C "$BIN" cargo-cache
chown -R 1000:1000 /out/opt/rust
EOF

# Ownership is set in the build stages: COPY --chown would also hand the
# agent /opt itself, and a mixin's directory entries replace the workload's.
FROM scratch
COPY --from=toolchain /opt /opt
COPY --from=extras /out/ /

# Entry point: through Socket Firewall when the sfw mixin is present.
COPY --chmod=0755 <<'EOF' /usr/local/bin/cargo
#!/bin/sh
[ -x /opt/socket/bin/sfw ] && exec /opt/socket/bin/sfw /opt/rust/cargo/bin/cargo "$@"
exec /opt/rust/cargo/bin/cargo "$@"
EOF

# Additive at assembly; PATH is appended.
ENV RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo \
    PATH=/opt/rust/cargo/bin
