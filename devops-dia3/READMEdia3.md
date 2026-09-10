# DIA 3 — DOCKER COMPOSE: NGINX + BACKEND FLASK + POSTGRESQL

## OBJETIVO

El objetivo del Día 3 fue avanzar desde un contenedor individual hacia una arquitectura formada por varios servicios utilizando **Docker Compose**.

La práctica consistió en crear una aplicación formada por:

* **NGINX** como servidor/proxy.
* **BACKEND FLASK** como aplicación.
* **POSTGRESQL** como base de datos.
* Comunicación entre los servicios mediante la red interna de Docker Compose.

La estructura del laboratorio quedó organizada dentro de `devops-dia3`.

---

## ESTRUCTURA DEL PROYECTO

La carpeta contiene:

```text
devops-dia3/
├── docker-compose.yml
├── nginx/
│   └── nginx.conf
└── backend/
    ├── app.py
    ├── Dockerfile
    ├── requirements.txt
    ├── test_app.py
    └── .gitignore
```

Durante las pruebas también se generaron archivos de entorno local como `.venv`, `__pycache__` y `.pytest_cache`, que forman parte del entorno de desarrollo/pruebas y no de la aplicación propiamente dicha.

---

# 1. BACKEND FLASK

Se creó una aplicación Python utilizando **Flask**.

El archivo principal fue:

```text
backend/app.py
```

La aplicación importa Flask y `psycopg`:

```python
from flask import Flask
import psycopg
```

Se creó la aplicación:

```python
app = Flask(__name__)
```

## ENDPOINT PRINCIPAL `/`

El endpoint `/` devuelve:

```text
Hola desde el Backend!
```

```python
@app.route("/")
def home():
    return "Hola desde el Backend!"
```

Este endpoint permite comprobar rápidamente que el backend está funcionando.

---

## ENDPOINT \HEALTH

Se creó un endpoint específico para comprobar el estado de la aplicación:

```python
@app.route("/health")
def health():
    return "OK"
```

Si responde:

```text
OK
```

significa que el backend está funcionando correctamente.

Este tipo de endpoint es especialmente útil posteriormente para **health checks, monitorización y despliegues**.

---

# 2. CONEXIÓN BACKEND CON POSTGRESQL

Se añadió un tercer endpoint:

```text
/users
```

Este endpoint permite comprobar la comunicación entre Flask y PostgreSQL.

La aplicación establece una conexión utilizando:

```python
conn = psycopg.connect(
    host="postgres",
    port=5432,
    dbname="devopsdb",
    user="devops",
    password="devops123"
)
```

Un detalle importante es:

```text
host="postgres"
```

No se utiliza `localhost`.

Esto se debe a que el backend y PostgreSQL funcionan como **contenedores diferentes** dentro de Docker Compose. El servicio de PostgreSQL se llama `postgres`, por lo que el backend puede utilizar ese nombre para comunicarse con él mediante la red interna de Docker Compose.

Después se ejecuta una consulta SQL:

```python
cur.execute("SELECT id, nombre FROM usuarios")
```

Se recuperan los resultados:

```python
users = cur.fetchall()
```

Finalmente se cierran el cursor y la conexión:

```python
cur.close()
conn.close()
```

Y se devuelve el resultado:

```python
return str(users)
```

De esta manera, el flujo es:

```text
Cliente
   ↓
Nginx
   ↓
Backend Flask
   ↓
PostgreSQL
   ↓
usuarios
```

---

# 3. PUERTO DEL BACKEND

La aplicación Flask se ejecuta en:

```text
0.0.0.0:5000
```

mediante:

```python
app.run(host="0.0.0.0", port=5000)
```

El uso de `0.0.0.0` permite que la aplicación pueda recibir conexiones desde fuera del proceso dentro del contenedor.

---

# 4. DOCKERFILE DEL BACKEND

Se creó:

```text
backend/Dockerfile
```

Contenido:

```dockerfile
FROM python:3.12-alpine

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

## EXPLICACIÓN

### IMAGEN BASE

```dockerfile
FROM python:3.12-alpine
```

Se utiliza Python 3.12 sobre Alpine Linux.

Alpine es una distribución ligera, por lo que resulta apropiada para crear imágenes pequeñas.

### DIRECTORIO DE TRABAJO

```dockerfile
WORKDIR /app
```

El directorio de trabajo dentro del contenedor pasa a ser:

```text
/app
```

### DEPENDENCIAS

```dockerfile
COPY requirements.txt .
```

Se copia el archivo de dependencias al contenedor.

Después:

```dockerfile
RUN pip install --no-cache-dir -r requirements.txt
```

se instalan las dependencias necesarias.

### CÓDIGO DE APLICACIÓN

```dockerfile
COPY app.py .
```

Se copia el código Python.

### PUERTO

```dockerfile
EXPOSE 5000
```

Se documenta que la aplicación utiliza el puerto 5000.

### INICIO

```dockerfile
CMD ["python", "app.py"]
```

Cuando se inicia el contenedor, se ejecuta la aplicación Flask.

---

# 5. DOCKER COMPOSE

Se creó:

```text
devops-dia3/docker-compose.yml
```

La configuración contiene tres servicios principales:

```text
backend
postgres
nginx
```

El Compose utiliza:

```yaml
services:
```

---

## SERVICIO BACKEND

```yaml
backend:
  image: devops-backend:v2
  container_name: backend-compose
```

El backend utiliza la imagen:

```text
devops-backend:v2
```

y el contenedor recibe el nombre:

```text
backend-compose
```

---

## SERVICIO POSTGRESQL

```yaml
postgres:
  image: postgres:16-alpine
  container_name: postgres-compose
```

Se utiliza PostgreSQL 16 sobre Alpine.

Se configuraron las variables de entorno:

```yaml
environment:
  POSTGRES_USER: devops
  POSTGRES_PASSWORD: devops123
  POSTGRES_DB: devopsdb
```

Por tanto, la base de datos utilizada por la aplicación es:

```text
Base de datos: devopsdb
Usuario:       devops
Puerto:        5432
```

La configuración del Compose confirma estos valores.

---

# 6. SERVICIO NGINX

Se añadió un tercer servicio:

```yaml
nginx:
  image: nginx:alpine
  container_name: nginx-compose
```

Nginx utiliza la imagen ligera:

```text
nginx:alpine
```

El puerto publicado fue:

```yaml
ports:
  - "8083:80"
```

Por tanto:

```text
Puerto del host:       8083
Puerto del contenedor: 80
```

La configuración completa de este servicio está registrada en el Compose.

---

# 7. CONFIGURACIÓN PERSONALIZADA DE NGINX

Se creó:

```text
nginx/nginx.conf
```

y se montó dentro del contenedor mediante:

```yaml
volumes:
  - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
```

El `:ro` significa **read-only**, es decir, el contenedor puede leer el archivo pero no modificarlo.

---

# 8. ARQUITECTURA FINAL

El laboratorio evolucionó desde un único contenedor hacia una pequeña arquitectura de varios servicios:

```text
                    ┌──────────────────┐
                    │      Cliente     │
                    └────────┬─────────┘
                             │
                             │ HTTP :8083
                             ▼
                    ┌──────────────────┐
                    │      Nginx       │
                    │ nginx-compose    │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Flask Backend   │
                    │  backend-compose │
                    │      :5000       │
                    └────────┬─────────┘
                             │
                             │ PostgreSQL
                             ▼
                    ┌──────────────────┐
                    │    PostgreSQL    │
                    │ postgres-compose │
                    │      :5432       │
                    └──────────────────┘
```

La idea fundamental aprendida fue que **cada servicio puede ejecutarse en su propio contenedor y comunicarse con los demás mediante Docker Compose**.

---

# 9. RESULTADO DEL DÍA 3

Al finalizar el laboratorio se consiguió crear una aplicación compuesta por:

```text
Nginx
   ↓
Flask
   ↓
PostgreSQL
```

gestionada mediante Docker Compose.

Además, el backend dispone de:

```text
/
/health
/users
```

donde `/users` permite comprobar la conexión del backend con PostgreSQL.

Este ejercicio supuso un salto respecto a los días anteriores porque ya no se trabajó solamente con un contenedor, sino con **varios servicios que colaboran entre sí**.

---
