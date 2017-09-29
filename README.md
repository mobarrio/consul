Consul by HasiCorp 
===

Script que automatiza la instalacion de  Hasicorp CONSUL y genera una configuracion basica.

**Para saber cuales son las ultimas versiones de consul y consul-template verificar:** 
```
  Consul           : https://github.com/hashicorp/consul
  Consul templates : https://github.com/hashicorp/consul-template
```


### Instalacion:
```
[root@grafana01 consul.git]# ./install-consul.sh 
Inicio instalacion y configuracion de CONSUL (HASHICORP)
- Creando directorios de trabajo
   /etc/consul.d. Done
   /etc/consul-template.d. Done
   /etc/consul.d/server. Done
   /etc/consul.d/tls. Done
   /var/consul. Done
   /opt/consul. Done
- Version de CONSUL a instalar (0.9.3):  0.9.3
 - Descargando https://releases.hashicorp.com/consul/0.9.3/consul_0.9.3_linux_amd64.zip. Done. 
 - Instalando consul. Done. 
- Version de CONSUL TEMPLATE a instalar (0.19.3): 0.19.0
 - Descargando 0.19.3. Done. 
 - Instalando consul-template. Done. 
 - Generando certificados para TLS/SSL
   CA Name (consulCA): consulCA
   Device Cert Name (consul): consul
 - Numero de Consul Servers (1): 1
   IP Nodo 1 : 10.152.0.80
 - Puerto para GUI: (8080): 443
 - Puerto para DNS: (8600): 53

- Copie las configuraciones a cada server
  # scp /etc/consul.d/server/10_152_0_80-server.json 10.152.0.80:/etc/consul.d/server/10_152_0_80-server.json

- Starting CONSUL Server
  # /opt/consul/consul agent -ui -config-file=/etc/consul.d/server/10_152_0_80-server.json

 - NOTA: Para borrar la instalacion ejecute: rm -fr /etc/consul.d/ /var/consul/ /opt/consul/
```




### Arranque
```
[root@grafana01 consul.git]# /opt/consul/consul agent -ui -config-file=/etc/consul.d/server/10_152_0_80-server.json

==> WARNING: BootstrapExpect Mode is specified as 1; this is the same as Bootstrap mode.
==> WARNING: Bootstrap mode enabled! Do not enable unless necessary
==> Starting Consul agent...
==> Consul agent running!
           Version: 'v0.9.3'
           Node ID: '40933dda-ea46-281c-5564-79387ed2da2c'
         Node name: 'node-1'
        Datacenter: 'dc1' (Segment: '<all>')
            Server: true (Bootstrap: true)
       Client Addr: 0.0.0.0 (HTTP: 8500, HTTPS: 443, DNS: 53)
      Cluster Addr: 10.152.0.80 (LAN: 8301, WAN: 8302)
           Encrypt: Gossip: true, TLS-Outgoing: true, TLS-Incoming: true

==> Log data will now stream in as it occurs:

    2017/09/29 11:26:22 [INFO] raft: Initial configuration (index=1): [{Suffrage:Voter ID:10.152.0.80:8300 Address:10.152.0.80:8300}]
    2017/09/29 11:26:22 [INFO] raft: Node at 10.152.0.80:8300 [Follower] entering Follower state (Leader: "")
    2017/09/29 11:26:22 [INFO] serf: EventMemberJoin: node-1.dc1 10.152.0.80
    2017/09/29 11:26:22 [INFO] serf: EventMemberJoin: node-1 10.152.0.80
    2017/09/29 11:26:22 [INFO] consul: Adding LAN server node-1 (Addr: tcp/10.152.0.80:8300) (DC: dc1)
    2017/09/29 11:26:22 [INFO] consul: Handled member-join event for server "node-1.xxxxx" in area "wan"
    2017/09/29 11:26:22 [INFO] agent: Started DNS server 0.0.0.0:53 (udp)
    2017/09/29 11:26:22 [INFO] agent: Started DNS server 0.0.0.0:53 (tcp)
    2017/09/29 11:26:22 [INFO] agent: Started HTTP server on [::]:8500
    2017/09/29 11:26:22 [INFO] agent: Started HTTPS server on [::]:443
    2017/09/29 11:26:22 [INFO] agent: Retry join LAN is supported for: aws azure gce softlayer
    2017/09/29 11:26:22 [INFO] agent: Joining LAN cluster...
    2017/09/29 11:26:22 [INFO] agent: (LAN) joining: [10.152.0.80:8301]
    2017/09/29 11:26:22 [INFO] agent: (LAN) joined: 1 Err: <nil>
    2017/09/29 11:26:22 [INFO] agent: Join LAN completed. Synced with 1 initial agents
    2017/09/29 11:26:28 [WARN] raft: Heartbeat timeout from "" reached, starting election
    2017/09/29 11:26:28 [INFO] raft: Node at 10.152.0.80:8300 [Candidate] entering Candidate state in term 2
    2017/09/29 11:26:28 [INFO] raft: Election won. Tally: 1
    2017/09/29 11:26:28 [INFO] raft: Node at 10.152.0.80:8300 [Leader] entering Leader state
    2017/09/29 11:26:28 [INFO] consul: cluster leadership acquired
    2017/09/29 11:26:28 [INFO] consul: New leader elected: node-1
    2017/09/29 11:26:28 [INFO] consul: member 'node-1' joined, marking health alive
```


### Test

```
 [root@grafana01 consul.git]# nslookup
 > server 127.0.0.1
 > 10.152.0.80
 Server:         localhost
 Address:        127.0.0.1#53
 
 80.0.152.10.in-addr.arpa        name = grafana01.node.globalia.consul.
```

### UI

<img src="https://raw.githubusercontent.com/mobarrio/consul/master/img/consul001.jpg" />
