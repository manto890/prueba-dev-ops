# DIA 4: CONSTRUCCIÓN DE PIPELINE DE CI/CD

## 1. OBJETIVO DEL DIA
El objetivo es construir un pipeline de CI con GitHub Actions que, cuando se realice un push a la rama main, descargue automáticamente el repositorio en una máquina de GitHub Actions, configure Python e instale las dependencias necesarias.

A continuación, se ejecutan dos tests para comprobar que la aplicación funciona correctamente. Si los tests son exitosos, se construye una imagen Docker de la aplicación y se publica en GHCR (GitHub Container Registry).

Finalmente, se comprueba que la imagen publicada en GHCR puede descargarse mediante docker pull, ejecutarse como un contenedor Docker y que la aplicación responde correctamente mediante curl.

## 2. ARQUITECTURA DEL PIPELINE

Primero, el usuario realiza un `git push` hacia el repositorio de GitHub. Al detectar este `push` en la rama `main`, GitHub Actions crea un **GitHub-hosted runner**, que es una máquina virtual temporal proporcionada por GitHub.

Dentro de esta máquina temporal, el workflow utiliza `actions/checkout` para descargar el repositorio. Después, se configura Python 3.12 y se instalan las dependencias necesarias para ejecutar la aplicación y los tests. Las dependencias de la aplicación se instalan mediante el archivo `requirements.txt`, que contiene entre otras `Flask` y `psycopg`. Además, se instala `pytest`, que se utilizará para ejecutar las pruebas.

A continuación, se ejecutan los tests definidos en `test_app.py` para comprobar que la aplicación funciona correctamente. En este proyecto se realizan dos pruebas: una para comprobar la ruta principal `/` y otra para comprobar la ruta `/health`. Si los tests fallan, el workflow se detiene y no se continúa con la construcción y publicación de la imagen Docker.

Si los tests son exitosos, GitHub Actions inicia sesión en **GHCR (GitHub Container Registry)** utilizando el usuario de GitHub y el `GITHUB_TOKEN` proporcionado automáticamente por GitHub. Para poder publicar la imagen se utiliza el permiso `packages: write`.

Después se construye la imagen Docker utilizando el `Dockerfile` de la aplicación. La imagen se etiqueta como:

`ghcr.io/manto890/devops-backend:latest`

Posteriormente, mediante `docker push`, la imagen Docker se sube a **GitHub Container Registry**, donde queda almacenada y disponible para ser descargada.

En este ejercicio, posteriormente descargamos manualmente la imagen desde GHCR mediante:

`docker pull ghcr.io/manto890/devops-backend:latest`

Una vez descargada, ejecutamos la imagen mediante `docker run`. El contenedor recibe el nombre `backend-ghcr`, se ejecuta en segundo plano mediante `-d` y se realiza un mapeo de puertos `5001:5000`, de forma que el puerto 5001 del equipo permite acceder al puerto 5000 de la aplicación dentro del contenedor.

Finalmente, utilizamos `curl` para realizar una petición HTTP a la aplicación:

`curl http://localhost:5001`

Si todo funciona correctamente, obtenemos como respuesta:

`Hola desde el Backend!`

De esta forma comprobamos todo el flujo: desde el `git push`, pasando por los tests y la construcción y publicación de la imagen, hasta la descarga y ejecución del contenedor.

## 3. ESTRUCTURA DE ARCHIVOS

Este proyecto se compone de varios archivos que permiten administrar, crear la app y automatizar su despliegue a los que se descargan el repositorio en GitHub.

prueba__dev_ops/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
└── devops-dia3/
    └── backend/
        ├── app.py
        ├── Dockerfile
        ├── requirements.txt
        ├── test_app.py
        └── .gitignore

### `.github/workflows/ci.yml`

Es el archivo principal del pipeline de GitHub Actions. Define todos los pasos que debe realizar automáticamente el **GitHub-hosted runner** cuando se hace un `push` a la rama `main`.

Entre otras cosas, se encarga de:

* Descargar el repositorio mediante `actions/checkout`.
* Configurar Python.
* Instalar las dependencias.
* Ejecutar los tests con `pytest`.
* Iniciar sesión en GHCR.
* Construir la imagen Docker.
* Publicar la imagen en GHCR.

### `app.py`

Es el código de la aplicación Flask que se ejecuta dentro del contenedor Docker.

