#!/bin/sh
# Renderiza la plantilla HTML en el web root al arrancar el contenedor.
# El entrypoint oficial de nginx corre envsubst solo sobre
# /etc/nginx/templates/*.template (archivos de configuración), así que la página
# necesita este hook extra en /docker-entrypoint.d/.
set -eu

: "${APP_NAME:=web-color}"
: "${APP_VERSION:=v1}"
: "${APP_COLOR:=steelblue}"
export APP_NAME APP_VERSION APP_COLOR

# La lista explícita de variables evita que envsubst toque cualquier otra cosa.
envsubst '${APP_NAME} ${APP_VERSION} ${APP_COLOR}' \
  < /usr/share/nginx/template/index.html.template \
  > /usr/share/nginx/html/index.html

echo "[web-color] index.html renderizado con APP_NAME=$APP_NAME APP_VERSION=$APP_VERSION APP_COLOR=$APP_COLOR"
