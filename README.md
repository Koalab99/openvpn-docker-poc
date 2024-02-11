# OpenVPN with LDAP Proof of Concept

## Setup
Installing OpenVPN requires a dedicated PKI. The PKI setup process was defined in `setup.sh`.

```
./setup.sh # And follow instruction
<ENTER>
yes
yes
```

The script will:
- create the PKI with one root CA, one certificate for the OpenVPN server and one for the client.
- Copy PKI files to openvpn config directory (`config/openvpn`) and template LDAP plugin configuration.
- Generate a client configuration file from the server configuration file (in `config/clients`)

## Start
You can start openvpn, openldap and phpldapadmin with `docker-compose`:
```
docker compose up -d
```

# Configure OpenLDAP
Then you're not done. You need to connect to the phpldapadmin on port 8080 [http://localhost:8080](http://localhost:8080).
- username: `cn=admin,dc=testldap`
- password: `admin`

You then need to create a default ldap group:
- "Create new entry here" > "Generic Posix Group"
- Set whatever name you want, it is not used by ovpn, and commit

Then create a second group named "vpn" this time. Its DN must be `cn=vpn,dc=testldap` (to work with the scripts and configuration)

Then create a user:
- "Create new entry here" > "Generic User Account"
- Fill the form with your user's data.
- "GID Number" should be set to the first group you created (this is a mandatory group).
- Write down the "Common Name", we'll need this in next step.

Then add the member to the `vpn` group:
- Go to the "cn=vpn" Page
- "Add new attribute" named "memberUid".
- Add the DN of the user (`cn=<COMMON_NAME>,dc=testldap`).

And you're good to go.

## Testing
We're simulating the client here.
On commandline:
```
openvpn config/clients/client0.ovpn
```
Will ask for common name and password.
The command wont give you back your shell.
Open another shell and verity you got a new route:
```
ip route
> ...
> 10.8.0.0/24 dev tun0 proto kernel scope link src 10.8.0.2
> ...
```
and
```
ping 10.8.0.1 # works
```
