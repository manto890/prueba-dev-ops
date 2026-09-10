# DÍA 2

## OBJETIVO DEL DÍA

El objetivo del Día 2 fue profundizar en Docker pasando de conceptos básicos a una aplicación web dockerizada con **Nginx**.

Durante la práctica se trabajó con:

* Creación de imágenes mediante Dockerfile.
* Ejecución y gestión de contenedores.
* Publicación de puertos.
* Uso de volúmenes Docker.
* Copia y modificación de archivos dentro de contenedores.
* Bind mounts.
* Docker Compose.
* Redes creadas automáticamente por Docker Compose.

La práctica sirvió como base para empezar a trabajar posteriormente con aplicaciones formadas por varios servicios.

---

# 1. CREACIÓN DE IMAGEN PERSONALIZADA CON NGINX

Se creó una carpeta `nginx` dentro de `devops-dia2` y se preparó una página `index.html` personalizada.

También se creó un `Dockerfile` basado en:

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

El objetivo fue construir una imagen propia a partir de **Nginx Alpine**, incorporando nuestra página web dentro de la imagen.

La imagen resultante fue:

```text
devops-nginx:v1
```

# 2. EJECUCIÓN DEL CONTENEDOR Y PUBLICACIÓN DE PUERTOS

A partir de la imagen creada se ejecutó el contenedor:

```text
devops-nginx
```

El puerto utilizado fue:

```text
8080:80
```

De esta forma, Nginx escuchaba en el puerto `80` dentro del contenedor, pero podía accederse desde el ordenador mediante el puerto `8080`.

Se comprobó desde el navegador que la página personalizada funcionaba correctamente.

Resultado:

```text
Mi primer servicio Dockerizado

Docker + Nginx funcionando correctamente.
```

Esta parte permitió entender de forma práctica cómo un servicio que se ejecuta dentro de un contenedor puede exponerse hacia el exterior.

---

# 3. TRABAJO CON CONTENEDORES Y ARCHIVOS

Se practicó también la interacción directa con los contenedores mediante herramientas como `docker exec` y `docker cp`.

Esto permitió:

* Ejecutar comandos dentro de un contenedor.
* Comprobar el contenido existente dentro del contenedor.
* Copiar archivos entre el sistema anfitrión y el contenedor.

Esta fase ayudó a entender que un contenedor no es simplemente una aplicación aislada, sino un entorno Linux donde podemos inspeccionar y gestionar los procesos y archivos que utiliza el servicio.

---

# 4. VOLÚMENES DOCKER

Posteriormente se introdujo el concepto de **volumen Docker**.

Se creó el volumen:

```text
nginx-data
```

y se utilizó con otro contenedor:

```text
nginx-volume
```

En este caso se utilizó el puerto:

```text
8081:80
```

También se utilizó `docker cp` para introducir nuestro contenido en el contenedor.


# 5. Introducción a Docker Compose

Una vez practicado Docker de forma individual, se pasó a **Docker Compose**.

Se creó:

```text
devops-dia2/docker-compose.yml
```

con un servicio Nginx basado en:

```text
nginx:alpine
```

El contenedor definido en Compose fue:

```text
nginx-compose
```

y se publicó:

```text
8082:80
```

La diferencia principal respecto a la primera parte de la práctica es que ahora la configuración del servicio quedaba definida en un archivo YAML en lugar de tener que especificar manualmente todos los parámetros mediante comandos independientes.

---

# 6. USO DE BIND MOUNT CON DOCKER COMPOSE

En Compose se utilizó:

```text
./nginx:/usr/share/nginx/html
```

Esto permitió montar directamente la carpeta `nginx` del proyecto dentro del directorio que utiliza Nginx para servir las páginas web.

Por tanto, la relación quedó:

```text
Proyecto local
./nginx
     │
     │ Bind Mount
     ▼
Contenedor
/usr/share/nginx/html
     │
     ▼
Nginx
```

Esto permitió modificar el contenido desde el proyecto local y comprobar los cambios en el servicio Nginx.

Se verificó finalmente desde el navegador que Docker Compose estaba sirviendo correctamente la página personalizada.

---

# 7. CONFIGURACIÓN Y RED CON DOCKER COMPOSE
Antes de ejecutar el servicio se comprobó la configuración mediante:

```text
docker compose config
```

Durante esta fase se observó también la creación automática de una red propia de Compose:

```text
devops-dia2_default
```

Esto permitió introducir un concepto importante para los siguientes días: **los contenedores de una aplicación pueden comunicarse entre ellos mediante redes Docker**.

Aunque en este día solamente se utilizó un servicio, la red creada automáticamente será especialmente importante cuando se trabaje con arquitecturas de varios contenedores.

---

# 8. RESULTADO FINAL

Al terminar el Día 2 se había pasado de una ejecución sencilla de Nginx a trabajar con diferentes mecanismos de Docker:

```text
Dockerfile
    ↓
Imagen personalizada
    ↓
Contenedor
    ↓
Publicación de puertos
    ↓
Volumen
    ↓
Bind Mount
    ↓
Docker Compose
```

Se consiguió ejecutar Nginx de diferentes formas y comprobar su funcionamiento desde el navegador.

La parte más importante del día fue entender la relación entre:

**imagen → contenedor → almacenamiento → red → servicio**

y comenzar a utilizar **Docker Compose** como herramienta para definir aplicaciones de forma reproducible.

---

# CONOCIMIENTOS ADQUIRIDOS

Al finalizar el Día 2, se practicaron los siguientes conceptos:

* **Dockerfile:** definición de una imagen personalizada.
* **Imagen:** plantilla utilizada para crear contenedores.
* **Contenedor:** instancia ejecutable de una imagen.
* **Port mapping:** comunicación entre puertos del host y del contenedor.
* **Volúmenes:** almacenamiento gestionado por Docker.
* **Bind mounts:** conexión entre una carpeta local y una ruta del contenedor.
* **Docker Compose:** definición y gestión de servicios mediante YAML.
* **Redes Docker:** comunicación entre contenedores y servicios.
* **Nginx:** utilización de un servidor web dentro de un contenedor.

Este día estableció la base necesaria para pasar posteriormente a aplicaciones con **varios contenedores y comunicación entre servicios**.
