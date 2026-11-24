# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# Content recipe for the python mixin (descriptor: python.yaml). Exact version
# in package.json, integrity hashes in package-lock.json. The .bin links are
# relative and resolve inside /opt/pyright.
FROM docker.io/library/node:26-trixie-slim@sha256:615a27817f7b9508f0de73eb1cc8fc8894ab122bee56c1a7a568b72cd1032067 AS build
COPY package.json package-lock.json /out/opt/pyright/
RUN cd /out/opt/pyright \
 && npm ci --omit=dev --no-audit --no-fund \
 && mkdir -p /out/usr/local/bin \
 && for b in pyright pyright-langserver; do \
      ln -s "/opt/pyright/node_modules/.bin/$b" "/out/usr/local/bin/$b"; \
    done

FROM scratch
COPY --from=build --chown=0:0 /out /
