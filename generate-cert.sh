#!/bin/bash
set -e

echo "🔐 Generating mTLS certificates..."

mkdir -p certs
cd certs

# Root CA
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
  -subj "/C=US/ST=CA/L=San Francisco/O=MTLS Demo/CN=Root CA"

# Server Certificate
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=CA/L=San Francisco/O=MTLS Demo/CN=server"

cat > server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:localhost,DNS:server,IP:127.0.0.1
EOF

openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -extfile server.ext

# Client Certificate  
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr \
  -subj "/C=US/ST=CA/L=San Francisco/O=MTLS Demo/CN=client"

cat > client.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
EOF

openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt -extfile client.ext

# Create PKCS12 files
openssl pkcs12 -export -in server.crt -inkey server.key \
  -out server.p12 -name server -passout pass:changeit

openssl pkcs12 -export -in client.crt -inkey client.key \
  -out client.p12 -name client -passout pass:changeit

# Create truststores
keytool -import -trustcacerts -alias root -file ca.crt \
  -keystore server-truststore.p12 -storetype PKCS12 \
  -storepass changeit -noprompt

keytool -import -trustcacerts -alias root -file ca.crt \
  -keystore client-truststore.p12 -storetype PKCS12 \
  -storepass changeit -noprompt

# Cleanup
rm -f *.csr *.ext *.srl

echo "✅ Certificates generated in ./certs/"