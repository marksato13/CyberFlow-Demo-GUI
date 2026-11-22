"""Resumen legible de las últimas decisiones del motor (lee motor_decision.log por stdin)."""
import json
import sys

print(f"{'ventana (UTC)':<10} {'IP':<13} {'decisión':<8} {'IF':<6} {'score':>7}  regla")
for linea in sys.stdin:
    try:
        d = json.loads(linea)
    except ValueError:
        continue
    if d.get("event") != "decision":
        continue
    reglas = ", ".join(f"{h['heuristico']}→{h['accion']}" for h in d.get("heuristicos") or [])
    if d.get("decision") == "PERMIT" and not reglas and d.get("entity_ip") != "10.10.20.30":
        continue   # el tráfico normal de los clientes no se lista, solo lo relevante
    score = d.get("score")
    print(f"{(d.get('window_end_utc') or '')[11:19]:<10} {d.get('entity_ip', ''):<13} "
          f"{d.get('decision', ''):<8} {str(d.get('decision_if') or '-'):<6} "
          f"{score if score is None else round(score, 3)!s:>7}  {reglas}")
