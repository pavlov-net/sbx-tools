# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# Content recipe for the ssh-agent-proxy mixin (descriptor: ssh-agent-proxy.yaml).
FROM scratch
COPY --chmod=0755 files/ssh-agent-proxy-sign.sh  /usr/local/bin/ssh-agent-proxy-sign
COPY --chmod=0755 files/ssh-agent-proxy-setup.sh /usr/local/lib/ssh-agent-proxy-setup.sh
