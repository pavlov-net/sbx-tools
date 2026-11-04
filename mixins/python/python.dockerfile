# syntax=docker/dockerfile:1
# Content recipe for the python mixin (descriptor: python.yaml). Exact version
# in package.json, integrity hashes in package-lock.json. The .bin links are
# relative and resolve inside /opt/pyright.
FROM docker.io/library/node:26-trixie-slim@sha256:e4db4c914bf8ad241bd24804fc25d272d89bad97e68cdc8a1414862790a02c39 AS build
COPY package.json package-lock.json /out/opt/pyright/
RUN cd /out/opt/pyright \
 && npm ci --omit=dev --no-audit --no-fund \
 && mkdir -p /out/usr/local/bin \
 && for b in pyright pyright-langserver; do \
      ln -s "/opt/pyright/node_modules/.bin/$b" "/out/usr/local/bin/$b"; \
    done

FROM scratch
COPY --from=build --chown=0:0 /out /
