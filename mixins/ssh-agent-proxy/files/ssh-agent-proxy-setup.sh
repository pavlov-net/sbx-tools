#!/usr/bin/env bash
# ssh-agent-proxy-setup: configure git commit signing if the proxy answers.
# Run in the background by the ssh-agent-proxy mixin's startup hook on every
# boot. Retries for a minute in case the proxy comes up after the sandbox;
# if it never answers, git is left unconfigured.
#
# https://github.com/pavlov-net/ssh-agent-proxy
set -u

base="http://${SSH_AGENT_PROXY_HOST}:${SSH_AGENT_PROXY_PORT}"
for _ in $(seq 30); do
    pubkey=$(curl --silent --fail --connect-timeout 1 --max-time 2 "${base}/publickey") && break
    sleep 2
done
[ -n "${pubkey:-}" ] || exit 0

mkdir -p "$HOME/.cache/ssh-agent-proxy"
printf '%s\n' "$pubkey" > "$HOME/.cache/ssh-agent-proxy/signing.pub"

git config --global gpg.format ssh
git config --global gpg.ssh.program /usr/local/bin/ssh-agent-proxy-sign
git config --global user.signingkey "$HOME/.cache/ssh-agent-proxy/signing.pub"
git config --global commit.gpgsign true
git config --global tag.gpgsign true
