#!/bin/bash
#
# Autor: Mariano J. Obarrio Miles
# Fecha: 27/09/2017
# Mail : mariano.obarrio@gmail.com
# Description: Script para automatizar la instalacion y creacion de la configuracion de CONSUL.

clear 

echo "Inicio instalacion y configuracion de CONSUL (HASHICORP)"
##
## Definicion de variables globales
##
export ETCDIR=/etc/consul.d
export ETCTDIR=/etc/consul-template.d
export CFGDIR=${ETCDIR}/server
export TLSDIR=${ETCDIR}/tls
export DATADIR=/var/consul
export BINDIR=/opt/consul

##
## Variables para la generacion y firma de los certificados
##
export TLS_C=ES
export TLS_ST=Baleares
export TLS_L=Llucmajor
export TLS_O=GSIS
export TLS_CN=Globalia Sistemas SLU
export TLS_emailAddress=sysadmin@globalia-sistemas.com

##
## Crea directorios de trabajo
##
echo "- Creando directorios de trabajo"
echo "   $ETCDIR. Done"
echo "   $ETCTDIR. Done"
echo "   $CFGDIR. Done"
echo "   $TLSDIR. Done"
echo "   $DATADIR. Done"
echo "   $BINDIR. Done"
mkdir -p $ETCDIR
mkdir -p $ETCTDIR
mkdir -p $CFGDIR
mkdir -p $TLSDIR
mkdir -p $DATADIR
mkdir -p $BINDIR

##
## Definicion de funciones generales
##
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

##
## Generacion de certificados via OPENSSL para la utilizacion del GUI
##
function genCert {
  CANAME=consulCA
  DEVCERTNAME=consul
  echo " - Generando certificados para TLS/SSL"
  echo -n "   CA Name (${CANAME}): "; read CANAME
  echo -n "   Device Cert Name (${DEVCERTNAME}): "; read DEVCERTNAME
  CANAME=${CANAME:-consulCA}
  DEVCERTNAME=${DEVCERTNAME:-consul}

  openssl genrsa -out ${TLSDIR}/${CANAME}.key 2048 >/dev/null 2>&1
  openssl req -x509 -new -days 3650 -sha256 -nodes -subj "/C=${TLS_C}/ST=${TLS_ST}/L=${TLS_L}/O=${TLS_O}/CN=${TLS_CN}/emailAddress=${TLS_emailAddress}" -key ${TLSDIR}/${CANAME}.key -out ${TLSDIR}/${CANAME}.crt >/dev/null 2>&1
  openssl genrsa -out ${TLSDIR}/${DEVCERTNAME}.key 2048 >/dev/null 2>&1
  openssl req -new -newkey rsa:4096 -key ${TLSDIR}/${DEVCERTNAME}.key -out ${TLSDIR}/${DEVCERTNAME}.csr -subj "/C=${TLS_C}/ST=${TLS_ST}/L=${TLS_L}/O=${TLS_O}/CN=${TLS_CN}/emailAddress=${TLS_emailAddress}" >/dev/null 2>&1
  openssl req -x509 -new -newkey rsa:4096 -days 3650 -nodes -subj "/C=${TLS_C}/ST=${TLS_ST}/L=${TLS_L}/O=${TLS_O}/CN=${TLS_CN}/emailAddress=${TLS_emailAddress}" -key ${TLSDIR}/${DEVCERTNAME}.key -out ${TLSDIR}/${DEVCERTNAME}.crt >/dev/null 2>&1
}

