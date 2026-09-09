# DIA 5 -- TERRAFORM + AZURE

## OBJETIVO

En este laboratorio he aprendido a utilizar **Terraform** para crear y gestionar infraestructura en Microsoft Azure mediante código (**Infrastructure as Code — IaC**).

El objetivo principal era pasar de crear recursos manualmente desde Azure Portal a definirlos mediante un archivo `main.tf`.

La arquitectura final contiene:

```text
Terraform
   │
   ▼
Microsoft Azure
   │
   ├── Resource Group
   ├── Virtual Network
   ├── Subnet
   ├── Public IP
   ├── Network Interface
   ├── Network Security Group
   ├── SSH Security Rule
   └── Virtual Machine
```

---

# 1. ENTORNO UTILIZADO

Sistema operativo:

* Windows 11
* WSL Ubuntu
* Visual Studio Code

Herramientas:

* Terraform
* Azure CLI
* Microsoft Azure
* SSH
* Git
* GitHub

Versiones utilizadas:

```bash
terraform version
```

Terraform:

```text
Terraform v1.16.0
```

Azure CLI:

```bash
az version
```

Azure CLI:

```text
2.90.0
```

---

# 2. COMPROBACIÓN DE AZURE

Primero comprobé que Azure CLI estuviera autenticado:

```bash
az account show
```

La suscripción utilizada estaba activa y configurada como suscripción predeterminada.

Esto permitió que Terraform pudiera comunicarse con Azure utilizando las credenciales de Azure CLI.

---

# 3. CREACIÓN DEL PROYECTO DE TERRAFORM

El laboratorio se realizó dentro del repositorio:

```text
prueba__dev_ops/
└── devops-dia5/
```

Dentro de esta carpeta se creó:

```text
devops-dia5/
├── main.tf
├── .terraform/
└── .terraform.lock.hcl
```

El archivo principal utilizado fue:

```text
main.tf
```

---

# 4. CONFIGURACIÓN DEL PROVEEDOR DE AZURE

En `main.tf` configuré el proveedor de Azure:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

El proveedor utilizado es:

```text
hashicorp/azurerm
```

Este proveedor permite que Terraform gestione recursos de Microsoft Azure.

---

# 5. INICIALIZACIÓN DE TERRAFORM

Ejecuté:

```bash
terraform init
```

Terraform descargó el proveedor `azurerm` y creó:

```text
.terraform/
.terraform.lock.hcl
```

El archivo `.terraform.lock.hcl` permite mantener controlada la versión del proveedor utilizada por el proyecto.

---

# 6. RESOURCE GROUP

El primer recurso definido fue el Resource Group:

```hcl
resource "azurerm_resource_group" "cloud_lab" {
  name     = "rg-cloud-lab"
  location = "Spain Central"
}
```

El Resource Group actúa como contenedor lógico de los recursos de Azure utilizados en el laboratorio.

---

# 7. PROBLEMA CON EL RESOURCE GROUP EXISTENTE

Al ejecutar:

```bash
terraform apply
```

Terraform indicó que:

```text
rg-cloud-lab
```

ya existía en Azure.

En lugar de crear otro Resource Group, comprobé el recurso:

```bash
az group show --name rg-cloud-lab
```

Después lo incorporé al estado de Terraform mediante:

```bash
terraform import azurerm_resource_group.cloud_lab "/subscriptions/2a2ffa7d-ec53-41c9-926a-24bb00479174/resourceGroups/rg-cloud-lab"
```

Después ejecuté:

```bash
terraform plan
```

Y Terraform indicó:

```text
No changes.
```

Esto permitió aprender el concepto de **Terraform Import**.

---

# 8. VIRTUAL NETWORK

Después creé una Virtual Network:

```hcl
resource "azurerm_virtual_network" "cloud_lab" {
  name                = "vnet-cloud-lab"
  location            = azurerm_resource_group.cloud_lab.location
  resource_group_name = azurerm_resource_group.cloud_lab.name
  address_space       = ["10.0.0.0/16"]
}
```

La red utiliza:

```text
10.0.0.0/16
```

Esto proporciona el espacio de direcciones privadas de la red.

---

# 9. SUBRED

Dentro de la Virtual Network creé una subnet:

```hcl
resource "azurerm_subnet" "cloud_lab" {
  name                 = "subnet-cloud-lab"
  resource_group_name  = azurerm_resource_group.cloud_lab.name
  virtual_network_name = azurerm_virtual_network.cloud_lab.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

La subnet utiliza:

```text
10.0.1.0/24
```

La VM creada posteriormente recibió una IP privada dentro de esta red.

---

# 10. IP PÚBLICA

Creé una IP pública:

```hcl
resource "azurerm_public_ip" "cloud_lab" {
  name                = "pip-cloud-lab"
  resource_group_name = azurerm_resource_group.cloud_lab.name
  location            = azurerm_resource_group.cloud_lab.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
```

Configuración:

```text
Nombre: pip-cloud-lab
SKU: Standard
Asignación: Static
```

Esta IP permite acceder desde Internet al recurso asociado.

---

# 11. INTERFAZ DE RED

Después creé una Network Interface:

```hcl
resource "azurerm_network_interface" "cloud_lab" {
  name                = "nic-cloud-lab"
  location            = azurerm_resource_group.cloud_lab.location
  resource_group_name = azurerm_resource_group.cloud_lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cloud_lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cloud_lab.id
  }
}
```

La NIC conecta la máquina virtual con:

```text
Virtual Network
      ↓
Subnet
      ↓
Network Interface
      ↓