Contiene las diferentes rutas de la aplicación:

* `/` → devuelve `Hola desde el Backend!`
* `/health` → devuelve `OK`
* `/users` → consulta los usuarios almacenados en PostgreSQL.

### `Dockerfile`

Contiene las instrucciones necesarias para construir la imagen Docker de la aplicación.

Entre otras cosas:

* Utiliza Python 3.12 sobre Alpine Linux.
* Define `/app` como directorio de trabajo.
* Copia `requirements.txt`.
* Instala las dependencias.
* Copia `app.py`.
* Expone el puerto 5000.
* Define `python app.py` como comando de inicio.

### `requirements.txt`

Contiene las dependencias Python necesarias para ejecutar la aplicación.

En este proyecto:

```text
Flask
psycopg[binary]
```

### `test_app.py`

Contiene los tests automáticos de la aplicación.

En este proyecto se realizan dos pruebas:

* `test_home()` → comprueba que la ruta `/` devuelve código HTTP `200` y el mensaje esperado.
* `test_health()` → comprueba que la ruta `/health` devuelve código HTTP `200` y `OK`.

Estos tests se ejecutan mediante `pytest`.

### `.gitignore`

Indica qué archivos o carpetas no deben ser incluidos en Git.

En este proyecto se utiliza para ignorar:

```text
.venv/
__pycache__/
```

La carpeta `.venv` contiene el entorno virtual de Python utilizado durante el desarrollo local y no es necesario subirla al repositorio.

### RELACIÓN ENTRE LOS ARCHIVOS

El funcionamiento puede resumirse así:

```text
app.py
  ↓
Dockerfile
  ↓
Imagen Docker
  ↓
GHCR

test_app.py
  ↓
pytest
  ↓
GitHub Actions

requirements.txt
  ↓
Instala dependencias
  ↓
Aplicación + tests
```

El archivo que coordina todo el proceso automático es:

```text
.github/workflows/ci.yml
```

# 4. TESTS CON PYTEST

Antes de construir y publicar la imagen Docker, el proyecto ejecuta una serie de pruebas automáticas utilizando **pytest**.

Las pruebas se encuentran en el archivo:

`devops-dia3/backend/test_app.py`

Se crearon dos pruebas principales:

* **test_home:** comprueba que la ruta `/` del backend responde correctamente con código HTTP `200` y devuelve el mensaje esperado.
* **test_health:** comprueba que la ruta `/health` responde correctamente con código HTTP `200` y devuelve `OK`.

Para ejecutar las pruebas manualmente se utilizó:

```bash
pytest -v
```

El resultado obtenido fue:

```text
collected 2 items

test_app.py::test_home PASSED
test_app.py::test_health PASSED

2 passed
```

Esto confirma que las dos pruebas del backend funcionan correctamente.

### INTEGRACIÓN EN GITHUB ACTIONS

Estas pruebas también se ejecutan automáticamente dentro del pipeline de **GitHub Actions** mediante el siguiente paso:

```yaml
- name: Run tests
  working-directory: devops-dia3/backend
  run: pytest -v
```

De esta forma, cada vez que se realiza un `git push` a la rama `main`, GitHub Actions ejecuta primero las pruebas.

Si alguna prueba falla, el workflow se detiene y no continúa con las siguientes etapas del pipeline.

Esto permite comprobar automáticamente que el código funciona correctamente antes de construir y publicar la imagen Docker en GHCR.

## 5. GITHUB ACTIONS

**GitHub Actions** es la herramienta de automatización de GitHub que permite ejecutar procesos automáticamente cuando ocurre un determinado evento en el repositorio.

En este proyecto se utiliza para crear un pequeño pipeline de **Integración Continua (CI)**. Cada vez que se realiza un `git push` sobre la rama `main`, GitHub Actions ejecuta automáticamente las diferentes etapas definidas en el archivo:

`.github/workflows/ci.yml`

### FLUJO DEL PIPELINE

El proceso realizado es:

```text
Git push
   ↓
GitHub Actions
   ↓
Checkout del repositorio
   ↓
Configuración de Python
   ↓
Instalación de dependencias
   ↓
Tests con pytest
   ↓
Login en GHCR
   ↓
Construcción de imagen Docker
   ↓
Publicación de imagen en GHCR
```

