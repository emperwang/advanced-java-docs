#!/bin/bash
BASE=`pwd`
EXT_FILE=${BASE}/server-ext-ip.txt
CA_FILE=${BASE}/root_cert.conf
SERVER=${BASE}/server
CLIENT=${BASE}/client
ROOT=${BASE}/root
DB=${BASE}/root/db
PRIVATE=${BASE}/root/private
CERT=${BASE}/root/certs

CN_NAME=CHIN
SERVER_CONF=server_cert.conf

# mkdir new dir
function createDir(){
if [ -d ${SERVER} ]; then
    echo "${SERVER} is exist.."
    exit 1
fi


if [ -d ${CLIENT} ]; then
    echo "${CLIENT} is exist.."
    exit 1
fi


if [ -d ${ROOT} ]; then
    echo "${ROOT} is exist.."
    exit 1
fi
if [ -d ${DB} ]; then
    echo "${DB} is exist.."
    exit 1
fi
mkdir -p  $DB
touch ${DB}/{index,serial,crlnumber}
openssl rand -hex 16 > ${DB}/serial
mkdir -p  ${PRIVATE}
mkdir -p  ${CERT}
mkdir $SERVER
mkdir $CLIENT
}

function genConfigFile(){
cat << EOF > ${SERVER}/${SERVER_CONF}
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = IP:192.168.72.18, IP:192.168.72.1, IP:10.154.129.144, IP:fd00::4, DNS:*.ca.eo.cmcc
EOF
}

function genPrivatekey(){
  openssl genrsa -des3 -out ${ROOT}/root.key 2048
  openssl genrsa -des3 -out ${SERVER}/server.key 2048
  openssl genrsa -des3 -out ${CLIENT}/client.key 2048
}

function genCsr(){
  openssl req -new -key ${ROOT}/root.key -out ${ROOT}/root.csr -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
  openssl req -new -key ${CLIENT}/client.key -out ${CLIENT}/client.csr -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
  openssl req -new -key ${SERVER}/server.key -out ${SERVER}/server.csr -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
}

function genPrivateAndCsr(){
openssl req -out ${ROOT}/root.csr -config ${CA_FILE} -new  -newkey rsa:2048 -nodes -keyout ${PRIVATE}/root.key -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
openssl req -out ${CLIENT}/client.csr  -new  -newkey rsa:2048 -nodes -keyout ${CLIENT}/client.key -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
openssl req -out ${SERVER}/server.csr  -new  -newkey rsa:2048 -nodes -keyout ${SERVER}/server.key -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
}

function genCASign(){
openssl  ca -selfsign  -in ${ROOT}/root.csr -days 1000 -config ${CA_FILE} -extensions ca_ext   -keyfile ${PRIVATE}/root.key  -out ${ROOT}/root.crt
openssl  x509  -req -in ${CLIENT}/client.csr -days 1000 -sha1 -CA ${ROOT}/root.crt -CAkey ${PRIVATE}/root.key -CAserial ${CLIENT}/client.srl  -CAcreateserial  -out ${CLIENT}/client.crt
#openssl  x509  -req -in ${SERVER}/server.csr -days 1000  -CA ${ROOT}/root.crt -CAkey ${ROOT}/root.key -CAserial ${SERVER}/server.srl  -CAcreateserial -out ${SERVER}/server.crt -extfile ${EXT_FILE}

openssl  x509  -req -in ${SERVER}/server.csr -days 1000  -CA ${ROOT}/root.crt -CAkey ${PRIVATE}/root.key -CAserial ${SERVER}/server.srl  -CAcreateserial -out ${SERVER}/server.crt -extfile ${SERVER}/${SERVER_CONF}
#openssl  x509  -req -in ${SERVER}/server.csr -days 1000  -CA ${ROOT}/root.crt -CAkey ${ROOT}/root.key -CAserial ${SERVER}/server.srl  -CAcreateserial -out ${SERVER}/server.crt
}

function genPKCS(){
openssl pkcs12 -export -in ${CLIENT}/client.crt -inkey ${CLIENT}/client.key -out ${CLIENT}/client.p12 -name sslclient -password pass:'123456'
openssl pkcs12 -export -in ${SERVER}/server.crt -inkey ${SERVER}/server.key -out ${SERVER}/server.p12 -name sslserver -password pass:'123456'
}

function genKeyStore(){
keytool -importkeystore -srckeystore ${CLIENT}/client.p12 -destkeystore ${CLIENT}/client.keystore -srcstoretype PKCS12 -srcstorepass '123456' -deststoretype JKS -deststorepass '123456' -srcalia
s sslclient -destalias sslclient
keytool -importkeystore -srckeystore ${SERVER}/server.p12 -destkeystore ${SERVER}/server.keystore -srcstoretype PKCS12 -srcstorepass '123456' -deststoretype JKS -deststorepass '123456' -srcalia
s sslserver -destalias sslserver
}

function genTrust(){
keytool -import -trustcacerts -alias sslroot -file ${ROOT}/root.crt -keystore ${CLIENT}/clientTrust  -deststorepass '123456' -noprompt
keytool -importcert  -alias sslserver -file ${SERVER}/server.crt -keystore ${CLIENT}/clientTrust -storepass '123456' -deststorepass '123456' -noprompt
keytool -import -trustcacerts -alias sslroot -file ${ROOT}/root.crt -keystore ${SERVER}/serverTrust  -deststorepass '123456'   -noprompt
keytool -importcert  -alias sslclient -file ${CLIENT}/client.crt -keystore ${SERVER}/serverTrust -storepass '123456' -deststorepass '123456'  -noprompt
}


function removeTmpFile(){
  rm  -f  ${ROOT}/*.conf
  rm  -f  ${ROOT}/*.csr


  rm  -f  ${SERVER}/*.conf
  rm  -f  ${SERVER}/*.csr
  rm  -f  ${SERVER}/*.srl
  rm  -f  ${SERVER}/*.key
  rm  -f  ${SERVER}/*.crt


  rm  -f  ${CLIENT}/*.conf
  rm  -f  ${CLIENT}/*.srl
  rm  -f  ${CLIENT}/*.csr
  rm  -f  ${CLIENT}/*.key
  rm  -f  ${CLIENT}/*.crt
}


function main(){
    createDir
    genConfigFile
    #genPrivatekey
    #genCsr
    genPrivateAndCsr
    genCASign
    genPKCS
    genKeyStore
    genTrust
    #removeTmpFile
}

main