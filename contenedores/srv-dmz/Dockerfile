# srv-dmz: el servidor protegido (10.10.30.10). Web en 80/443, endpoint con
# autenticación básica en 8081 (para la fuerza bruta) y DNS en 53.
FROM debian:trixie-slim

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      nginx dnsmasq openssl ca-certificates procps \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/nginx/sites-enabled/default

COPY nginx.conf /etc/nginx/conf.d/cyberflow.conf
COPY dnsmasq.conf /etc/dnsmasq.d/cyberflow.conf
COPY www/ /var/www/cyberflow/
COPY arranque.sh /usr/local/bin/arranque.sh
RUN chmod +x /usr/local/bin/arranque.sh

EXPOSE 53/udp 80 443 8081
CMD ["/usr/local/bin/arranque.sh"]
