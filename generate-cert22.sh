#!/bin/bash
set -e

echo "🔐 Generating mTLS certificates with best practices..."

# Create directories
mkdir -p certs
cd certs

# Generate Root CA
echo "📜 Generating Root CA..."
openssl genrsa -aes256 -out ca.key -passout pass:changeit 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=Root CA" \
  -passin pass:changeit

# Generate Server Certificate
echo "🖥️  Generating Server Certificate..."
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=server"

cat > server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:localhost,DNS:server,IP:127.0.0.1
EOF

openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -extfile server.ext -passin pass:changeit

# Generate Client Certificate
echo "💻 Generating Client Certificate..."
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=client"

cat > client.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
EOF

openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt -extfile client.ext -passin pass:changeit

# Create PKCS12 keystores
echo "📦 Creating PKCS12 keystores..."
openssl pkcs12 -export -in server.crt -inkey server.key \
  -out server.p12 -name server -CAfile ca.crt -caname root \
  -passout pass:changeit -chain

openssl pkcs12 -export -in client.crt -inkey client.key \
  -out client.p12 -name client -CAfile ca.crt -caname root \
  -passout pass:changeit -chain

# Create truststores
echo "🤝 Creating truststores..."
keytool -import -trustcacerts -alias root -file ca.crt \
  -keystore server-truststore.p12 -storetype PKCS12 \
  -storepass changeit -noprompt

keytool -import -trustcacerts -alias root -file ca.crt \
  -keystore client-truststore.p12 -storetype PKCS12 \
  -storepass changeit -noprompt

# Cleanup
rm -f *.csr *.ext *.srl

echo "✅ Certificate generation complete!"
echo "📁 Generated files:"
ls -la