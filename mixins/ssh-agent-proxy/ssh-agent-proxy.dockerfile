# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# Content recipe for the ssh-agent-proxy mixin (descriptor: ssh-agent-proxy.yaml).
FROM scratch
COPY --chmod=0755 files/ssh-agent-proxy-sign.sh  /usr/local/bin/ssh-agent-proxy-sign
COPY --chmod=0755 files/ssh-agent-proxy-setup.sh /usr/local/lib/ssh-agent-proxy-setup.sh
