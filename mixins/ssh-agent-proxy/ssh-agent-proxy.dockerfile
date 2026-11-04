# syntax=docker/dockerfile:1
# Content recipe for the ssh-agent-proxy mixin (descriptor: ssh-agent-proxy.yaml).
FROM scratch
COPY --chmod=0755 files/ssh-agent-proxy-sign.sh  /usr/local/bin/ssh-agent-proxy-sign
COPY --chmod=0755 files/ssh-agent-proxy-setup.sh /usr/local/lib/ssh-agent-proxy-setup.sh