##
## Solicita la version a descargar y valida que exista
##
function getVersion2Download {
  export CONSULVER=0.9.3
  echo -n "- Version de CONSUL a instalar ($CONSULVER): "; read CONSULVER
  CONSULVER=${CONSULVER:-0.9.3}
  export CONSUL_URL="https://releases.hashicorp.com/consul/${CONSULVER}/consul_${CONSULVER}_linux_amd64.zip"
  if [ `validate_url $CONSUL_URL` ]; then
     echo "ERROR: $CONSUL_URL (No existe)"; exit 0
  fi

  ##
  ## Descarga e instala consul
  ##
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


  export CONSULTEMPLATEVER=0.19.3
  echo -n "- Version de CONSUL TEMPLATE a instalar ($CONSULTEMPLATEVER): "; read CONSULVER
  CONSULVER=${CONSULVER:-0.9.3}
  export CONSUL_TEMPLATE_URL="https://releases.hashicorp.com/consul-template/${CONSULTEMPLATEVER}/consul-template_${CONSULTEMPLATEVER}_linux_amd64.zip"
  if [ `validate_url $CONSUL_TEMPLATE_URL` ]; then
     echo "ERROR: $CONSUL_TEMPLATE_URL (No existe)"; exit 0
  fi

  ##
  ## Descarga e instala consul
  ##
  cd $BINDIR
  echo -n " - Descargando $CONSULTEMPLATEVER. "
  wget -q $CONSUL_TEMPLATE_URL -O $BINDIR/consul_template_${CONSULTEMPLATEVER}_linux_amd64.zip
  echo "Done. "
  echo -n " - Instalando consul-template. "
  unzip consul_template_${CONSULTEMPLATEVER}_linux_amd64.zip >/dev/null 2>&1
  rm -f consul_template_${CONSULTEMPLATEVER}_linux_amd64.zip >/dev/null 2>&1
  chmod 755 consul-template
  chown consul:consul consul
  echo "Done. " 
}

##
## Verifica y crea usuario consul si no existe
##
function crearUsuario {
  if [ $(grep -c consul /etc/passwd) -eq 0 ]; then 
    echo " - Creando Usuario Consul"
    useradd -m consul >/dev/null 2>&1
    passwd consul
  fi
}


##
## MAIN
##
getVersion2Download                                 ## Solicita la version a descargar y valida que exista
crearUsuario                                        ## Verifica y crea usuario consul si no existe

##
## Asigna permisos a los directorios de instalacion
##
chown consul:consul $BINDIR
chown consul:consul $DATADIR
cd $BINDIR

##
## Crea una clave base64 de uso en los archivos de configuracion
##
export CONSUL_ENCRYPT=$(${BINDIR}/consul keygen)

##
## Generacion de certificados via OPENSSL para la utilizacion del GUI
##
genCert

##
## Definicion de Servidores que formaran el cluster.
##
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
DNS_PORT=8600
echo -n " - Puerto para GUI: ($SERVER_PORT): "; read SERVER_PORT
echo -n " - Puerto para DNS: ($DNS_PORT): "; read DNS_PORT
SERVER_PORT=${SERVER_PORT:-8080}
DNS_PORT=${DNS_PORT:-8600}


for i in $(seq "$NSERVER");
do
CFGNAME=$(echo ${NODOS[$i]}|tr . _)
cat <<EOF > ${CFGDIR}/${CFGNAME}-server.json
{
  "advertise_addr":"${NODOS[$i]}",
  "client_addr":"0.0.0.0",
  "bind_addr": "0.0.0.0",
  "datacenter": "globalia",
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
  "verify_outgoing": true,
  "verify_incoming": true,
  "key_file":  "${TLSDIR}/${DEVCERTNAME}.key",
  "cert_file": "${TLSDIR}/${DEVCERTNAME}.crt",
  "ca_file":   "${TLSDIR}/${CANAME}.crt",
  "ports": {
    "https": ${SERVER_PORT},
    "dns": ${DNS_PORT}
  },
  "retry_join": [ $RETRY_JOIN ]
}
EOF
done

## Informacion post instalacion
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
echo "  # $BINDIR/consul agent -ui -config-file=${CFGDIR}/${CFGNAME}-server.json"
echo
echo " - NOTA: Para borrar la instalacion ejecute: rm -fr /etc/consul.d/ /var/consul/ /opt/consul/"
echo
echo 

