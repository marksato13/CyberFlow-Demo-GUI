#!/bin/sh
# Escenario «Cliente legítimo intenso»: 60 páginas, una cada 2 s. Debe quedar en
# PERMIT de principio a fin (ninguna regla lo sostiene).
echo "[$(hostname)] 60 páginas, una cada 2 s, contra 10.10.30.10"
for i in $(seq 1 60); do curl -s -o /dev/null http://10.10.30.10/; sleep 2; done
echo "[$(hostname)] fin: legítimo intenso"
