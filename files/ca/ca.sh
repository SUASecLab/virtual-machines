#!/bin/bash

CA_NAME=suasploitable_ca
CERT_NAME=suaseclab.de
DAYS_VALID=3650
PASSWORD=$(openssl rand -base64 32)

## Certificate authority
# Create root key, encrypted with AES
openssl genrsa -aes256 -passout pass:$PASSWORD -out $CA_NAME.key

# Create root certificate
openssl req -x509 -new -passin pass:$PASSWORD -nodes -key $CA_NAME.key -sha256 -days $DAYS_VALID -out $CA_NAME.crt -subj "/C=DE/ST=Thuringia/L=Schmalkalden/O=SUAS/OU=SUASecLab/CN=SUASploitable CA Root"

## Create certificate for SUASploitable services
# Create extensions file
cat > $CERT_NAME.v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = DNS:suaseclab.de,DNS:*.suaseclab.de
EOF

# Create certificate
openssl req -new -nodes -out $CERT_NAME.2048.csr -newkey rsa:2048 -keyout $CERT_NAME.2048.key -subj "/C=DE/ST=Thuringia/L=Schmalkalden/O=SUAS/OU=SUASecLab/CN=suaseclab.de"
openssl req -new -nodes -out $CERT_NAME.4096.csr -newkey rsa:4096 -keyout $CERT_NAME.4096.key -subj "/C=DE/ST=Thuringia/L=Schmalkalden/O=SUAS/OU=SUASecLab/CN=suaseclab.de"

# Sign certificate
openssl x509 -req -passin pass:$PASSWORD -in $CERT_NAME.2048.csr -CA $CA_NAME.crt -CAkey $CA_NAME.key -CAcreateserial -out $CERT_NAME.2048.crt -days $DAYS_VALID -sha256 -extfile $CERT_NAME.v3.ext
openssl x509 -req -passin pass:$PASSWORD -in $CERT_NAME.4096.csr -CA $CA_NAME.crt -CAkey $CA_NAME.key -CAcreateserial -out $CERT_NAME.4096.crt -days $DAYS_VALID -sha256 -extfile $CERT_NAME.v3.ext
