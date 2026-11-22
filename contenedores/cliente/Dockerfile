# Cliente legítimo: navega, resuelve nombres y hace ping al srv-dmz a ritmo humano.
FROM debian:trixie-slim
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      curl ca-certificates dnsutils iputils-ping \
 && rm -rf /var/lib/apt/lists/*
COPY trafico-legitimo.sh /usr/local/bin/trafico-legitimo.sh
COPY legitimo-intenso.sh /usr/local/bin/legitimo-intenso
RUN chmod +x /usr/local/bin/trafico-legitimo.sh /usr/local/bin/legitimo-intenso
CMD ["/usr/local/bin/trafico-legitimo.sh"]
