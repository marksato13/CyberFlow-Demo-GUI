# Atacante (10.10.20.30): las mismas herramientas y comandos de los escenarios
# del panel, pero apuntando solo al srv-dmz de esta red aislada.
FROM debian:trixie-slim
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      nmap curl ca-certificates dnsutils iputils-ping findutils procps \
 && rm -rf /var/lib/apt/lists/*
COPY ataque.sh /usr/local/bin/ataque
COPY ciclo.sh /usr/local/bin/ciclo
RUN chmod +x /usr/local/bin/ataque /usr/local/bin/ciclo
CMD ["/usr/local/bin/ciclo"]
