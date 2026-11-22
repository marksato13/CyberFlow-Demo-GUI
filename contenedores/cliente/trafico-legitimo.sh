#!/bin/sh
# Tráfico normal de un usuario: unas pocas acciones por minuto, con pausas
# aleatorias. Mezcla las tres capas que mira el motor:
#   L3  ping           L4  conexiones TCP cortas        L7  HTTP, HTTPS, DNS
SRV=10.10.30.10
NOMBRES="www.cyberflow.lab intranet.cyberflow.lab correo.cyberflow.lab archivos.cyberflow.lab"
PAGINAS="/ /noticias.html /docs.html"

azar() { awk -v m="$1" 'BEGIN{srand(); print int(rand()*m)}'; }
elige() { set -- $1; n=$#; i=$(( $(azar "$n") + 1 )); eval echo "\${$i}"; }

sleep "$(azar 10)"
while :; do
  case "$(azar 10)" in
    0|1|2) curl -s -o /dev/null -m 5 "http://$SRV$(elige "$PAGINAS")" ;;
    3|4)   curl -sk -o /dev/null -m 5 "https://$SRV$(elige "$PAGINAS")" ;;
    5|6)   dig +short +time=2 +tries=1 @"$SRV" "$(elige "$NOMBRES")" >/dev/null ;;
    7)     curl -s -o /dev/null -m 5 -u operador:cyberflow-demo "http://$SRV:8081/" ;;
    8)     ping -c 2 -W 2 "$SRV" >/dev/null ;;
    9)     dig +short +time=2 +tries=1 @"$SRV" "$(elige "$NOMBRES")" >/dev/null
           curl -s -o /dev/null -m 5 "http://$SRV/" ;;
  esac
  sleep $(( 4 + $(azar 12) ))
done
