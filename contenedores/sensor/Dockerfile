# Sensor de CyberFlow: la misma cadena que corre en Sensor1, en un contenedor.
#   tcpdump (anillo PCAP de 5 s) + Suricata (solo EVE, sin reglas)
#   motor_decision.py (Isolation Forest if_limpio_2026_10, alfa 0,01 + heurísticos)
#   detector_rapido.py (vía rápida de escaneo) + publicador v2 (feed firmado ed25519)
#   dashboard.py (panel en :8788)
FROM python:3.14-slim-trixie

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      tcpdump suricata openssl procps \
 && rm -rf /var/lib/apt/lists/*

# Las versiones EXACTAS del entorno del modelo congelado (requirements-model.txt)
COPY contenedores/sensor/requirements-model.txt /tmp/requirements-model.txt
RUN pip install --no-cache-dir -r /tmp/requirements-model.txt

COPY producto/ /opt/cyberflow/
COPY contenedores/sensor/systemctl /usr/local/bin/systemctl
COPY contenedores/sensor/arranque.sh /usr/local/bin/arranque.sh
COPY contenedores/sensor/resumen.py /opt/cyberflow/herramientas-demo/resumen.py
RUN chmod +x /usr/local/bin/systemctl /usr/local/bin/arranque.sh \
 && find /opt/cyberflow -name '*.sh' -exec chmod +x {} +

WORKDIR /opt/cyberflow
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
CMD ["/usr/local/bin/arranque.sh"]
