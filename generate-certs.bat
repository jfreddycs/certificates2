@echo off
echo Generating certificates for mTLS setup...

echo Creating Root CA...
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=Test CA"

echo Creating server certificate...
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=localhost"

echo Creating server extensions file...
echo subjectAltName=DNS:localhost > server.ext
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt -extfile server.ext

echo Creating client certificate...
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=client"
openssl x509 -req -days 3650 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 02 -out client.crt

echo Creating PKCS12 files...
openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12 -name server -passout pass:password
openssl pkcs12 -export -in client.crt -inkey client.key -out client.p12 -name client -passout pass:password

echo Cleaning up temporary files...
del server.csr
del client.csr
del server.ext

echo Certificate generation complete!
echo Files created:
echo - ca.key, ca.crt (Root CA)
echo - server.key, server.crt, server.p12 (Server certificates)
echo - client.key, client.crt, client.p12 (Client certificates)