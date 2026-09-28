# `web-color` — la imagen visual de la práctica en clase

Una página de una sola pantalla que pinta el fondo con el valor de `APP_COLOR` y muestra `APP_NAME` y `APP_VERSION`. No tiene backend, no tiene base de datos y pesa lo mismo que un nginx: existe para que **una variable de entorno se vea en el navegador**, sin leer un solo log.

Se usa en la práctica en clase de las semanas 2, 3 y 4, y como carga de prueba en las semanas 5 a 8 cuando lo que se está enseñando es Kubernetes y no la aplicación.

## Los dos Dockerfile son el contenido de clase

| Archivo | Cuándo se lee la configuración | Qué demuestra |
|---|---|---|
| [`Dockerfile`](Dockerfile) | al **arrancar** el contenedor | Una imagen, todos los ambientes. El patrón del curso. |
| [`Dockerfile.buildtime`](Dockerfile.buildtime) | durante el **build** | Una imagen **por** ambiente. El anti-patrón. |

```bash
# El patrón: se construye una vez...
docker build -t web-color:v1 .
# ...y el color cambia sin reconstruir nada
docker run -d --name azul  -p 8081:8080 -e APP_COLOR=steelblue     web-color:v1
docker run -d --name verde -p 8082:8080 -e APP_COLOR=seagreen      web-color:v1
docker run -d --name lila  -p 8083:8080 -e APP_COLOR=rebeccapurple web-color:v1

# El anti-patrón: el color entra por --build-arg y la env var ya no hace nada
docker build -f Dockerfile.buildtime --build-arg APP_COLOR=firebrick -t web-color-build:v1 .
docker run -d --name rojo -p 8084:8080 -e APP_COLOR=seagreen web-color-build:v1
# → sigue siendo firebrick. Para cambiarlo hay que volver a buildear.
```

Los tres primeros contenedores son **la misma imagen** con tres colores distintos. El cuarto es la razón por la que el curso descarta `VITE_API_URL` en el frontend de `app-notas`: lo que se hornea en el build obliga a una imagen por ambiente.

## Variables de entorno

| Variable | Default | Efecto |
|---|---|---|
| `APP_COLOR` | `steelblue` | Color de fondo. Cualquier valor CSS válido (`seagreen`, `#ff6600`, `rebeccapurple`). |
| `APP_NAME` | `web-color` | Título grande. Sirve para distinguir réplicas o ambientes. |
| `APP_VERSION` | `v1` | Se muestra en la ficha. Se hornea con `--build-arg APP_VERSION=v2`. |

## Detalles que son contenido de clase

- **Escucha en 8080, no en 80.** La base es `nginxinc/nginx-unprivileged`, que corre como uid 101, y un proceso no-root no puede bindear puertos menores a 1024. Es la misma razón que en `notas-frontend`.
- **El renderizado va en `/docker-entrypoint.d/40-render-index.sh`.** El entrypoint oficial de nginx corre `envsubst` únicamente sobre `/etc/nginx/templates/*.template`, que son archivos de **configuración**; para templatizar la página hace falta este hook, que la imagen oficial ejecuta antes de arrancar nginx.
- **`envsubst` recibe la lista explícita de variables** (`'${APP_NAME} ${APP_VERSION} ${APP_COLOR}'`). Sin esa lista reemplazaría cualquier `${...}` del archivo. Es el mismo cuidado que `NGINX_ENVSUBST_FILTER=^API_` en `notas-frontend`.
- **Se borra el `index.html` que trae la imagen.** Es de `root` con permisos 644: el hook corre como uid 101 y no puede truncarlo. Sin ese `rm -f`, el contenedor muere con `can't create /usr/share/nginx/html/index.html: Permission denied` — un buen error para mostrar.

## Verificación

```bash
docker run --rm --entrypoint id web-color:v1        # uid=101(nginx)
curl -s localhost:8081 | grep 'background:'         # el color efectivo
docker logs azul | grep web-color                   # el hook informa qué renderizó
```
