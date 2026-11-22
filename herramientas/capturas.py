"""Recorre las vistas del panel y guarda una captura de cada una.

Corre en un contenedor de Playwright conectado a la red del laboratorio:

    docker run --rm --network cyberflow-demo_lab --ip 10.10.0.10 -v "$PWD:/w" -w /w \
      mcr.microsoft.com/playwright/python:v1.55.0-noble \
      sh -c "pip install -q playwright==1.55.0 && python herramientas/capturas.py"

Sirve para comprobar de un vistazo que todas las vistas pintan datos.
"""
from __future__ import annotations

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

PANEL = "http://10.10.30.10:8788/"
SALIDA = Path("docs/capturas")
VISTAS = [  # (seccion, modo, segundos de espera, nombre)
    ("s-salud", "operativo", 12, "01-resumen"),
    ("s-escenario", "operativo", 8, "02-escenario-en-vivo"),
    ("s-alertas", "operativo", 8, "03-alertas"),
    ("s-bloqueos", "operativo", 8, "04-respuestas"),
    ("s-topologia", "operativo", 8, "05-mapa-del-sistema"),
    ("s-vivo", "desarrollo", 20, "06-datos-en-vivo"),
    ("s-decisiones", "desarrollo", 8, "07-decisiones"),
    ("s-actividad", "desarrollo", 8, "08-actividad"),
    ("s-variables", "desarrollo", 8, "09-variables"),
    ("s-modelo", "desarrollo", 8, "10-modelo"),
    ("s-scores", "desarrollo", 8, "11-scores"),
]


def main() -> int:
    SALIDA.mkdir(parents=True, exist_ok=True)
    errores: list[str] = []
    with sync_playwright() as p:
        nav = p.chromium.launch()
        for seccion, modo, espera, nombre in VISTAS:
            ctx = nav.new_context(viewport={"width": 1500, "height": 950})
            ctx.add_init_script(
                "try{localStorage.setItem('cyberflow_modo','%s');"
                "localStorage.setItem('cf_tour_visto','1');}catch(e){}" % modo)
            pag = ctx.new_page()
            pag.on("pageerror", lambda e, n=nombre: errores.append(f"{n}: {e}"))
            pag.goto(PANEL + "#" + seccion, wait_until="networkidle")
            if seccion == "s-vivo":
                for texto in ("Abrir captura", "Iniciar", "Empezar"):
                    boton = pag.get_by_role("button", name=texto)
                    if boton.count():
                        boton.first.click()
                        break
            pag.wait_for_timeout(espera * 1000)
            pag.screenshot(path=str(SALIDA / f"{nombre}.png"), full_page=False)
            print("captura", nombre)
            ctx.close()
        nav.close()
    for e in errores:
        print("ERROR JS", e, file=sys.stderr)
    return 1 if errores else 0


if __name__ == "__main__":
    raise SystemExit(main())
