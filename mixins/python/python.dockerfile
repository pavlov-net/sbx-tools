# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# Content recipe for the python mixin (descriptor: python.yaml). Exact version
# in package.json, integrity hashes in package-lock.json. The .bin links are
# relative and resolve inside /opt/pyright.
FROM docker.io/library/node:26-trixie-slim@sha256:e6bedef217677b276c591795e169840edd9096dbf13f29df8ef8d1856b8820bc AS build
COPY package.json package-lock.json /out/opt/pyright/
RUN cd /out/opt/pyright \
 && npm ci --omit=dev --no-audit --no-fund \
 && mkdir -p /out/usr/local/bin \
 && for b in pyright pyright-langserver; do \
      ln -s "/opt/pyright/node_modules/.bin/$b" "/out/usr/local/bin/$b"; \
    done

FROM scratch
COPY --from=build --chown=0:0 /out /
