# ============================================================
# OpenClaw – Empleado Digital Personal
# Dockerfile custom para EasyPanel / Docker Compose
# ============================================================
# Imagen base: OpenClaw oficial desde GHCR.
#   Si esta imagen deja de existir, prueba:
#     ghcr.io/phioranex/openclaw-docker:latest  (community)
#   o construye desde el repo: https://github.com/openclaw/openclaw
# ============================================================
FROM ghcr.io/phioranex/openclaw-docker:latest

# --- Cambiar a root para instalar herramientas del sistema ---
USER root


# --- Evitar prompts interactivos de apt/dpkg ---
ENV DEBIAN_FRONTEND=noninteractive

# --- Timezone ---
ENV TZ=America/Argentina/Buenos_Aires
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# --- Herramientas base para que el agente pueda compilar / instalar ---
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  python3 \
  python3-venv \
  python3-dev \
  libffi-dev \
  git \
  curl \
  wget \
  ca-certificates \
  tzdata \
  ffmpeg \
  # --- Herramientas clave validadas por la comunidad ---
  jq \
  pandoc \
  poppler-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
# jq           → procesador JSON en línea de comandos (recomendado oficialmente por OpenClaw)
# pandoc       → conversor universal de documentos (md↔html↔docx↔pdf, etc.)
# poppler-utils → utilidades PDF (pdftotext, pdfinfo, pdfimages, etc.)

# --- Directorios persistentes ---
RUN mkdir -p /root/.openclaw /workspace/venv /workspace/node /workspace/logs

# --- Pre-crear virtualenv de Python ---
RUN python3 -m venv /workspace/venv

# --- Configurar npm ---
RUN npm config set prefix /workspace/node 2>/dev/null || true

# --- Permisos: Asegurar que todo en /workspace sea accesible ---
RUN chmod -R 777 /workspace /root/.openclaw


# --- Variables de entorno para que pip/npm del agente usen el workspace ---
ENV PATH="/workspace/venv/bin:/workspace/node/bin:${PATH}"
ENV NPM_CONFIG_PREFIX="/workspace/node"

# --- Healthcheck ---
# OpenClaw UI escucha en el puerto 18789 por defecto.
# Si tu imagen usa otro puerto, ajustá la variable OPENCLAW_PORT.
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -sf http://localhost:${OPENCLAW_PORT:-18789}/ || exit 1

# --- Puerto interno ---
EXPOSE 18789

CMD ["gateway", "--port", "18789", "--allow-unconfigured"]


