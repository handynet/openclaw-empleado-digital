# 🤖 OpenClaw – Empleado Digital Personal

Repositorio listo para desplegar [OpenClaw](https://openclaw.ai) (agente IA autónomo) con **PostgreSQL** usando **Docker Compose** o **EasyPanel**.

> **OpenClaw** es un empleado digital de código abierto que puede gestionar emails, calendarios, navegar la web, ejecutar comandos, y mucho más. Se controla vía WhatsApp, Telegram, Discord o la interfaz web.

---

## 📁 Estructura del Repo

```
openclaw-empleado-digital/
├── Dockerfile              # Imagen custom con herramientas de desarrollo
├── docker-compose.yml      # OpenClaw + PostgreSQL (para deploy local)
├── .env.example            # Variables de entorno (copiar a .env)
├── .gitignore              # Excluye .env y archivos temporales
├── .dockerignore           # Excluye docs del build context
├── SYSTEM_PROMPT.md        # Prompt de sistema recomendado para el agente
└── README.md               # Esta documentación
```

---

## 🧰 Herramientas Pre-instaladas

La imagen custom incluye todo esto listo para usar por el agente:

| Herramienta | Para qué sirve |
|---|---|
| `build-essential` | Compilar paquetes C/C++ (dependencias de pip, etc.) |
| `python3` + `venv` + `dev` | Python 3 con virtualenv y headers de desarrollo |
| `git` | Control de versiones, clonar repos |
| `curl` / `wget` | Descargar archivos y hacer requests HTTP |
| `ffmpeg` | Procesar audio y video |
| **`jq`** ⭐ | Procesador JSON en línea de comandos — [recomendado oficialmente por OpenClaw](https://openclaw.ai) |
| **`pandoc`** ⭐ | Conversor universal de documentos (Markdown ↔ HTML ↔ DOCX ↔ PDF ↔ LaTeX) |
| **`poppler-utils`** ⭐ | Utilidades PDF: `pdftotext`, `pdfinfo`, `pdfimages`, `pdftohtml` |

> ⭐ = Herramientas clave validadas por la comunidad de OpenClaw.

### Ejemplos de uso rápido

```bash
# jq — Parsear respuestas JSON de APIs
curl -s https://api.example.com/data | jq '.results[0].name'

# pandoc — Convertir Markdown a DOCX
pandoc informe.md -o informe.docx

# poppler-utils — Extraer texto de un PDF
pdftotext documento.pdf documento.txt

# ffmpeg — Extraer audio de un video
ffmpeg -i video.mp4 -vn audio.mp3
```

---

## ⚡ Deploy Rápido (Local)

### 1. Clonar y configurar

```bash
git clone <URL_DE_TU_REPO> openclaw-empleado-digital
cd openclaw-empleado-digital
cp .env.example .env
```

### 2. Editar `.env`

Abrí `.env` y configurá como mínimo:

```bash
# Cambiar la contraseña de Postgres (usá algo seguro)
POSTGRES_PASSWORD=mi_password_seguro_123

# Actualizar la DATABASE_URL con la misma contraseña
DATABASE_URL=postgresql://openclaw:mi_password_seguro_123@postgres:5432/openclaw

# Tu API key del proveedor de LLM
OPENCLAW_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Construir y levantar

```bash
docker compose up -d --build
```

### 4. Acceder

Por defecto **no se exponen puertos** al host. Para acceder localmente:

**Opción A: Descomentar ports (desarrollo local)**

Editá `docker-compose.yml` y descomentá la sección `ports`:

```yaml
ports:
  - "18789:18789"
```

Luego: `docker compose up -d` y accedé a `http://localhost:18789`

**Opción B: Usar docker exec para el onboarding**

```bash
docker compose exec openclaw openclaw status
```

---

## 🚀 Deploy en EasyPanel

### Método: "Build from Repo"

1. **Subir el repo** a GitHub/GitLab (público o privado con token).

2. En EasyPanel:
   - Crear un nuevo **proyecto**.
   - Agregar un **servicio** tipo **"App"** → **"Build from Git Repository"**.
   - Ingresar la URL del repo.
   - EasyPanel detectará el `Dockerfile` y lo construirá.

3. **Agregar servicio de PostgreSQL**:
   - Dentro del mismo proyecto, agregar un servicio **"Database"** → **"PostgreSQL"**.
   - Anotar las credenciales generadas.

4. **Configurar variables de entorno** en el servicio de OpenClaw:
   ```
   DATABASE_URL=postgresql://usuario:password@nombre-servicio-postgres:5432/openclaw
   TZ=America/Argentina/Buenos_Aires
   OPENCLAW_API_KEY=tu-api-key
   OPENCLAW_PORT=18789
   ```

5. **Configurar el puerto expuesto**:
   - En la configuración del servicio OpenClaw en EasyPanel, ir a **"Domains"**.
   - El **puerto interno** (container port) es `18789`.
   - Asignar un dominio o subdominio.

6. **Configurar volúmenes** (opcional pero recomendado):
   - En el servicio OpenClaw → pestaña **"Mounts"** o **"Volumes"**.
   - Crear un volumen persistente para `/root/.openclaw` (config/memoria del agente).
   - Crear un volumen persistente para `/workspace` (archivos, venv, npm, logs).

7. **Deploy**: EasyPanel construirá la imagen y levantará el contenedor.

### Configurar Dominio y SSL

1. En el servicio de OpenClaw → pestaña **"Domains"**:
   - Agregar tu dominio: `agente.tudominio.com`
   - Container port: `18789`
2. EasyPanel genera automáticamente el certificado SSL con Let's Encrypt.
3. Apuntar el DNS (registro A o CNAME) al IP/hostname de tu servidor EasyPanel.

> **Nota sobre docker-compose.yml y EasyPanel:** EasyPanel puede usar el compose
> como referencia, pero generalmente construye desde el Dockerfile directamente.
> Si usás el compose completo, asegurate de que EasyPanel maneje el servicio
> postgres por separado (como servicio de base de datos nativo) para evitar
> conflictos.

---

## 🔒 Puertos y Networking

### ¿Por qué no se exponen puertos por defecto?

Para evitar conflictos (especialmente con el puerto 3000 que usan muchas apps)
y porque **EasyPanel usa su propio reverse proxy (Traefik)** para enrutar el
tráfico. Los contenedores se comunican entre sí por la red interna de Docker.

### ¿Cómo accedo si NO uso EasyPanel?

Descomentá la sección `ports` en `docker-compose.yml`:

```yaml
# En el servicio openclaw:
ports:
  - "${HOST_PORT:-18789}:18789"
```

O usá un port-forward temporal:

```bash
# Sin modificar el compose:
docker compose exec openclaw curl http://localhost:18789
# O un port-forward con SSH si estás en un server remoto:
ssh -L 18789:localhost:18789 usuario@tu-server
```

---

## 💾 Persistencia

### Volúmenes

| Volumen | Ruta en contenedor | Qué contiene |
|---|---|---|
| `postgres_data` | `/var/lib/postgresql/data` | Base de datos PostgreSQL |
| `openclaw_data` | `/root/.openclaw` | Configuración y memoria del agente |
| `openclaw_workspace` | `/workspace` | Archivos del usuario, venv, node, logs |

### Instalaciones persistentes del agente

El agente puede instalar paquetes que **persisten entre reinicios**:

#### Python (pip)

```bash
# El venv ya está creado en /workspace/venv
source /workspace/venv/bin/activate
pip install requests pandas numpy
```

Persistente: ✅ (el venv vive en el volumen `/workspace`)

#### Node.js (npm)

```bash
# El prefix ya está en /workspace/node via NPM_CONFIG_PREFIX
npm install -g typescript ts-node
```

Persistente: ✅ (los binarios y módulos se guardan en `/workspace/node`)

#### Paquetes del sistema (apt)

```bash
DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y <paquete>
```

Persistente: ❌ (se pierden al reiniciar el contenedor)

> Si necesitás que un paquete de sistema persista, agregalo al `Dockerfile` y
> reconstruí la imagen.

### ⛔ ¿Por qué NO persistir `/usr/local` con un volumen?

Podría parecer tentador montar `/usr/local` como volumen para que todo lo que
se instale ahí persista. **No lo hagas.** Razones:

1. **Node.js y npm viven en `/usr/local`** en la imagen base. Si montás un
   volumen vacío ahí, esas herramientas desaparecen.
2. **Actualizaciones de imagen se rompen**: Al actualizar la imagen base,
   el volumen antiguo tapa los archivos nuevos.
3. **Conflictos de arquitectura**: Si cambiás de arquitectura (x86 ↔ arm),
   los binarios del volumen no van a funcionar.

La solución correcta es usar `/workspace/venv` para Python y
`/workspace/node` para Node.js.

---

## 🛠️ Troubleshooting

### Ver logs

```bash
# Logs de OpenClaw
docker compose logs openclaw -f --tail=100

# Logs de PostgreSQL
docker compose logs postgres -f --tail=100

# Logs de todos los servicios
docker compose logs -f --tail=50
```

### Healthcheck

```bash
# Ver estado del healthcheck
docker compose ps

# Ejecutar healthcheck manualmente
docker compose exec openclaw curl -sf http://localhost:18789/ && echo "OK" || echo "FAIL"

# Estado detallado del agente
docker compose exec openclaw openclaw status --all
```

### Puertos ocupados

Si al exponer el puerto 18789 obtenés un error de "port already in use":

```bash
# Ver qué usa el puerto
# Linux/Mac:
ss -tlnp | grep 18789
# Windows:
netstat -ano | findstr 18789

# Solución: Cambiar el puerto del host en .env
HOST_PORT=18790
# Y descomentar la sección ports del compose
```

### Reiniciar limpio

```bash
# Reiniciar los contenedores (los datos persisten)
docker compose restart

# Recrear contenedores (los datos persisten)
docker compose down && docker compose up -d

# ⚠️ BORRAR TODO (incluidos los datos)
docker compose down -v
```

### El agente no conecta con la base de datos

1. Verificar que postgres esté healthy:
   ```bash
   docker compose ps postgres
   ```
2. Verificar la variable `DATABASE_URL`:
   ```bash
   docker compose exec openclaw env | grep DATABASE_URL
   ```
3. Probar conexión directa:
   ```bash
   docker compose exec postgres psql -U openclaw -d openclaw -c "SELECT 1;"
   ```

### Errores de build

```bash
# Rebuild sin cache
docker compose build --no-cache

# Si la imagen base falla, probar la imagen community:
# En Dockerfile, cambiar la primera línea a:
# FROM ghcr.io/phioranex/openclaw-docker:latest
```

---

## 📋 Prompt de Sistema

Revisá el archivo [`SYSTEM_PROMPT.md`](./SYSTEM_PROMPT.md) para un prompt de
sistema recomendado que le enseña al agente a:

- Instalar paquetes en las rutas persistentes correctas
- Usar las herramientas pre-instaladas (jq, pandoc, poppler-utils, ffmpeg)
- No romper el sistema base del contenedor
- Loguear todos los comandos ejecutados
- Pedir permiso antes de abrir puertos

---

## ⚙️ Rutas Internas – Ajustables según la Imagen

Las rutas usadas en este repo se basan en la imagen oficial
`ghcr.io/openclaw/openclaw:main`. Si tu versión usa rutas diferentes:

| Concepto | Ruta actual | Dónde ajustar |
|---|---|---|
| Config del agente | `/root/.openclaw` | `docker-compose.yml` → volumen `openclaw_data` |
| Workspace | `/workspace` | `Dockerfile` + `docker-compose.yml` |
| Puerto web | `18789` | `.env` → `OPENCLAW_PORT` + `Dockerfile` HEALTHCHECK |

> **Tip:** Ejecutá `docker compose exec openclaw ls /` para ver la estructura
> real de archivos dentro del contenedor e identificar las rutas correctas.

---

## 📊 Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                    EasyPanel / Host                  │
│                                                     │
│  ┌──────────────────┐     ┌──────────────────────┐  │
│  │   Reverse Proxy  │────▶│   openclaw :18789    │  │
│  │ (Traefik/EasyP)  │     │                      │  │
│  │  :443 (HTTPS)    │     │  ┌────────────────┐  │  │
│  └──────────────────┘     │  │  /workspace    │  │  │
│                           │  │  ├── venv/     │  │  │
│         Internet          │  │  ├── node/     │  │  │
│            │              │  │  └── logs/     │  │  │
│            ▼              │  └────────────────┘  │  │
│  agente.tudominio.com     │         │            │  │
│                           └─────────┼────────────┘  │
│                                     │               │
│                           ┌─────────▼────────────┐  │
│                           │   postgres :5432     │  │
│                           │                      │  │
│                           │  /var/lib/pg/data    │  │
│                           └──────────────────────┘  │
│                                                     │
│  Volúmenes:                                         │
│   📦 postgres_data      → DB persistente            │
│   📦 openclaw_data      → Config/memoria agente     │
│   📦 openclaw_workspace → Archivos + venv + node    │
└─────────────────────────────────────────────────────┘
```

---

## 📝 Licencia

Este repositorio de configuración es de libre uso. OpenClaw tiene su propia
licencia — consultá [github.com/openclaw/openclaw](https://github.com/openclaw/openclaw)
para detalles.
