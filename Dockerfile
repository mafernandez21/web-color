# web-color — configuración en RUNTIME (el patrón que enseña el curso).
# El color se lee de una variable de entorno cuando ARRANCA el contenedor:
# una sola imagen sirve para todos los ambientes.
FROM nginxinc/nginx-unprivileged:1.27-alpine

# ARG existe solo durante el build; ENV persiste en el contenedor y se puede
# sobreescribir con -e al hacer docker run.
ARG APP_VERSION=v1
ENV APP_VERSION=${APP_VERSION} \
    APP_NAME=web-color \
    APP_COLOR=steelblue

# La plantilla NO va al web root: se renderiza al arrancar.
COPY html/index.html.template /usr/share/nginx/template/index.html.template
COPY docker-entrypoint.d/40-render-index.sh /docker-entrypoint.d/40-render-index.sh

USER root
# El index.html que trae la imagen es de root: el hook no puede truncarlo, así que se borra.
RUN chmod +x /docker-entrypoint.d/40-render-index.sh \
 && rm -f /usr/share/nginx/html/index.html \
 && chown nginx:nginx /usr/share/nginx/html
USER nginx

EXPOSE 8080
