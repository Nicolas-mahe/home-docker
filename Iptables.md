# IPtables set
## Todo
To save V4 in file:
` iptables-save > /etc/iptables/rules.v4 `
To save V6 in file:
` ip6tables-save > /etc/iptables/rules.v6 `

To add rules on start, add theses ligne in /etc/rc.local : 
` iptables-restore < /etc/iptables/rules.v4 `
` ip6tables-restore < /etc/iptables/rules.v6 `

## Add Rules
`#!/bin/bash 
# Règle 1 : On conserve les connexions établies en sortie
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Règle 2 : On conserve les connexions établies en entrée
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Règle 3 : On donne tous les accès aux PCs utilisés par la configuration d'OMV (IP de mes postes : 192.168.1.8 et 192.168.1.9)
iptables -A INPUT -s 192.168.1.8/32 -j ACCEPT
iptables -A INPUT -s 192.168.1.9/32 -j ACCEPT
iptables -A INPUT -s 10.192.1.10/32 -j ACCEPT
iptables -A INPUT -s 10.192.1.20/32 -j ACCEPT
iptables -A OUTPUT -d 192.168.1.8/32 -j ACCEPT
iptables -A OUTPUT -d 192.168.1.9/32 -j ACCEPT
iptables -A OUTPUT -d 10.192.1.10/32 -j ACCEPT
iptables -A OUTPUT -d 10.192.1.20/32 -j ACCEPT
# Règle 4 : On autorise le loopback en entrée
iptables -A INPUT -i lo -j ACCEPT
# Règle 5 : On autorise le loopback en sortie
iptables -A OUTPUT -o lo -j ACCEPT
# Règle 6 : On autorise le PING (protocole ICMP) à partir de toute machine du réseau local (mon réseau local 192.168.1.0/24)
iptables -A INPUT -p icmp -s 192.168.1.0/24 -j ACCEPT
iptables -A OUTPUT -p icmp -d 192.168.1.0/24 -j ACCEPT
# Règle 7 : On autorise l'accès en SSH via le port 14864 à partir du réseau local (192.168.1.0/24)
iptables -A INPUT -p tcp --dport 14864 -s 192.168.1.0/24 -j ACCEPT
# Règle 8 : On autorise l'admistration d'OMV à partir du réseau local (192. 168.1.0/24) sur les ports 14823 & 13823
iptables -A INPUT -p tcp --dport 13823 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 14823 -s 192.168.1.0/24 -j ACCEPT
# Règle 9 et 10 : On autorise les requêtes DNS (port 53 en TCP et UDP)
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
# Règle 11 et 12 : On autorise les requêtes HTTP et HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
# Règle 13 : On autorise la connexion au serveur de temps (NTP)
iptables -A INPUT -p udp --dport 123 -j ACCEPT
# Règle 14 : On autorise le trafic sur le port 3322 depuis le réseau local
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 3322 -j ACCEPT
iptables -A OUTPUT -p tcp -d 192.168.1.0/24 --sport 3322 -m state --state ESTABLISHED,RELATED -j ACCEPT
# Règle 15 : On autorise le trafic sur le port 27878 depuis le réseau local
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 27878 -j ACCEPT
iptables -A OUTPUT -p tcp -d 192.168.1.0/24 --sport 27878 -m state --state ESTABLISHED,RELATED -j ACCEPT
# Règle 16 : On autorise le SMB depuis le réseau local
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 445 -j ACCEPT
iptables -A INPUT -p udp -s 192.168.1.0/24 --dport 445 -j ACCEPT
iptables -A OUTPUT -p tcp -d 192.168.1.0/24 --sport 445 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p udp -d 192.168.1.0/24 --sport 445 -m state --state ESTABLISHED,RELATED -j ACCEPT
# Règle 17 : On interdit tout le reste (ce qui n'est pas autorisé)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
# Règle 19 : Bloquer tout le trafic IPv6
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP
# Afficher les règles
iptables -L -v
exit 0  `