### GITHUB-HOSTED RUNNER

Para ejecutar el workflow, GitHub proporciona una máquina virtual temporal llamada **runner**.

En este proyecto se utiliza:

```yaml
runs-on: ubuntu-latest
```

Esto indica que el workflow se ejecutará en un entorno Ubuntu proporcionado por GitHub.

El runner descarga el código del repositorio y ejecuta todos los comandos definidos en el workflow.

### CHECKOUT DEL REPOSITORIO

El primer paso utiliza:

```yaml
- name: Checkout repository
  uses: actions/checkout@v4
```

Esta acción descarga el contenido del repositorio dentro del runner para que GitHub Actions pueda trabajar con los archivos del proyecto.

### CONFIGURACIÓN DE PYTHON

A continuación se configura Python 3.12:

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: "3.12"
```

Esto garantiza que los tests se ejecuten utilizando la versión de Python especificada.

### EJECUCIÓN DE TESTS

Después se instalan las dependencias y se ejecutan los tests:

```yaml
- name: Run tests
  working-directory: devops-dia3/backend
  run: pytest -v
```

Si los tests son correctos, el pipeline continúa con las siguientes etapas.

### LOGIN EN GHCR

Después de superar los tests, GitHub Actions se autentica en **GitHub Container Registry (GHCR)**:

```yaml
- name: Log in to GHCR
  uses: docker/login-action@v3
```

Para realizar esta autenticación se utiliza el `GITHUB_TOKEN` proporcionado automáticamente por GitHub.

Además, el workflow tiene los permisos necesarios:

```yaml
permissions:
  contents: read
  packages: write
```

`contents: read` permite leer el contenido del repositorio y `packages: write` permite publicar la imagen Docker en GHCR.

### CONSTRUCCIÓN DE LA IMAGEN DOCKER

Una vez autenticado, se construye la imagen:

```yaml
- name: Build Docker image
  run: docker build -t ghcr.io/${{ github.repository_owner }}/devops-backend:latest ./devops-dia3/backend
```

La imagen se construye utilizando el `Dockerfile` del backend y recibe el nombre:

`ghcr.io/manto890/devops-backend:latest`

### PUBLICACIÓN DE LA IMAGEN

Finalmente, la imagen se publica en GHCR:

```yaml
- name: Push Docker image
  run: docker push ghcr.io/${{ github.repository_owner }}/devops-backend:latest
```

De esta manera, la imagen queda almacenada en GitHub Container Registry y puede ser descargada posteriormente mediante:

```bash
docker pull ghcr.io/manto890/devops-backend:latest
```

### Resultado

El pipeline permite automatizar todo el proceso desde que se sube código a GitHub hasta que se genera y publica una imagen Docker.

Por tanto, el proyecto consigue un flujo básico de **CI**:

```text
Código
  ↓
GitHub
  ↓
GitHub Actions
  ↓
Tests
  ↓
Docker Build
  ↓
GHCR
```

Esto evita tener que realizar manualmente las pruebas, la construcción de la imagen y su publicación cada vez que se actualiza el proyecto.

## 6. BUILD DE DOCKER

Después de ejecutar correctamente los tests con `pytest`, el pipeline utiliza Docker para construir una imagen del backend.

La construcción se realiza mediante el siguiente paso de GitHub Actions:

```yaml
- name: Build Docker image
  run: docker build -t ghcr.io/${{ github.repository_owner }}/devops-backend:latest ./devops-dia3/backend
```

### ¿QUÉ HACE ESTE COMANDO?

El comando `docker build` crea una **imagen Docker** a partir del `Dockerfile` situado en:

```text
devops-dia3/backend/Dockerfile
```

La imagen contiene todo lo necesario para ejecutar el backend, incluyendo:

* Python 3.12
* Las dependencias del proyecto
* El archivo `app.py`
* La configuración necesaria para ejecutar Flask

### NOMBRE DE LA IMAGEN

La imagen recibe el siguiente nombre:

```text
ghcr.io/manto890/devops-backend:latest
```

Este nombre está formado por varias partes:

```text
ghcr.io / manto890 / devops-backend : latest
   │          │            │             │
   │          │            │             └── Tag
   │          │            └──────────────── Nombre de la imagen
   │          └───────────────────────────── Usuario/organización
   └──────────────────────────────────────── GitHub Container Registry
