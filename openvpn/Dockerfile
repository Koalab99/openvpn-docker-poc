FROM alpine:latest

RUN apk add --no-cache vim bash openvpn openvpn-auth-ldap && mkdir /var/log/openvpn

WORKDIR /etc/openvpn

CMD ["openvpn", "/etc/openvpn/server.conf"]

