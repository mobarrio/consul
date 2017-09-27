#!/bin/bash

clear

function join_by { local IFS="$1"; shift; echo "$*"; }
function validate_url(){
  FILEEXIST=$(wget -S --spider $1 2>&1|grep -ic 'HTTP/1.1 200 OK')
  if [ "x$FILEEXIST" == "x1" ]; then
    return 0 # 0 = true
  else
    echo "false"
    return 1 # 1 = false
  fi
}

echo 
export CONSULVER=0.9.3
echo -n "Version de CONSUL a instalar (0.9.3): "; read CONSULVER
CONSULVER=${CONSULVER:-0.9.3}

export CONSUL_URL="https://releases.hashicorp.com/consul/${CONSULVER}/consul_${CONSULVER}_linux_amd64.zip"
if [ `validate_url $CONSUL_URL` ]; then
   echo "ERROR: $CONSUL_URL (No existe)"; exit 0
fi

echo 
echo "Inicio instalacion CONSUL V${CONSULVER}"
echo 
if [ $(grep -c consul /etc/passwd) -eq 0 ]; then 
  echo " - Creando Usuario Consul"
  useradd -m consul >/dev/null 2>&1
  passwd consul
  echo
fi

export ETCDIR=/etc/consul.d
export CFGDIR=${ETCDIR}/server
export TLSDIR=${ETCDIR}/tls
export DATADIR=/var/consul
export BINDIR=/opt/consul

mkdir -p $ETCDIR
mkdir -p $CFGDIR
mkdir -p $TLSDIR
mkdir -p $DATADIR
mkdir -p $BINDIR
chown consul:consul $BINDIR
chown consul:consul $DATADIR
cd $BINDIR

echo -n " - Descargando $CONSUL_URL. "
wget -q $CONSUL_URL -O $BINDIR/consul_${CONSULVER}_linux_amd64.zip
echo "Done. "
echo -n " - Instalando consul. "
unzip consul_${CONSULVER}_linux_amd64.zip >/dev/null 2>&1
rm -f consul_${CONSULVER}_linux_amd64.zip >/dev/null 2>&1
chmod 755 consul
chown consul:consul consul
echo "Done. "

export CONSUL_ENCRYPT=$(${BINDIR}/consul keygen)

echo
CANAME=consulCA
DEVCERTNAME=consul
echo " - Generando certificados para TLS/SSL"
echo -n "   CA Name (${CANAME}): "; read CANAME
echo -n "   Device Cert Name (${DEVCERTNAME}): "; read DEVCERTNAME
CANAME=${CANAME:-consulCA}
DEVCERTNAME=${DEVCERTNAME:-consul}

openssl genrsa -out ${TLSDIR}/${CANAME}.key 2048 >/dev/null 2>&1
openssl req -x509 -new -days 3650 -sha256 -nodes -subj "/C=ES/ST=Baleares/L=Llucmajor/O=GSIS/CN=Globalia Sistemas SLU/emailAddress=sysadmin@globalia-sistemas.com" -key ${TLSDIR}/${CANAME}.key -out ${TLSDIR}/${CANAME}.crt >/dev/null 2>&1
openssl genrsa -out ${TLSDIR}/${DEVCERTNAME}.key 2048 >/dev/null 2>&1
openssl req -new -newkey rsa:4096 -key ${TLSDIR}/${DEVCERTNAME}.key -out ${TLSDIR}/${DEVCERTNAME}.csr -subj "/C=ES/ST=Baleares/L=Llucmajor/O=GSIS/CN=Globalia Sistemas SLU/emailAddress=sysadmin@globalia-sistemas.com" >/dev/null 2>&1
openssl req -x509 -new -newkey rsa:4096 -days 3650 -nodes -subj "/C=ES/ST=Baleares/L=Llucmajor/O=GSIS/CN=Globalia Sistemas SLU/emailAddress=sysadmin@globalia-sistemas.com" -key ${TLSDIR}/${DEVCERTNAME}.key -out ${TLSDIR}/${DEVCERTNAME}.crt >/dev/null 2>&1

echo

NSERVER=1
echo -n " - Numero de Consul Servers ($NSERVER): "; read NSERVER
NSERVER=${NSERVER:-1}

for i in $(seq "$NSERVER");
do
   echo -n "   IP Nodo ${i} : "; read NODE_IP
   NODOS[$i]="${NODE_IP}"
   NODOS_RETRY[$i]=\"${NODE_IP}:8301\"
done

RETRY_JOIN=$(join_by , "${NODOS_RETRY[@]}")

SERVER_PORT=8080
echo
echo -n " - Puerto para GUI: ($SERVER_PORT): "; read SERVER_PORT
SERVER_PORT=${SERVER_PORT:-8080}


for i in $(seq "$NSERVER");
do
CFGNAME=$(echo ${NODOS[$i]}|tr . _)
cat <<EOF > ${CFGDIR}/${CFGNAME}-server.json
{
  "bind_addr": "${NODOS[$i]}", 
  "datacenter": "dc1",
  "data_dir": "${DATADIR}",
  "encrypt": "${CONSUL_ENCRYPT}",
  "log_level": "INFO",
  "enable_syslog": true,
  "enable_debug": true,
  "node_name": "node-${i}",
  "server": true,
  "bootstrap_expect": 1,
  "leave_on_terminate": false,
  "skip_leave_on_interrupt": true,
  "rejoin_after_leave": true,
  "retry_interval": "30s",
  "key_file":  "${TLSDIR}/${DEVCERTNAME}.key",
  "cert_file": "${TLSDIR}/${DEVCERTNAME}.crt",
  "ca_file":   "${TLSDIR}/${CANAME}.crt",
  "ports": {
    "https": ${SERVER_PORT}
  },
  "retry_join": [ $RETRY_JOIN ]
}
EOF
done

echo
echo "- Copie las configuraciones a cada server"
for i in $(seq "$NSERVER");
do
   CFGNAME=$(echo ${NODOS[$i]}|tr . _)
   echo "  # scp ${CFGDIR}/${CFGNAME}-server.json ${NODOS[$i]}:${CFGDIR}/${CFGNAME}-server.json"
done

echo
echo "- Starting CONSUL Server"
CFGNAME=$(echo ${NODOS[1]}|tr . _)
echo "  # $BINDIR/consul agent -config-file=${CFGDIR}/${CFGNAME}-server.json -ui"
echo
echo " - NOTA: Para borrar la instalacion ejecute: rm -fr /etc/consul.d/ /var/consul/ /opt/consul/"
echo
echo 

