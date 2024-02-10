#!/usr/bin/env bash

pushd "$(dirname $0)" >/dev/null

BUILD_PKI=y
GEN_SERVER_CONF=y
GEN_CLIENT_CONF=y
VPN_IP="127.0.0.1"

if [[ "$BUILD_PKI" == "y" ]]
then
    # Create PKI and CA
    easyrsa/easyrsa init-pki
    easyrsa/easyrsa build-ca nopass

    # Create the server certificate
    easyrsa/easyrsa build-server-full server0 nopass

    # Create the client certificate
    easyrsa/easyrsa build-client-full client0 nopass

    # Generate Diffie-Hellman paramters
    easyrsa/easyrsa gen-dh

    # Build TLS Auth for HMAC
    touch pki/ta.key
    podman build openvpn/ -t ovpn-tmp:1.0
    podman run -v "$(pwd)/pki/ta.key:/ta.key" -t localhost/ovpn-tmp:1.0 openvpn --genkey secret /ta.key
fi

if [[ "$GEN_SERVER_CONF" == "y" ]]
then
    cp pki/ca.crt config/openvpn
    cp pki/issued/server0.crt config/openvpn
    cp pki/private/server0.key config/openvpn
    cp pki/dh.pem config/openvpn/dh2048.pem
    cp pki/ta.key config/openvpn
fi

if [[ "$GEN_CLIENT_CONF" == "y" ]]
then
    mkdir -p config/clients
    FILE="config/clients/client0.ovpn"

    # First line, specify this is a client config
    echo "client" >"$FILE"
    # Copy server config
    cat config/openvpn/server.conf | grep -v "^#\|^;\|^$" >>"$FILE"

    # Remove server specific config
    sed -i '/^ca /d' "$FILE"
    sed -i '/^cert /d' "$FILE"
    sed -i '/^client-config-dir /d' "$FILE"
    sed -i '/^client-to-client /d' "$FILE"
    sed -i '/^dev-node /d' "$FILE"
    sed -i '/^dh /d' "$FILE"
    sed -i '/^duplicate-cn /d' "$FILE"
    sed -i '/^explicit-exit-notify /d' "$FILE"
    sed -i '/^group /d' "$FILE"
    sed -i '/^ifconfig-pool-persist /d' "$FILE"
    sed -i '/^key /d' "$FILE"
    sed -i '/^learn-address /d' "$FILE"
    sed -i '/^local /d' "$FILE"
    sed -i '/^log /d' "$FILE"
    sed -i '/^log-append /d' "$FILE"
    sed -i '/^max-clients /d' "$FILE"
    sed -i '/^port /d' "$FILE"
    sed -i '/^push /d' "$FILE"
    sed -i '/^route /d' "$FILE"
    sed -i '/^server /d' "$FILE"
    sed -i '/^server-bridge /d' "$FILE"
    sed -i '/^status /d' "$FILE"
    sed -i '/^tls-auth /d' "$FILE"
    sed -i '/^user /d' "$FILE"

    # Add client specific config
    echo "<ca>" >>"$FILE"
    cat pki/ca.crt >>"$FILE"
    echo "</ca>" >>"$FILE"
    echo "<cert>" >>"$FILE"
    cat pki/issued/client0.crt >>"$FILE"
    echo "</cert>" >>"$FILE"
    echo "<key>" >>"$FILE"
    cat pki/private/client0.key>>"$FILE"
    echo "</key>" >>"$FILE"
    echo "<tls-auth>" >>"$FILE"
    cat pki/ta.key >>"$FILE"
    echo "</tls-auth>" >>"$FILE"
    # Change key direction (tls-auth stuff)
    echo "key-direction 1" >>"$FILE"

    # Port is handled a bit differently on the client and server side. Extracting it to add it to the config
    PORT=$(grep "^port " config/openvpn/server.conf | awk '{print($2)}')

    echo "remote-cert-tls server" >>"$FILE"
    echo "remote $VPN_IP $PORT" >>"$FILE"

    # using client, dont bind a specific port
    echo "nobind" >>"$FILE"

    # Set resolv timeout to 15 seconds
    echo "resolv-retry 15" >>"$FILE"

fi

popd >/dev/null