```

* **`ghcr.io`** → GitHub Container Registry, donde posteriormente se almacenará la imagen.
* **`manto890`** → propietario del paquete en GitHub.
* **`devops-backend`** → nombre de la imagen Docker.
* **`latest`** → etiqueta o `tag` utilizada para identificar esta versión de la imagen.

### IMPORTANTE: BUILD ≠ PUSH

En esta etapa todavía **no se está subiendo la imagen a GHCR**.

Primero:

```text
docker build
     ↓
Construye la imagen
```

Después, en el siguiente paso del pipeline:

```text
docker push
     ↓
Sube la imagen a GHCR
```

Por tanto, el proceso completo es:

```text
Dockerfile
    ↓
docker build
    ↓
Imagen Docker
    ↓
docker push
    ↓
GHCR
```

### ¿Y los puertos?

El `docker build` **no publica ningún puerto**.

El `Dockerfile` contiene:

```dockerfile
EXPOSE 5000
```

Esto indica que la aplicación dentro del contenedor utiliza el **puerto 5000**, pero `EXPOSE` por sí solo no publica ese puerto en el ordenador.

Cuando posteriormente ejecutamos la imagen manualmente utilizamos:

```bash
docker run -d --name backend-ghcr -p 5001:5000 ghcr.io/manto890/devops-backend:latest
```

Aquí sí aparece una configuración de puertos:

```text
5001:5000
  │    │
  │    └── Puerto dentro del contenedor
  └─────── Puerto del host
```

Esto significa:

```text
Tu ordenador:5001
       ↓
Contenedor:5000
       ↓
Flask
```

Por eso pudimos comprobar el backend mediante:

```bash
curl http://localhost:5001
```

y obtuvimos:

```text
Hola desde el Backend!
```

### Resultado

El resultado del `docker build` es una imagen Docker preparada para ser publicada en GHCR.

En este proyecto:

```text
Código del backend
       ↓
Dockerfile
       ↓
docker build
       ↓
ghcr.io/manto890/devops-backend:latest
       ↓
docker push
       ↓
GitHub Container Registry
```

De esta forma, GitHub Actions automatiza la creación de una imagen Docker a partir del código del proyecto.

## 7. PUBLICACIÓN EN GHCR

Una vez construida correctamente la imagen Docker, el siguiente paso del pipeline consiste en publicarla en **GitHub Container Registry (GHCR)**.

GHCR es el registro de contenedores de GitHub. Permite almacenar imágenes Docker para poder descargarlas y utilizarlas posteriormente desde otras máquinas o servidores.

### AUTENTIFICACIÓN EN GHCR

Antes de publicar la imagen, GitHub Actions realiza un inicio de sesión en GHCR mediante:

```yaml
- name: Log in to GHCR
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

En este caso:

* **`registry: ghcr.io`** → indica que el registro utilizado es GitHub Container Registry.
* **`github.actor`** → identifica al usuario que ha iniciado la ejecución del workflow.
* **`GITHUB_TOKEN`** → token proporcionado automáticamente por GitHub Actions para realizar operaciones autorizadas sobre el repositorio y sus paquetes.

Además, el workflow tiene configurado:

```yaml
permissions:
  contents: read
  packages: write
```

El permiso `packages: write` permite que GitHub Actions pueda publicar la imagen en GHCR.

### PUBLICACIÓN DE LA IMAGEN

Después de realizar el login, se utiliza:

```yaml
- name: Push Docker image
  run: docker push ghcr.io/${{ github.repository_owner }}/devops-backend:latest
```

Este comando **sube la imagen Docker que se construyó en el paso anterior a GHCR**.

La imagen publicada tiene el nombre:

```text
ghcr.io/manto890/devops-backend:latest
```

El proceso completo es:

```text
Dockerfile
     ↓
docker build
     ↓
Imagen Docker
     ↓
Login en GHCR
     ↓
docker push
     ↓
GitHub Container Registry
```

### COMPROBACIÓN DE LA IMAGEN

Una vez publicada, la imagen puede descargarse desde otra máquina utilizando:

```bash
docker pull ghcr.io/manto890/devops-backend:latest
```

En este proyecto se realizó esta prueba y Docker descargó correctamente la imagen desde GHCR.

Posteriormente se ejecutó:

```bash
docker run -d --name backend-ghcr -p 5001:5000 ghcr.io/manto890/devops-backend:latest
```

