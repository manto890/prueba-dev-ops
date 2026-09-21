# Día 6 - CI/CD, Docker, GitHub Actions y Terraform

## Objetivo

En este día se construyó una pequeña aplicación Flask y se creó un pipeline de integración continua con GitHub Actions.

El objetivo principal fue conectar diferentes partes del flujo DevOps:

GitHub → GitHub Actions → Tests → Docker → GitHub Container Registry → Azure → Terraform

Además, se configuró Terraform para utilizar un backend remoto en Azure Storage, evitando mantener el estado de Terraform únicamente de forma local.

---

# 1. Estructura del proyecto

Se creó la siguiente estructura:

```text
devops-dia6/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   └── test_app.py
│
├── docker/
│   └── Dockerfile
│
├── terraform/
│   ├── main.tf
│   ├── terraform.tfvars
│   └── .terraform.lock.hcl
│
└── .github/
    └── workflows/
        └── ci-dia6.yml
```
Cada parte tiene una función concreta:

app/ → aplicación Flask y pruebas automatizadas.
docker/ → configuración para construir la imagen Docker.
terraform/ → configuración de infraestructura en Azure.
.github/workflows/ → automatización mediante GitHub Actions.

# 2. Aplicación Flask

Se creó una aplicación sencilla utilizando Flask.

Archivo:

app/app.py

La aplicación dispone de dos endpoints.

Endpoint /

Devuelve:

Proyecto DevOps - Aplicacion funcionando correctamente!
Endpoint /health

Devuelve:

OK

La aplicación escucha en:

0.0.0.0:5000

Esto permite ejecutar posteriormente la aplicación dentro de un contenedor Docker.

# 3. Dependencias de Python

El archivo:

app/requirements.txt

contiene las dependencias necesarias para ejecutar la aplicación.

La dependencia principal utilizada es:

Flask

# 4. Tests automatizados

Para comprobar que la aplicación funciona correctamente se creó:

app/test_app.py

Se realizaron pruebas sobre los dos endpoints de la aplicación:

/
/health

Los tests comprueban:

Que el endpoint responde.
Que el código HTTP es 200.
Que el contenido de la respuesta es el esperado.

Los tests creados fueron:

from app import app


def test_home():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert response.data == b"Proyecto DevOps - Aplicacion funcionando correctamente!"


def test_health():
    client = app.test_client()
    response = client.get("/health")
    assert response.status_code == 200
    assert response.data == b"OK"
Resultado

Los tests se ejecutaron localmente mediante pytest.

Resultado:

2 passed

Esto confirmó que los endpoints funcionaban correctamente antes de integrarlos en GitHub Actions.

# 5. Entorno virtual de Python

Al intentar instalar pytest directamente en el Python del sistema apareció la protección de Ubuntu contra instalaciones globales de paquetes Python.

Para solucionarlo se creó un entorno virtual:

.venv

Dentro del entorno virtual se instalaron:

pytest
Flask

El entorno virtual no se sube a GitHub.

Para evitarlo se añadieron estas rutas al .gitignore:

# Python
devops-dia6/app/.venv/
devops-dia6/app/__pycache__/
devops-dia6/app/.pytest_cache/

De esta forma se evita subir al repositorio archivos temporales y el entorno virtual local.

# 6. Docker

Después de comprobar que la aplicación funcionaba correctamente se creó una imagen Docker.

## Archivo:

docker/Dockerfile

## Contenido:

FROM python:3.12-alpine

WORKDIR /app

COPY app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 5000

CMD ["python", "app.py"]
## Funcionamiento del Dockerfile
### Imagen base

Se utiliza:

python:3.12-alpine

Es una imagen ligera de Python basada en Alpine Linux.

### Directorio de trabajo

Se establece:

/app
### Dependencias

Primero se copia:

app/requirements.txt

y posteriormente se instalan las dependencias.

### Aplicación

Después se copia el contenido de:

app/

al contenedor.

### Puerto

La aplicación utiliza:

5000

por lo que se declara:

EXPOSE 5000
### Ejecución

El contenedor inicia la aplicación mediante:

CMD ["python", "app.py"]

# 7. Construcción de la imagen Docker

La imagen se construyó desde la raíz del proyecto utilizando:

docker build -t proyecto-devops:v1 -f docker/Dockerfile .

