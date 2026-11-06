# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# Content recipe for the python mixin (descriptor: python.yaml). Exact version
# in package.json, integrity hashes in package-lock.json. The .bin links are
# relative and resolve inside /opt/pyright.
FROM docker.io/library/node:26-trixie-slim@sha256:5adad64f9a1fca2d51972caa65983634c8a774eb300d72b20f7f2a0f60368072 AS build
COPY package.json package-lock.json /out/opt/pyright/
RUN cd /out/opt/pyright \
 && npm ci --omit=dev --no-audit --no-fund \
 && mkdir -p /out/usr/local/bin \
 && for b in pyright pyright-langserver; do \
      ln -s "/opt/pyright/node_modules/.bin/$b" "/out/usr/local/bin/$b"; \
    done

FROM scratch
COPY --from=build --chown=0:0 /out /
