#!/bin/sh
# Genera lo que no se versiona (certificado y contraseña de 8081) y arranca
# DNS y web. Nada de esto es un secreto real: vive solo en el contenedor.
set -eu

if [ ! -f /etc/nginx/cyberflow.crt ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -subj "/CN=srv-dmz.cyberflow.lab" \
    -keyout /etc/nginx/cyberflow.key -out /etc/nginx/cyberflow.crt 2>/dev/null
fi
if [ ! -f /etc/nginx/htpasswd ]; then
  # usuario legítimo de la demo: los clientes entran con él (200); la Kali
  # prueba x:x (401), que es la huella que caza la regla brute_force.
  printf 'operador:%s\n' "$(openssl passwd -apr1 cyberflow-demo)" > /etc/nginx/htpasswd
fi

dnsmasq --keep-in-foreground --conf-dir=/etc/dnsmasq.d &
exec nginx -g 'daemon off;'
