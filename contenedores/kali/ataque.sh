#!/bin/sh
# ataque <escenario>   — los mismos comandos que muestra «Escenario en vivo».
#   l4      escaneo de puertos           (regla port_scan   -> BLOCK)
#   brute   fuerza bruta HTTP 401        (regla brute_force -> BLOCK)
#   l7      abuso HTTP, 900 peticiones   (regla http_abuse  -> LIMIT)
#   l3      inundación ICMP              (sin regla ICMP: solo señal del modelo)
#   dns     DNS de alta entropía (DGA)   (regla dns_entropy -> LIMIT)
#   fp      tráfico legítimo de la Kali  (debe quedar en PERMIT)
SRV=10.10.30.10
case "${1:-}" in
  l4)    echo "[kali] escaneo de puertos contra $SRV"
         nmap -sT -T4 --max-retries 1 -p 1-3000 --open "$SRV" ;;
  brute) echo "[kali] 120 logins fallidos contra $SRV:8081"
         for i in $(seq 1 120); do curl -s -o /dev/null -u x:x "http://$SRV:8081/"; done ;;
  l7)    echo "[kali] 900 peticiones HTTP en paralelo contra $SRV"
         seq 1 900 | xargs -P20 -I{} curl -s -o /dev/null "http://$SRV/" ;;
  l3)    echo "[kali] inundación ICMP contra $SRV (60 s)"
         for k in 1 2 3 4; do ping -q -i 0.002 -s 1200 -w 60 "$SRV" >/dev/null & done; wait ;;
  dns)   # en el laboratorio el resolver es DC1 (10.10.10.20); aquí es el srv-dmz
         echo "[kali] 80 consultas DNS a nombres aleatorios (DGA) contra $SRV"
         for i in $(seq 1 80); do
           r=$(head -c6 /dev/urandom | od -An -tx1 | tr -d ' \n')
           dig +short +time=1 +tries=1 "${r}.francos-sac.com" @"$SRV" >/dev/null 2>&1; sleep 0.5
         done ;;
  fp)    echo "[kali] tráfico legítimo: ping, 2 puertos, 5 páginas"
         ping -c 4 "$SRV" >/dev/null
         nmap -sT -p 80,443 "$SRV" >/dev/null
         for i in 1 2 3 4 5; do curl -s -o /dev/null "http://$SRV/"; sleep 2; done ;;
  *)     echo "uso: ataque l4|brute|l7|l3|dns|fp" >&2; exit 2 ;;
esac
echo "[kali] fin: $1"
