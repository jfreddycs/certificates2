#!/bin/bash

set -e

echo "🔐 Generating Server Certificates..."
echo "===================================="

CERT_DIR="src/main/resources/certificates"
mkdir -p $CERT_DIR
cd $CERT_DIR

# Clean up existing certificates
rm -f *.key *.crt *.csr *.p12 *.jks *.srl

# Generate CA
echo "📜 Generating Certificate Authority..."
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
  -subj "/C=US/ST=California/L=San Francisco/O=Certificate Auth Demo/CN=Demo Root CA"

# Generate Server Certificate
echo "🖥️  Generating Server Certificate..."
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Certificate Auth Demo/CN=localhost"
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# Generate Client Certificate for testing
echo "📱 Generating Client Certificate..."
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Certificate Auth Demo/CN=client-app"
openssl x509 -req -days 3650 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt

# Create PKCS12 keystores
echo "📦 Creating PKCS12 Keystores..."
openssl pkcs12 -export -out server.p12 -inkey server.key -in server.crt \
  -name server -password pass:serverpass
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.crt \
  -name client -password pass:clientpass

# Create JKS truststore
echo "🏦 Creating Java Truststore..."
keytool -import -trustcacerts -alias ca -file ca.crt \
  -keystore truststore.jks -storepass trustpass -noprompt

# Set proper permissions
chmod 600 *.key
chmod 644 *.crt *.p12 *.jks

echo ""
echo "✅ Server certificates generated successfully!"
echo "📍 Location: $CERT_DIR"
echo ""
echo "📋 Certificate Details:"
echo "   Server Keystore: server.p12 (password: serverpass)"
echo "   Truststore: truststore.jks (password: trustpass)"
echo "   Client Certificate: client.p12 (password: clientpass)"