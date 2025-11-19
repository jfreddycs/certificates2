@echo off
setlocal enabledelayedexpansion

echo 🔐 Generating mTLS certificates with best practices...

mkdir certs 2>nul
cd certs

echo 📜 Generating Root CA...
openssl genrsa -aes256 -out ca.key -passout pass:changeit 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=State/L=City/O=Organization/CN=Root CA" -passin pass:changeit

echo 🖥️  Generating Server Certificate...
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=server"

(
echo authorityKeyIdentifier=keyid,issuer
echo basicConstraints=CA:FALSE
echo keyUsage=digitalSignature,keyEncipherment
echo extendedKeyUsage=serverAuth
echo subjectAltName=DNS:localhost,DNS:server,IP:127.0.0.1
) > server.ext

openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -extfile server.ext -passin pass:changeit

echo 💻 Generating Client Certificate...
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=client"

(
echo authorityKeyIdentifier=keyid,issuer
echo basicConstraints=CA:FALSE
echo keyUsage=digitalSignature,keyEncipherment
echo extendedKeyUsage=clientAuth
) > client.ext

openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -extfile client.ext -passin pass:changeit

echo 📦 Creating PKCS12 keystores...
openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12 -name server -CAfile ca.crt -caname root -passout pass:changeit -chain
openssl pkcs12 -export -in client.crt -inkey client.key -out client.p12 -name client -CAfile ca.crt -caname root -passout pass:changeit -chain

echo 🤝 Creating truststores...
keytool -import -trustcacerts -alias root -file ca.crt -keystore server-truststore.p12 -storetype PKCS12 -storepass changeit -noprompt
keytool -import -trustcacerts -alias root -file ca.crt -keystore client-truststore.p12 -storetype PKCS12 -storepass changeit -noprompt

del *.csr *.ext *.srl 2>nul

echo ✅ Certificate generation complete!
echo 📁 Generated files:
dir