Esto permitió ejecutar la imagen publicada y comprobar que el backend funcionaba correctamente.

La aplicación se verificó mediante:

```bash
curl http://localhost:5001
```

Obteniendo:

```text
Hola desde el Backend!
```

### RESULTADO

La imagen Docker generada por GitHub Actions queda almacenada en GHCR y puede ser descargada posteriormente para ejecutar el backend.

Por tanto, el flujo conseguido en este proyecto es:

```text
Git push
   ↓
GitHub Actions
   ↓
Tests
   ↓
Docker Build
   ↓
Login GHCR
   ↓
Docker Push
   ↓
GHCR
   ↓
Docker Pull
   ↓
Docker Run
   ↓
Backend funcionando
```

Esto permite automatizar la construcción y distribución de imágenes Docker, que es una parte fundamental de los flujos de trabajo de CI/CD y DevOps.

## 8. CÓMO DESCARGAR LA IMAGEN

Una vez publicada la imagen Docker en **GitHub Container Registry (GHCR)**, es posible descargarla desde cualquier máquina que tenga Docker instalado y tenga acceso al registro.

Para descargar la imagen se utiliza el comando:

```bash
docker pull ghcr.io/manto890/devops-backend:latest
```

### ¿QUÉ HACE DOCKER PULL?

El comando `docker pull` descarga una imagen Docker desde un registro de contenedores y la almacena localmente en la máquina.

En este caso:

```text
docker pull
     ↓
GHCR
     ↓
ghcr.io/manto890/devops-backend:latest
     ↓
Imagen almacenada localmente
```

La imagen descargada es:

```text
ghcr.io/manto890/devops-backend:latest
```

Donde:

* **`ghcr.io`** → GitHub Container Registry.
* **`manto890`** → propietario de la imagen.
* **`devops-backend`** → nombre de la imagen.
* **`latest`** → tag de la imagen.

### DESCARGA REALIZADA

En este proyecto se ejecutó:

```bash
docker pull ghcr.io/manto890/devops-backend:latest
```

Docker descargó correctamente la imagen desde GHCR.

Durante la descarga se obtuvo un identificador `Digest`, que permite identificar de forma única el contenido concreto de la imagen:

```text
Digest: sha256:f431c9b54f0288a0064870f8fb9743c6f11c554251383917d6072c3002d2627b
```

### COMPROBACIÓN DE LA IMAGEN

Una vez descargada, podemos comprobar que Docker tiene la imagen almacenada localmente mediante:

```bash
docker images
```

Debería aparecer una entrada similar a:

```text
ghcr.io/manto890/devops-backend    latest
```

### EJECUTAR LA IMAGEN DESCARGADA

Descargar una imagen no significa que el contenedor esté ejecutándose.

Para crear y ejecutar un contenedor a partir de la imagen se utilizó:

```bash
docker run -d --name backend-ghcr -p 5001:5000 ghcr.io/manto890/devops-backend:latest
```

La relación de puertos es:

```text
Host:      5001
              ↓
Contenedor: 5000
              ↓
           Flask
```

Después se comprobó que el backend funcionaba correctamente mediante:

```bash
curl http://localhost:5001
```

Resultado:

```text
Hola desde el Backend!
```

### FLUJO COMPLETO

El proceso realizado en este proyecto es:

```text
GitHub Actions
      ↓
docker build
      ↓
Imagen Docker
      ↓
docker push
      ↓
GHCR
      ↓
docker pull
      ↓
Imagen descargada localmente
      ↓
docker run
      ↓
Contenedor funcionando
```

De esta forma se verificó que la imagen publicada en GHCR podía ser descargada y ejecutada correctamente.

## 9. CÓMO EJECUTAR EL CONTENEDOR

Una vez descargada la imagen Docker desde GHCR mediante `docker pull`, el siguiente paso es crear y ejecutar un contenedor utilizando dicha imagen.

Para ello se utilizó el comando:

```bash
docker run -d --name backend-ghcr -p 5001:5000 ghcr.io/manto890/devops-backend:latest
```

### QUE HACE DOCKER RUN?

El comando `docker run` crea un nuevo contenedor a partir de una imagen Docker y lo inicia.

En este caso, se utiliza la imagen:

```text
ghcr.io/manto890/devops-backend:latest
```

