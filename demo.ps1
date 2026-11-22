<#
  CyberFlow · demo en Docker (Windows / PowerShell)

    .\demo.ps1 iniciar            construye y levanta el laboratorio, abre el panel
    .\demo.ps1 iniciar -Manual    igual, pero la Kali NO ataca sola
    .\demo.ps1 ataque l4          lanza un escenario: l4 | brute | l7 | l3 | dns | fp | intenso
    .\demo.ps1 estado             contenedores y últimas decisiones del motor
    .\demo.ps1 registros          registros del sensor (Ctrl+C para salir)
    .\demo.ps1 capturas           guarda una captura de cada vista en docs\capturas
    .\demo.ps1 parar              apaga y borra los contenedores (no deja nada)
#>
param(
  [Parameter(Position = 0)][string]$Orden = "ayuda",
  [Parameter(Position = 1)][string]$Escenario = "",
  [switch]$Manual
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$Panel = "http://127.0.0.1:8788"

function Test-Docker {
  docker version --format '{{.Server.Version}}' *> $null
  if ($LASTEXITCODE -ne 0) { throw "Docker no responde: abre Docker Desktop y vuelve a intentarlo." }
}

switch ($Orden) {
  "iniciar" {
    Test-Docker
    $env:AUTO = if ($Manual) { "0" } else { "1" }
    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) { throw "docker compose up falló" }
    Write-Host "`nEsperando al panel..." -NoNewline
    for ($i = 0; $i -lt 60; $i++) {
      try { Invoke-WebRequest $Panel -UseBasicParsing -TimeoutSec 3 | Out-Null; break } catch { Start-Sleep 2; Write-Host "." -NoNewline }
    }
    Write-Host "`nPanel: $Panel"
    Write-Host "El motor necesita ~1-2 min de tráfico antes de evaluar ventanas completas."
    if (-not $Manual) { Write-Host "La Kali empieza su ciclo de ataques a los 90 s (escaneo, fuerza bruta, flood, legítimo)." }
    Start-Process $Panel
  }
  "ataque" {
    if ($Escenario -notin @("l4", "brute", "l7", "l3", "dns", "fp", "intenso")) { throw "uso: .\demo.ps1 ataque l4|brute|l7|l3|dns|fp|intenso" }
    if ($Escenario -eq "intenso") { docker compose exec cliente1 legitimo-intenso } else { docker compose exec kali ataque $Escenario }
  }
  "estado" {
    docker compose ps
    docker compose exec -T sensor sh -c "tail -n 400 /opt/cyberflow/logs/motor_decision.log | python /opt/cyberflow/herramientas-demo/resumen.py"
  }
  "registros" { docker compose exec sensor sh -c "tail -F /var/log/cyberflow/*.log" }
  "capturas" {
    Test-Docker
    docker run --rm --network cyberflow-demo_lab --ip 10.10.0.10 -v "${PWD}:/w" -w /w `
      mcr.microsoft.com/playwright/python:v1.55.0-noble `
      sh -c "pip install -q playwright==1.55.0 && python herramientas/capturas.py"
  }
  "parar" { docker compose down --remove-orphans }
  default { (Get-Content $PSCommandPath -TotalCount 11 | Select-Object -Skip 1) -join "`n" | Write-Host }
}
