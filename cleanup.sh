#!/usr/bin/env bash
pushd "$(dirname $0)" >/dev/null

docker compose down
rm -rf pki
rm -rf config/clients
rm -f config/openvpn/{auth-ldap.conf,ca.crt,dh2048.pem,server0.crt,server0.key,ta.key}

popd >/dev/null
