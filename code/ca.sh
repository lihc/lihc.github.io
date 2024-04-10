#!/bin/bash

SERVER='example.com'

openssl genrsa -out ca.key 2048 > /dev/null 2>&1
openssl req -new -key ca.key -nodes -out ca.csr -subj "/CN=CA-example"

cat > v3.ext <<EOF
[ca_extensions]
basicConstraints = CA:true
keyUsage = cRLSign, keyCertSign

[server_extensions]
basicConstraints = CA:false
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[client_extensions]
basicConstraints = CA:false
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${SERVER}
DNS.2 = www.${SERVER}
EOF

openssl x509 -req -extensions ca_extensions -days 3650 \
        -signkey ca.key -in ca.csr  \
        -extfile v3.ext -out ca.crt > /dev/null 2>&1

openssl genrsa -out ${SERVER}.key 2048 > /dev/null 2>&1
openssl req -new -key ${SERVER}.key -nodes -out ${SERVER}.csr -subj "/CN=${SERVER}"

openssl x509 -req -extensions server_extensions -days 3650 \
        -CA ca.crt -CAkey ca.key -CAcreateserial \
        -in ${SERVER}.csr -extfile v3.ext -out ${SERVER}.crt > /dev/null 2>&1

# openssl req -noout -text -in ca.crt
# openssl x509 -noout -text -in ca.csr
