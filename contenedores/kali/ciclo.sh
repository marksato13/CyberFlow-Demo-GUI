#!/bin/sh
# Con AUTO=1 la Kali repite sola el recorrido de la demo, dejando entre ataque
# y ataque tiempo de sobra para que la medida caduque y la IP vuelva a PERMIT.
# Con AUTO=0 se queda quieta: lanza tú cada escenario con «ataque <id>».
if [ "${AUTO:-1}" != "1" ]; then
  echo "[kali] modo manual: docker compose exec kali ataque l4|brute|l7|l3|fp"
  exec sleep infinity
fi
sleep 90   # que el motor tenga antes historia de tráfico normal
while :; do
  for esc in l4 brute l7 fp; do
    ataque "$esc"
    sleep 240
  done
done
