# Proyecto PC4 - Grupo 13

# Proyecto 13 — Container Runtime Hardening Lab (Sprint 1)

Sprint 1 implementado al 100%:
- App con Flask que ejecuta operaciones sensibles.
- Dockerfile multi-stage con usuario no-root.
- Scripts para correr la app en modo OPEN y HARDENED.
- Script para recolectar resultados.
- Makefile para automatizar todo.

## Comandos rápidos
```bash
make build
make run-open
make run-hardened
make collect

curl http://localhost:8000/health
curl http://localhost:8000/check