La imagen resultante fue:

proyecto-devops:v1

# 8. Ejecución del contenedor

La imagen se ejecutó mediante:

docker run -d --name proyecto-devops -p 5000:5000 proyecto-devops:v1

Esto creó el contenedor:

proyecto-devops

y realizó la correspondencia:

Puerto del equipo → Puerto del contenedor

5000 → 5000

Se comprobó que la aplicación respondía correctamente.

/
Proyecto DevOps - Aplicacion funcionando correctamente!
/health
OK

Con esto se verificó que Flask funcionaba correctamente dentro de Docker.

# 9. GitHub Container Registry

Como siguiente paso se incorporó GitHub Container Registry (GHCR).

GHCR permite almacenar las imágenes Docker generadas por el proyecto.

La imagen utilizada por el pipeline tiene el formato:

ghcr.io/${{ github.repository_owner }}/proyecto-devops:latest

De esta forma, GitHub Actions puede:

Construir la imagen.
Autenticarse en GHCR.
Publicar la imagen.

La imagen queda disponible en el registro para poder utilizarla posteriormente durante el despliegue.

# 10. GitHub Actions

Se creó un nuevo workflow específico para el Día 6:

.github/workflows/ci-dia6.yml

El workflow se ejecuta cuando se realiza un push sobre:

main

El pipeline se divide en dos jobs:

test-and-build
       ↓
terraform

El segundo job depende de que test-and-build termine correctamente.

# 11. Job test-and-build

El primer job se encarga de comprobar la aplicación y construir/publicar la imagen Docker.

## 11.1 Checkout

GitHub Actions descarga el contenido del repositorio mediante:

actions/checkout@v4

## 11.2 Configuración de Python

Se utiliza:

Python 3.12

mediante:

actions/setup-python@v5
## 11.3 Instalación de dependencias

GitHub Actions entra en:

devops-dia6/app

e instala:

requirements.txt
pytest
## 11.4 Ejecución de tests

Se ejecuta:

pytest -v

Los tests deben finalizar correctamente antes de continuar con la construcción de Docker.

## 11.5 Login en GHCR

GitHub Actions se autentica en:

ghcr.io

utilizando:

GITHUB_TOKEN

mediante:

docker/login-action@v3
## 11.6 Construcción de Docker

La imagen se construye utilizando:

devops-dia6/docker/Dockerfile

y se etiqueta como:

ghcr.io/${{ github.repository_owner }}/proyecto-devops:latest
## 11.7 Push a GHCR

Finalmente, la imagen se publica mediante:

docker push ghcr.io/${{ github.repository_owner }}/proyecto-devops:latest

# 12. Terraform

Terraform se utiliza para gestionar la infraestructura de Azure.

El proyecto utiliza el proveedor:

hashicorp/azurerm

con:

~> 4.0

La configuración se encuentra en:

devops-dia6/terraform/main.tf

# 13. Importación de la VM existente

En lugar de crear otra máquina virtual, se decidió utilizar la VM de Azure que ya existía:

vm-cloud-lab

dentro del Resource Group:

rg-cloud-lab

La VM utiliza:

Ubuntu 24.04 LTS

y el tamaño:

Standard_B2ts_v2

La VM fue importada a Terraform para que Terraform pudiera gestionar una infraestructura que ya existía.

Después se ajustó la configuración de Terraform para que coincidiera con la infraestructura real de Azure.

# 14. Comprobación de Terraform

Una vez reconciliada la configuración se ejecutó:

terraform plan

El resultado fue:

No changes. Your infrastructure matches the configuration.

Esto significa que Terraform reconoce correctamente la infraestructura existente y no detecta cambios pendientes.

# 15. Backend remoto de Terraform

Uno de los puntos principales del Día 6 fue configurar un backend remoto para Terraform.

Antes de realizar esta configuración, el estado de Terraform podía almacenarse localmente mediante:

terraform.tfstate

Se decidió almacenar el estado en Azure Storage.

Para ello se creó una cuenta de almacenamiento:

sttfstatecloudlab

dentro del Resource Group:

rg-cloud-lab

También se creó un contenedor:

tfstate

El archivo de estado remoto utilizado es:

devops-dia6.tfstate

# 16. Configuración del backend Azure

