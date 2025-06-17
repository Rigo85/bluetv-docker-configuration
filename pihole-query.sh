#!/usr/bin/env bash

# Nombre: pihole-query.sh
# Uso: pihole-query.sh -d /ruta/a/db -m [blocked|allowed] -l N

# Valores por defecto
DB_PATH="etc-pihole/pihole-FTL.db"
MODE="blocked"
LIMIT=100

# Función de ayuda
usage() {
  cat <<EOF
Uso: $0 [opciones]
  -d, --db      Ruta al fichero SQLite (por defecto: $DB_PATH)
  -m, --mode    Modo de consulta: blocked o allowed (por defecto: $MODE)
  -l, --limit   Límite de resultados (por defecto: $LIMIT)
  -h, --help    Muestra esta ayuda y sale
EOF
  exit 1
}

# Parseo de parámetros
while getopts ":d:m:l:-:h" opt; do
  case $opt in
    d) DB_PATH="$OPTARG" ;;
    m) MODE="$OPTARG" ;;
    l) LIMIT="$OPTARG" ;;
    h) usage ;;
    -)
      case $OPTARG in
        db=*)    DB_PATH="${OPTARG#*=}" ;;
        mode=*)  MODE="${OPTARG#*=}" ;;
        limit=*) LIMIT="${OPTARG#*=}" ;;
        help)    usage ;;
        *)       echo "Opción desconocida: --$OPTARG" >&2; usage ;;
      esac ;;
    \?) echo "Opción inválida: -$OPTARG" >&2; usage ;;
    :)  echo "Falta argumento para -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND -1))

# Determinar códigos de estado según el modo
if [[ "$MODE" == "allowed" ]]; then
  STATUS_CODES="2,3,12,13,14"
elif [[ "$MODE" == "blocked" ]]; then
  STATUS_CODES="1,4,5,6,7,8,9,10,11,15,16,18"
else
  echo "Modo desconocido: $MODE. Usa 'allowed' o 'blocked'." >&2
  exit 2
fi

# Ejecutar consulta SQLite
sqlite3 "$DB_PATH" <<SQL
.headers on
.mode column
SELECT
  domain,
  COUNT(*) AS hits
FROM queries
WHERE status IN ($STATUS_CODES)
GROUP BY domain
ORDER BY hits DESC
LIMIT $LIMIT;
SQL