El contenedor creado recibe el nombre:

```text
backend-ghcr
```

### EXPLICACIÓN DEL COMANDO

```bash
docker run -d --name backend-ghcr -p 5001:5000 ghcr.io/manto890/devops-backend:latest
```

Cada parte tiene una función:

* **`docker run`** → crea y ejecuta un contenedor a partir de una imagen.
* **`-d`** → ejecuta el contenedor en segundo plano (*detached mode*).
* **`--name backend-ghcr`** → asigna el nombre `backend-ghcr` al contenedor.
* **`-p 5001:5000`** → conecta el puerto `5001` del ordenador con el puerto `5000` del contenedor.
* **`ghcr.io/manto890/devops-backend:latest`** → imagen utilizada para crear el contenedor.

Por tanto, desde el ordenador podemos acceder al backend mediante:

```text
http://localhost:5001
```

El puerto `5001` es el puerto utilizado en el ordenador, mientras que `5000` es el puerto donde escucha Flask dentro del contenedor.

### COMPROBACIÓN DEL CONTENEDOR

Después de ejecutar el comando, se puede comprobar que el contenedor está funcionando mediante:

```bash
docker ps
```

Debería aparecer una entrada similar a:

```text
backend-ghcr    ghcr.io/manto890/devops-backend:latest    ...    0.0.0.0:5001->5000/tcp
```

Esto indica que el contenedor está en ejecución y que el puerto `5001` del host está conectado con el puerto `5000` del contenedor.

### COMPROBACIÓN DE LA APLICACIÓN

Finalmente, se realizó una petición HTTP al backend utilizando `curl`:

```bash
curl http://localhost:5001
```

El resultado obtenido fue:

```text
Hola desde el Backend!
```

De esta forma se comprobó que la imagen generada y publicada mediante GitHub Actions podía descargarse y ejecutarse correctamente en otra máquina.

## 10. PRUEBAS REALIZADAS

Una vez finalizada la configuración del pipeline de GitHub Actions, se realizaron diferentes pruebas para comprobar que cada parte del proceso funcionaba correctamente.

### 10.1. PRUEBAS AUTOMÁTICAS EN PYTEST

Primero se ejecutaron los tests del backend de forma local:

```bash
pytest -v
```

El resultado fue:

```text
collected 2 items

test_app.py::test_home PASSED
test_app.py::test_health PASSED

2 passed
```

Esto confirmó que las rutas principales del backend respondían correctamente.

### 10.2. COMPROBACIÓN DEL PIPELINE EN GITHUB ACTIONS

Después se realizó un `git push` a la rama `main` para comprobar que GitHub Actions ejecutaba automáticamente el workflow.

El pipeline realizó correctamente las siguientes etapas:

```text
Checkout
   ↓
Configuración de Python
   ↓
Instalación de dependencias
   ↓
Tests
   ↓
Login en GHCR
   ↓
Docker Build
   ↓
Docker Push
```

El workflow finalizó correctamente, mostrando un resultado **exitoso (Success)**.

Esto confirmó que la automatización de CI estaba funcionando correctamente.

### 10.3. COMPROBACIÓN DE LA IMAGEN EN GHCR

Después de la ejecución del workflow, se comprobó que la imagen Docker había sido publicada correctamente en GitHub Container Registry.

La imagen publicada fue:

```text
ghcr.io/manto890/devops-backend:latest
```

### 10.4. DESCARGA DE LA IMAGEN

Para comprobar que la imagen podía utilizarse desde otra máquina o entorno Docker, se realizó:

```bash
docker pull ghcr.io/manto890/devops-backend:latest
```

Docker descargó correctamente la imagen desde GHCR.

### 10.5. Ejecución del contenedor

A continuación se creó un contenedor utilizando la imagen descargada:

```bash
docker run -d --name backend-ghcr -p 5001:5000 ghcr.io/manto890/devops-backend:latest
```

Se comprobó que el contenedor estaba ejecutándose mediante:

```bash
docker ps
```

El contenedor aparecía con el nombre:

```text
backend-ghcr
```

y con el mapeo de puertos:

```text
5001->5000
```

### 10.6. PRUEBA DE HTTP DE BACKEND

Finalmente, se realizó una petición HTTP al backend:

```bash
curl http://localhost:5001
```

La aplicación respondió:

