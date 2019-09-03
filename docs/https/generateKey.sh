#!/bin/bash
BASE=`pwd`
EXT_FILE=${BASE}/server-ext-ip.txt
SERVER=${BASE}/server
CLIENT=${BASE}/client
ROOT=${BASE}/root
CN_NAME=CHINA
ROOT_CONF=root_cert.conf
SERVER_CONF=server_cert.conf
CLIENT_CONF=client_cert.conf
PROJECT_NAME="TLS Project"

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

mkdir $SERVER
mkdir $CLIENT
mkdir $ROOT
}

function genConfigFile(){

cat << EOF > ${ROOT}/${ROOT_CONF}
[ req ]
distinguished_name     = req_distinguished_name
prompt                 = no

[ req_distinguished_name ]
 O                      = $PROJECT_NAME Dodgy Certificate Authority
EOF

cat << EOF > ${SERVER}/${SERVER_CONF}
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = IP:169.254.110.194, IP:fd00::5, IP:10.154.129.144, IP:fd00::4, DNS:*.ca.eo.cmcc
EOF

cat << EOF > ${CLIENT}/${CLIENT_CONF}
[ req ]
distinguished_name     = req_distinguished_name
prompt                 = no

[ req_distinguished_name ]
 O                      = $PROJECT_NAME Device Certificate
 CN                     = 192.168.72.18
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
 openssl req -out ${ROOT}/root.csr  -new  -newkey rsa:2048 -nodes -keyout ${ROOT}/root.key -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
 openssl req -out ${CLIENT}/client.csr  -new  -newkey rsa:2048 -nodes -keyout ${CLIENT}/client.key -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
 openssl req -out ${SERVER}/server.csr  -new  -newkey rsa:2048 -nodes -keyout ${SERVER}/server.key -subj "/C=CN/ST=BJ/L=BJ/O=ericsson/OU=ericsson/CN=${CN_NAME}"
}


function genCASign(){
 openssl  x509  -req -in ${ROOT}/root.csr -days 1000 -sha1 -extensions v3_ca  -signkey ${ROOT}/root.key  -out ${ROOT}/root.crt
 openssl  x509  -req -in ${CLIENT}/client.csr -days 1000 -sha1 -extensions v3_ca -CA ${ROOT}/root.crt -CAkey ${ROOT}/root.key -CAserial ${CLIENT}/client.srl  -CAcreateserial  -out ${CLIENT}/client.crt
#openssl  x509  -req -in ${SERVER}/server.csr -days 1000  -CA ${ROOT}/root.crt -CAkey ${ROOT}/root.key -CAserial ${SERVER}/server.srl  -CAcreateserial -out ${SERVER}/server.crt -extfile ${EXT_FILE}

openssl  x509  -req -in ${SERVER}/server.csr -days 1000  -CA ${ROOT}/root.crt -CAkey ${ROOT}/root.key -CAserial ${SERVER}/server.srl  -CAcreateserial -out ${SERVER}/server.crt -extfile ${SERVER}/${SERVER_CONF}
}

function genPKCS(){
 openssl pkcs12 -export -in ${CLIENT}/client.crt -inkey ${CLIENT}/client.key -out ${CLIENT}/client.p12 -name sslclient -password pass:'123456'
 openssl pkcs12 -export -in ${SERVER}/server.crt -inkey ${SERVER}/server.key -out ${SERVER}/server.p12 -name sslserver -password pass:'123456'
}

function genKeyStore(){
 keytool -importkeystore -srckeystore ${CLIENT}/client.p12 -destkeystore ${CLIENT}/client.keystore -srcstoretype PKCS12 -srcstorepass '123456' -deststoretype JKS -deststorepass '123456' -srcalias sslclient -destalias sslclient
 keytool -importkeystore -srckeystore ${SERVER}/server.p12 -destkeystore ${SERVER}/server.keystore -srcstoretype PKCS12 -srcstorepass '123456' -deststoretype JKS -deststorepass '123456' -srcalias sslserver -destalias sslserver
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
    removeTmpFile
}

main
