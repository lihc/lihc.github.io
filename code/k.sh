CA_NAME='kubernetes-ca'
SERVER_NAME='apiserver'

openssl genrsa -out ${CA_NAME}.key 2048
openssl req -new -key ${CA_NAME}.key -nodes -out ${CA_NAME}.csr -subj "/CN=${CA_NAME}"

cat > ${CA_NAME}.cnf <<EOF
[ca_extensions]
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, keyEncipherment, keyCertSign
subjectKeyIdentifier = hash
subjectAltName = DNS:kubernetes
EOF

openssl x509 -req -extensions ca_extensions -days 3650 \
        -signkey ${CA_NAME}.key -in ${CA_NAME}.csr  \
        -extfile ${CA_NAME}.cnf -out ${CA_NAME}.crt


openssl genrsa -out ${SERVER_NAME}.key 2048
openssl req -new -key ${SERVER_NAME}.key -nodes -out ${SERVER_NAME}.csr -subj "/CN=${SERVER_NAME}"

cat > ${SERVER_NAME}.cnf <<EOF
[server_extensions]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
basicConstraints = critical, CA:FALSE
subjectKeyIdentifier = hash
subjectAltName = DNS:centos
EOF

openssl x509 -req -extensions server_extensions -days 3650 \
        -CA ${CA_NAME}.crt -CAkey ${CA_NAME}.key -CAcreateserial \
        -in ${SERVER_NAME}.csr -extfile ${SERVER_NAME}.cnf -out ${SERVER_NAME}.crt

# openssl req -noout -text -in ca.crt
# openssl x509 -noout -text -in ca.csr
