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
  - API: `http://localhost:3050/` (o el puerto definido en `app/index.js`)
  - Swagger UI: `http://localhost:3050/api-docs`
  - Metrics (Prometheus): `http://localhost:3050/metrics`

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
docker run -p 3050:3050 mundose-local
```
- Asegúrate de que el `Dockerfile` copie/ejecute la app correctamente. Si el `Dockerfile` está en `app/`, usa `-f app/Dockerfile app`.

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
- `SONAR_TOKEN` (si usas SonarQube)
- Opcionales: `SNYK_TOKEN`, `ECR_PUBLIC_ALIAS`.

**Infraestructura con Terraform**
- Carpeta: `terraform/`.
- Recursos principales: VPC, Subnet pública, Internet Gateway, Route Table, Security Groups, EC2 instance, ECR public repository, key pair generado con `tls_private_key`.
- El `user_data` de la instancia EC2 instala Docker y crea en `/home/ubuntu/monitoring` una `prometheus.yml` y un `docker-compose.yml` para levantar Prometheus y Grafana (Prometheus usa `network_mode: host` y Grafana se expone en el host `3001`).
- Security groups: se creó un SG para la aplicación y otro para monitoreo (puerto 9090) — verifica y ajusta según tus necesidades.

Terraform: comandos comunes
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Despliegue remoto (Cómo trabaja la Action)**
- La job de deploy por SSH crea `~/deploy/docker-compose.yml` con el mapping de puertos definido en la Action. Por defecto el mapping actual es `"3080:3050"` (host:container). Si quieres exponer el contenedor en `3050` en la máquina host, cambia la línea a `"3050:3050"` en `/.github/workflows/ci-cd.yml`.
- La instancia EC2 debe tener el Security Group apropiado abierto para el puerto que expones en host (por ejemplo 3080 o 3050) y para el puerto 9090 si quieres acceder a Prometheus desde fuera.

**Monitoreo (Prometheus + Grafana)**
- Prometheus config base en `prometheus/prometheus.yml` (scrapea `localhost:3050` por defecto). Si Prometheus corre en `host` network, `localhost:3050` raspea la app expuesta en la instancia.
- URL por defecto (tras provisioning):
  - Prometheus: `http://<EC2_PUBLIC_IP>:9090`
  - Grafana: `http://<EC2_PUBLIC_IP>:3001`
- Recomendación: limitar acceso público al puerto 9090 usando CIDR restringido o habilitar un proxy con autenticación.

**Cambio de puertos y problemas comunes**
- Si la app parece no responder en `3050`, verifica:
  - Que la app sea mapeada al host en la Action `docker-compose` (host:container). Si la Action tiene `- "3080:3050"`, accede por `EC2:3080`.
  - Que el Security Group en Terraform permita el puerto del host (no sólo el del container).
  - Que el contenedor esté en ejecución con `docker ps` en la instancia remota.

**Recomendaciones de seguridad**
- No uses `0.0.0.0/0` para producción; restringe el acceso a IPs conocidas.
- Protege el acceso a Prometheus y Grafana con autenticación o VPN.
- Almacena las claves SSH y tokens en `GitHub Secrets` y no en el repo.

**Notas adicionales**
- Si cambias el stack a Java/Spring Boot o a Gradle, puedo actualizar el workflow para usar `actions/setup-java` y `mvn`/`gradle`.
- Si prefieres que Prometheus descubra contenedores por nombre, cambia `docker-compose` para usar una red común en lugar de `network_mode: host` y actualiza las reglas de scraping.

**Contacto / Próximos pasos**
- Puedo actualizar automáticamente el `Dockerfile` en `app/`, ajustar el mapping de puertos en `/.github/workflows/ci-cd.yml`, o añadir provisioning de Datasource/Dashboards en Grafana.
- Indícame qué prefieres: mantener `3080:3050` (actual CI), o mover a `3050:3050` (exponer 3050 en host).