En main.tf se añadió:

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cloud-lab"
    storage_account_name = "sttfstatecloudlab"
    container_name       = "tfstate"
    key                  = "devops-dia6.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

  }

  required_version = ">= 1.6.0"
}

De esta manera Terraform utiliza Azure Storage como backend remoto.

# 17. Migración del Terraform State

Una vez creado el backend remoto se realizó la migración del estado local al backend de Azure.

La migración finalizó correctamente.

Después se comprobó el contenido del estado mediante:

terraform state list

Resultado:

azurerm_linux_virtual_machine.cloud_lab

Esto confirmó que el recurso de la VM estaba registrado en el estado remoto.

Posteriormente se volvió a ejecutar:

terraform plan

Resultado:

No changes. Your infrastructure matches the configuration.

Por tanto, el estado remoto quedó correctamente configurado.

# 18. Autenticación de GitHub Actions con Azure

Para que GitHub Actions pudiera acceder a Azure se configuró autenticación mediante OpenID Connect (OIDC).

El workflow utiliza:

- name: Azure Login
  uses: azure/login@v2

con:

AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID

Estas variables están configuradas en GitHub.

La autenticación mediante OIDC permite que GitHub Actions pueda iniciar sesión en Azure sin almacenar una contraseña de usuario de Azure dentro del repositorio.

# 19. Permisos para Terraform State

La identidad utilizada por GitHub Actions necesitaba permisos adicionales sobre Azure Storage para poder acceder al estado remoto.

Se asignó:

Storage Blob Data Contributor

sobre la cuenta de almacenamiento utilizada por Terraform.

De esta manera GitHub Actions puede acceder al contenedor:

tfstate

y al estado:

devops-dia6.tfstate

# 20. Job terraform de GitHub Actions

El segundo job del workflow se ejecuta después de:

test-and-build

siempre que este termine correctamente.

Este job realiza cuatro pasos principales.

## 20.1 Azure Login

GitHub Actions inicia sesión en Azure mediante OIDC.

## 20.2 Comprobación de Azure

Se ejecuta:

az account show

para comprobar la cuenta de Azure utilizada por el workflow.

## 20.3 Terraform Init

Se ejecuta:

terraform init

dentro de:

devops-dia6/terraform

Esto permite inicializar Terraform y conectarse al backend remoto configurado en Azure Storage.

## 20.4 Terraform Validate

Se ejecuta:

terraform validate

para comprobar que la configuración de Terraform es válida.

## 20.5 Terraform Plan

Finalmente se ejecuta:

terraform plan

Este paso permite comprobar qué cambios realizaría Terraform sin aplicar modificaciones sobre la infraestructura.

# 21. Resultado del pipeline

El workflow del Día 6 se ejecutó correctamente en GitHub Actions.

El resultado final fue:

Tests                  Hecho
Docker Build           Hecho
Push a GHCR            Hecho
Azure Login            Hecho
Terraform Init         Hecho
Terraform Validate     Hecho
Terraform Plan         Hecho

El primer intento del workflow había presentado un fallo, pero posteriormente se realizó otro intento sobre el mismo commit y finalizó correctamente.

El último intento quedó completamente en verde.

# 22. Flujo actual del proyecto

Actualmente el flujo conseguido es:

┌────────────────────┐
│       GitHub       │
│     Repository     │
└─────────┬──────────┘
          │
          │ push
          ▼
┌────────────────────┐
│   GitHub Actions   │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│       Tests        │
│       pytest       │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│    Docker Build    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│       GHCR         │
│  Docker Registry   │
└────────────────────┘


          │
          │
          ▼

┌────────────────────┐
│    Azure Login     │
│       OIDC         │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│     Terraform      │
│       Init         │
│      Validate      │
│       Plan         │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   Azure Storage    │
│                    │
│ devops-dia6.tfstate│

# 23. Arquitectura de la infraestructura

La infraestructura utilizada actualmente incluye:

Azure
│
├── Resource Group
│   └── rg-cloud-lab
│
├── Virtual Machine
│   └── vm-cloud-lab
│
└── Storage Account
    └── sttfstatecloudlab
        │
        └── Container
            └── tfstate
                └── devops-dia6.tfstate

La VM vm-cloud-lab ya disponía de Docker y Nginx de fases anteriores del laboratorio.
