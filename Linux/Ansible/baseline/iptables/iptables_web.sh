#!/bin/bash
#shamelessly stolen from Shane's securing linux guide

set -e

ipt="iptables"

$ipt -F; $ipt -X

#Edit this line depending on the services running
$ipt -A INPUT -p tcp -m multiport --dport 22,445,80 -j ACCEPT

$ipt -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$ipt -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

#Allow outbound to 80/443 for yum/apt installations and updates but if your box is secured don't be afraid to remove this to prevent C2 Traffic
$ipt -A OUTPUT -p tcp -m multiport --dport 80,443 -j ACCEPT
$ipt -A INPUT -p udp --dport 53 -j ACCEPT
$ipt -A OUTPUT -p udp --dport 53 -j ACCEPT

$ipt -P FORWARD DROP; $ipt -P OUTPUT DROP; $ipt -P INPUT DROP