Virtual Machine
```

La IP privada se configuró como dinámica.

---

# 12. GRUPO DE SEGURIDAD DE RED

Creé un Network Security Group:

```hcl
resource "azurerm_network_security_group" "cloud_lab" {
  name                = "nsg-cloud-lab"
  location            = azurerm_resource_group.cloud_lab.location
  resource_group_name = azurerm_resource_group.cloud_lab.name
}
```

El NSG permite controlar el tráfico de red que entra y sale de los recursos.

---

# 13. REGLA SSH

Para poder conectarme a la VM mediante SSH creé una regla para el puerto 22:

```hcl
resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.cloud_lab.name
  network_security_group_name = azurerm_network_security_group.cloud_lab.name
}
```

La regla permite:

```text
TCP
Puerto destino: 22
Dirección: Inbound
Acceso: Allow
```

### SEGURIDAD

Durante el laboratorio utilicé:

```text
source_address_prefix = "*"
```

Esto permite conexiones SSH desde cualquier dirección IP.

Para un entorno real debería restringirse el acceso, por ejemplo, únicamente a una IP o rango de IP autorizado.

---

# 14. ASOCIACIÓN DEL NSG CON LA NIC

El NSG se asoció a la Network Interface:

```hcl
resource "azurerm_network_interface_security_group_association" "cloud_lab" {
  network_interface_id      = azurerm_network_interface.cloud_lab.id
  network_security_group_id = azurerm_network_security_group.cloud_lab.id
}
```

Esto hace que las reglas del NSG se apliquen a la interfaz de red de la VM.

---

# 15. CREACIÓN DE LA CLAVE SSH

Para poder acceder a la nueva VM mediante SSH generé una nueva pareja de claves:

```bash
ssh-keygen -t rsa -b 4096
```

Se generaron:

```text
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
```

Terraform utiliza la clave pública:

```text
~/.ssh/id_rsa.pub
```

La clave privada permanece en el equipo local y se utiliza posteriormente para realizar la conexión SSH.

---

# 16. MÁQUINA VIRTUAL CON TERRAFORM

Finalmente definí la VM:

```hcl
resource "azurerm_linux_virtual_machine" "cloud_lab" {
  name                = "vm-terraform-lab"
  resource_group_name = azurerm_resource_group.cloud_lab.name
  location            = azurerm_resource_group.cloud_lab.location
  size                = "Standard_B2ts_v2"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.cloud_lab.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
```

Características principales:

```text
Nombre: vm-terraform-lab
Sistema operativo: Ubuntu 22.04
Tamaño: Standard_B2ts_v2
Usuario: azureuser
Autenticación: SSH
```

---

# 17. PROBLEMA: VM EXISTENTE

Durante el laboratorio descubrí que ya existía una VM llamada:

```text
vm-cloud-lab
```

Esta VM había sido creada anteriormente desde Azure Portal.

Intenté importarla inicialmente a Terraform:

```bash
terraform import azurerm_linux_virtual_machine.cloud_lab "..."
```

Terraform detectó diferencias entre la configuración existente y mi código.

Entre las diferencias estaban:

* Nombre/configuración
* Usuario administrador
* NIC
* Tamaño de VM
* Imagen de Ubuntu
* Clave SSH
* Configuración del disco

Terraform proponía reemplazar la VM.

### Decisión

No ejecuté el `apply` de ese plan porque podía modificar o destruir la VM existente.

En su lugar, eliminé únicamente la VM importada del **estado de Terraform**:

```bash
terraform state rm azurerm_linux_virtual_machine.cloud_lab
```

Esto es importante:

```text
terraform state rm
```

NO elimina el recurso de Azure.

Simplemente deja de estar gestionado por Terraform.

La VM existente:

```text
vm-cloud-lab
```

se mantuvo intacta.

---

# 18. SEGUNDA VM PARA TERRAFORM

Para evitar modificar la VM existente decidí crear una VM independiente:

```text
vm-terraform-lab
```

De esta manera:

```text
VM existente
vm-cloud-lab
      │
      └── Creada manualmente

VM nueva
vm-terraform-lab
      │
      └── Creada mediante Terraform
```

Esto permitió practicar Terraform sin poner en riesgo la infraestructura anterior.

---

# 19. PROBLEMA: CAPACIDAD DE STANDARD_B1S

Inicialmente configuré:

```hcl
size = "Standard_B1s"
```

El `terraform apply` falló porque Azure no tenía capacidad disponible para ese SKU en `SpainCentral`.

Azure devolvió un error:

```text
SkuNotAvailable
Standard_B1s
SpainCentral
Capacity Restrictions
```

Esto me permitió aprender que un tamaño de VM puede estar disponible en una región pero no necesariamente tener capacidad disponible en ese momento.

---

# 20. COMPROBACIÓN DE SKU'S DISPONIBLES

Consulté los tamaños disponibles en la región:

```bash
az vm list-skus --location spaincentral --resource-type virtualMachines --query "[].name" -o tsv | head -50
```

Entre los resultados apareció:

```text
Standard_B2ts_v2
```

Además, la VM existente utilizaba ese mismo tamaño.

Por ello cambié:

```hcl
size = "Standard_B2ts_v2"
```

---

# 21. TERRAFORM PLAN

Antes de crear la infraestructura ejecuté:

```bash
terraform plan
```

Terraform indicó:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Esto significa:

```text
1 recurso nuevo
0 modificaciones
0 eliminaciones
```

Este paso es fundamental porque permite revisar qué cambios realizará Terraform antes de ejecutarlos.

---

# 22. TERRAFORM APPLY

Después ejecuté:

```bash
terraform apply
```

Terraform creó la VM correctamente:

```text
Creation complete
```

Resultado:

```text
Apply complete!
Resources: 1 added, 0 changed, 0 destroyed.
```

La infraestructura quedó creada en Azure.

---

# 23. REVISIÓN DE APLICACIÓN DE ARQUITECTURA

Después de crear la VM volví a ejecutar:

```bash
terraform plan
```

Terraform devolvió:

```text
No changes.
Your infrastructure matches the configuration.
```

Esto demuestra que:

```text
Código Terraform
       ↓
Infraestructura Azure
       ↓
Estado Terraform
```

están sincronizados.

---

# 24. OBTENER LA IP PÚBLICA

Para obtener la IP pública de la nueva VM ejecuté:

```bash
az vm show -d -g rg-cloud-lab -n vm-terraform-lab --query publicIps -o tsv
```

La IP pública obtenida durante la práctica fue:

```text
158.158.3.229
```

---

# 25. CONEXIÓN SSH

Finalmente probé el acceso real a la VM:

```bash
ssh -i ~/.ssh/id_rsa azureuser@158.158.3.229
```

La primera conexión mostró la advertencia de autenticidad del host.

Acepté el host y conseguí acceder:

```text
azureuser@vm-terraform-lab:~$
```

La conexión SSH funcionó correctamente.

---

# 26. VERIFICACIÓN DE LA MÁQUINA

Una vez dentro de la VM comprobé información del sistema.

La máquina estaba ejecutando:

```text
Ubuntu 22.04.5 LTS
```

La interfaz de red tenía una IP privada dentro de la subnet:

```text
10.0.1.4
```

Esto confirmó que la VM estaba correctamente conectada a:

```text
vnet-cloud-lab
      ↓
subnet-cloud-lab
      ↓
nic-cloud-lab
      ↓
vm-terraform-lab
```

---

# 27. ARQUITECTURA FINAL

La infraestructura creada con Terraform quedó de la siguiente manera:

```text
                    Azure
                      │
                rg-cloud-lab
                      │
        ┌─────────────┴─────────────┐
        │                           │
vnet-cloud-lab                 pip-cloud-lab
        │
subnet-cloud-lab
        │
nic-cloud-lab
        │
        ├────────────── nsg-cloud-lab
        │                    │
        │               allow-ssh :22
        │
        ▼
vm-terraform-lab
        │
        └── Ubuntu 22.04
```

La VM tiene:

```text
Nombre: vm-terraform-lab
Usuario: azureuser
Tamaño: Standard_B2ts_v2
IP privada: 10.0.1.4
Acceso: SSH
```

---

# 28. DIFERENCIA ENTRE LAS DOS MV'S

Durante este laboratorio quedaron dos máquinas virtuales independientes.

### VM EXISTENTE

```text
vm-cloud-lab
```

* Creada manualmente desde Azure Portal
* Usuario: `mantonio`
* No forma parte de la infraestructura Terraform del laboratorio
* Se mantuvo intacta

### VM TERRAFORM

```text
vm-terraform-lab
```

* Creada mediante Terraform
* Usuario: `azureuser`
* Ubuntu 22.04
* Gestionada mediante Terraform
* Conectada mediante SSH

---

# 29. CONCEPTOS APRENDIDOS

Durante el Día 5 aprendí:

### TERRAFORM

* `terraform init`
* `terraform plan`
* `terraform apply`
* `terraform import`
* `terraform state rm`
* Estado de Terraform
* Dependencias entre recursos
* Infrastructure as Code

### AZURE

* Resource Groups
* Virtual Networks
* Subnets
* Public IP
* Network Interfaces
* Network Security Groups
* Security Rules
* Virtual Machines
* SKUs
* Regiones de Azure

### LINUX / SSH

* Generación de claves SSH
* Autenticación mediante clave pública
* Conexión SSH a una VM
* Comprobación del sistema Linux

---

# 30. INFRAESTRUCTURE AS A CODE

Antes:

```text
Azure Portal
     ↓
Crear recurso manualmente
     ↓
Configurar recurso
     ↓
Repetir manualmente
```

Ahora:

```text
main.tf
   ↓
terraform plan
   ↓
terraform apply
   ↓
Azure
```

La infraestructura queda definida mediante código.

Esto permite:

* Reproducibilidad
* Automatización
* Versionado con Git
* Revisar cambios antes de aplicarlos
* Crear infraestructura de forma consistente
* Reducir configuraciones manuales

---

# 31. FLUJO DE TRABAJO APRENDIDO

El flujo que debo seguir normalmente es:

```text
1. Modificar main.tf
        ↓
2. terraform fmt
        ↓
3. terraform validate
        ↓
4. terraform plan
        ↓
5. Revisar cambios
        ↓
6. terraform apply
        ↓
7. Verificar infraestructura
        ↓
8. terraform plan
        ↓
9. Comprobar "No changes"
```

Este flujo será especialmente importante en futuros proyectos de Cloud/DevOps.

---

# 32. RESULTADO FINAL

El laboratorio terminó correctamente.

Terraform consiguió crear y gestionar infraestructura real en Azure:

```text
Terraform
   ↓
Resource Group
   ↓
Virtual Network
   ↓
Subnet
   ↓
Public IP
   ↓
NIC
   ↓
NSG + SSH Rule
   ↓
Virtual Machine
   ↓
SSH
   ↓
Ubuntu 22.04
```

Finalmente:

```text
terraform plan
```

devolvió:

```text
No changes.
Your infrastructure matches the configuration.
```

Y la conexión:

```bash
ssh -i ~/.ssh/id_rsa azureuser@158.158.3.229
```

funcionó correctamente.

## DIA 5 COMPLETADO

He creado mi primera infraestructura completa de Azure mediante **Terraform**, he trabajado con el estado de Terraform, imports, redes, seguridad, máquinas virtuales y acceso SSH.
