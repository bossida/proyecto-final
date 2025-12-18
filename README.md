**Proyecto TP-Final**

- **Resumen:**: Proyecto de ejemplo que contiene una aplicación Node.js (Express) con métricas Prometheus, despliegue por CI/CD (GitHub Actions) hacia una instancia EC2 usando Docker/ECR, y recursos de infraestructura gestionados con Terraform.

**Estructura del repositorio**
- **`app/`**: Código fuente de la aplicación Node.js (Express). Aquí están `index.js`, `package.json` y tests.
- **`.github/workflows/`**: Workflows de GitHub Actions, incluyendo `ci-cd.yml` y `install-monitoring.yml` (pipelines de CI/CD y despliegue).
- **`infra/`**: Archivos auxiliares para despliegue local con Docker Compose (opcional).
- **`prometheus/`**: Configuración de Prometheus (`prometheus.yml`).
- **`terraform/`**: Configuración de infraestructura para AWS (VPC, subnet, instancia EC2, ECR, claves, security groups, etc.).
- **`Dockerfile`**: Dockerfile raíz (si aplica) para construir la imagen de la aplicación.

**Requisitos previos**
- Local: `node` (v18), `npm`, `docker` (opcional), `docker-compose` (opcional).
- Para provisionar en la nube: `terraform` (v1.x), cuenta AWS con permisos suficientes.
- En GitHub: `secrets` configurados para el pipeline (ver sección `Secrets` abajo).

**Desarrollo local (app)**
- Instalar dependencias e iniciar localmente:
```bash
cd app
npm ci
node index.js
# o para desarrollo con nodemon (si está instalado):
# npx nodemon index.js
```
- La app expone:
  - API: `http://localhost:3080/` (o el puerto definido en `app/index.js`)
  - Swagger UI: `http://localhost:3080/api-docs`
  - Metrics (Prometheus): `http://localhost:9090/metrics`
  

**Tests**
- Ejecutar tests (desde `app/`):
```bash
cd app
npm test
```

**Construir y ejecutar con Docker (local)**
- Construir imagen local y ejecutar (ejemplo):
```bash
# Desde la raíz del repo
docker build -t mundose-local app
docker run -p 3080:3080 mundose-local
```

**CI/CD (GitHub Actions)**
- Archivo principal: `/.github/workflows/ci-cd.yml`.
- Flujo resumido:
  - `ci` job: instala dependencias, lint, tests y sube cobertura.
  - `build_and_deploy` job: construye imagen Docker, hace login a ECR, push, y via SSH crea/actualiza `~/deploy/docker-compose.yml` en el servidor remoto y hace `docker compose up -d`.
- Excepciones: se ha añadido `paths-ignore` en las triggers `push` y `pull_request` para no ejecutar el pipeline cuando sólo cambian archivos bajo: `terraform/**`, `infra/**`, `docs/**`, `prometheus/**`.

**Secrets necesarios en GitHub**
- `AWS_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `SERVER_HOST` (IP o hostname del servidor destino)
- `SERVER_USER` (usuario SSH, por ejemplo `ubuntu`)
- `SERVER_SSH_KEY` (clave privada SSH en formato PEM)
- `SONAR_TOKEN` (token de SonarQube)
- `SNYK_TOKEN` (para conectarse a Snyk)

**Infraestructura con Terraform**
- Carpeta: `terraform/`.
- Recursos principales: VPC, Subnet pública, Internet Gateway, Route Table, Security Groups, EC2 instance, ECR public repository, key pair generado con `tls_private_key`.
- El `user_data` de la instancia EC2 instala Docker.
- Security groups: se creó un SG para la aplicación, otro para monitoreo (puerto 9090) y otro para Grafana (3000)

Terraform: comandos comunes
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Despliegue remoto (Cómo trabaja la Action)**
- Ubicada en `/.github/workflows/ci-cd.yml`
- La job de deploy por SSH crea `~/deploy/docker-compose.yml` y despliega la app nodejs en el puerto 3080.


**Monitoreo (Prometheus + Grafana)**
- La creacion de Prometheus y Grafana se hace ejecuando en forma manual el job install-monitoring en .github\workflows. Una vez instalados se debe asociar Prometheus con Grafana e importar el dasboard de Grafana. 
- URL por defecto (tras provisioning):
  - Prometheus: `http://<EC2_PUBLIC_IP>:9090`
  - Grafana: `http://<EC2_PUBLIC_IP>:3000`


**Aplicaciones expuestas al finalizar el deploy**
- API: `http://<EC2_PUBLIC_IP>:3080/` Hello World 
- Swagger UI: `http://<EC2_PUBLIC_IP>:3080/api-docs`
- Metrics exporter Node : `http://<EC2_PUBLIC_IP>:3030/metrics`
- Metrics (Prometheus): `http://<EC2_PUBLIC_IP>:9090/`
- Metrics (Grafana): `http://<EC2_PUBLIC_IP>:3000`


**Curl API**
- curl http://<EC2_PUBLIC_IP>:3080/countries?name=<NOMBRE_PAIS>
- ej.  http://10.20.55.78:3080/countries?name=arg