```text
Hola desde el Backend!
```

Esto confirmó que el contenedor estaba funcionando y que la aplicación Flask era accesible desde el host.

### RESULTADO FINAL

Las pruebas realizadas permitieron verificar todo el flujo del proyecto:

```text
Código
  ↓
Git push
  ↓
GitHub Actions
  ↓
Pytest ✅
  ↓
Docker Build ✅
  ↓
Docker Push ✅
  ↓
GHCR ✅
  ↓
Docker Pull ✅
  ↓
Docker Run ✅
  ↓
Curl HTTP ✅
  ↓
Backend funcionando ✅
```

Por tanto, se comprobó que el pipeline es capaz de automatizar la validación del código, construir la imagen Docker, publicarla en GHCR y posteriormente utilizar dicha imagen para ejecutar el backend correctamente.


## 11. ¿QUÉ APRENDÍ?

Durante este proyecto aprendí a crear un flujo básico de **Integración Continua (CI)** utilizando GitHub Actions y Docker.

Los principales conocimientos adquiridos fueron:

### GIT Y GITHUB

Aprendí a utilizar Git para trabajar con el repositorio y a diferenciar las operaciones principales:

* `git push` → enviar cambios desde el entorno local a GitHub.
* `git pull` → descargar y actualizar cambios desde GitHub.
* `git clone` → descargar un repositorio por primera vez.

También aprendí que GitHub Actions puede obtener automáticamente el código del repositorio mediante `actions/checkout`.

### TESTS AUTOMATIZADOS

Aprendí a utilizar **pytest** para realizar pruebas automáticas sobre el backend.

Los tests permiten comprobar que la aplicación funciona correctamente antes de continuar con el proceso de construcción y publicación de la imagen Docker.

### GITHUB ACTIONS

Aprendí a crear un workflow utilizando GitHub Actions y a automatizar diferentes tareas.

El workflow se ejecuta automáticamente cuando se realiza un `git push` sobre la rama `main`.

El pipeline realiza:

```text
Git push
   ↓
Checkout
   ↓
Tests
   ↓
Docker Build
   ↓
Docker Push
```

También aprendí qué es un **GitHub-hosted runner**, que es el entorno temporal proporcionado por GitHub donde se ejecutan los pasos del workflow.

### DOCKER

Aprendí a diferenciar entre una **imagen Docker** y un **contenedor**.

* La imagen contiene todo lo necesario para ejecutar la aplicación.
* El contenedor es una instancia de esa imagen que se encuentra en ejecución.

También practiqué:

```bash
docker build
docker run
docker pull
docker push
docker ps
```

### GITHUB CONTAINER REGISTRY

Aprendí qué es **GHCR** y cómo utilizarlo para almacenar imágenes Docker.

El flujo utilizado fue:

```text
Docker Build
     ↓
Docker Login
     ↓
Docker Push
     ↓
GHCR
     ↓
Docker Pull
     ↓
Docker Run
```

También aprendí a utilizar `GITHUB_TOKEN` y los permisos de GitHub Actions necesarios para publicar paquetes:

```yaml
permissions:
  contents: read
  packages: write
```

### PUERTOS Y CONTENEDORES

Aprendí a realizar un mapeo de puertos mediante:

```bash
-p 5001:5000
```

Esto conecta el puerto `5001` del host con el puerto `5000` del contenedor.

```text
Host:5001
    ↓
Container:5000
    ↓
Flask
```

### CONCEPTO DE CI/CD

Finalmente, comprendí de forma práctica cómo funciona un flujo básico de **CI/CD**.

En este proyecto se implementó principalmente la parte de **Integración Continua (CI)**: cada vez que se sube código al repositorio, se ejecutan automáticamente pruebas y se construye y publica una imagen Docker.

El proyecto completo queda representado por:

```text
Desarrollador
     ↓
   git push
     ↓
   GitHub
     ↓
GitHub Actions
     ↓
   Pytest
     ↓
Docker Build
     ↓
   GHCR
     ↓
Docker Pull
     ↓
Docker Run
     ↓
Aplicación funcionando
```

Este proyecto me permitió entender de forma práctica cómo se pueden automatizar procesos que normalmente tendrían que realizarse manualmente y cómo Git, GitHub Actions, Docker y GHCR pueden trabajar juntos dentro de un flujo DevOps.
