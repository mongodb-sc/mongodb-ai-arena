# linuxserver/openvscode-server based image
# VS Code binary: /app/openvscode-server/bin/openvscode-server
# Runtime user:   abc (UID/GID controlled via PUID/PGID env vars at runtime)
# Config/data:    /config
ARG OPENVSCODE_VERSION=1.109.5

FROM lscr.io/linuxserver/openvscode-server:${OPENVSCODE_VERSION}

ARG REPO_NAME=mongodb-ai-arena
ARG REPO_URL=https://github.com/mongodb-sc/${REPO_NAME}
ARG REPO_BRANCH=main

# Declare ARG variables after FROM to make them available in build stages
ARG NODE_VERSION=24
ARG NPM_VERSION=12.0.2
ARG PYTHON_VERSION=3.12
ARG JAVA_VERSION=21
ARG MONGODB_MCP_VERSION=2.1.0
ARG MONGOSH_VERSION=2.10.0
ARG AGENT_SKILLS_VERSION=v1.1.0

# Set environment variable to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64

# Pre-seed CODE_ARGS so the linuxserver s6 run script picks up --disable-workspace-trust
# (the run script appends the connection-token arg on top of this value)
ENV CODE_ARGS="--disable-workspace-trust"

# Install basic tools and dependencies
RUN apt-get update -qq && apt-get install -y -qq \
    apt-utils \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -qq && apt-get install -y -qq \
    curl \
    wget \
    gnupg \
    software-properties-common \
    git \
    less \
    vim \
    net-tools \
    lsof \
    jq \
    unzip \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y -qq nodejs \
    && rm -rf /var/lib/apt/lists/*

# Upgrade npm and install MongoDB MCP Server globally
RUN npm install -g npm@${NPM_VERSION}

RUN npm install -g mongodb-mcp-server@${MONGODB_MCP_VERSION}

# Install Python from deadsnakes PPA
RUN apt-get update -qq && apt-get install -y -qq \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update -qq \
    && apt-get install -y -qq \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    python${PYTHON_VERSION}-dev \
    && rm -rf /var/lib/apt/lists/*

# Install pip for Python
# --break-system-packages is required on Ubuntu Noble (PEP 668)
RUN wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py \
    && python${PYTHON_VERSION} get-pip.py --break-system-packages \
    && rm get-pip.py

# Set Python as default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1

# Install uv (Python package manager)
# UV_INSTALL_DIR avoids relying on $HOME (/config), which does not exist at build time
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# Install Java (headless version for smaller footprint)
RUN apt-get update -qq && apt-get install -y -qq \
    openjdk-${JAVA_VERSION}-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# Install mongosh
RUN wget -q -P /tmp https://downloads.mongodb.com/compass/mongodb-mongosh_${MONGOSH_VERSION}_amd64.deb \
    && dpkg -i /tmp/mongodb-mongosh_${MONGOSH_VERSION}_amd64.deb \
    && apt-get install -f -y -qq \
    && rm -f /tmp/mongodb-mongosh_${MONGOSH_VERSION}_amd64.deb

# Install VS Code extensions at build time
# Runtime extensions dir is /config/.openvscode-server/extensions (confirmed from server logs)
RUN mkdir -p /config/.openvscode-server/extensions /config/.openvscode-server/data && \
    for ext in \
        mongodb.mongodb-vscode \
        humao.rest-client \
        saoudrizwan.claude-dev \
    ; do \
        /app/openvscode-server/bin/openvscode-server \
            --install-extension "${ext}" \
            --extensions-dir /config/.openvscode-server/extensions \
            --user-data-dir /config/.openvscode-server/data; \
    done

# Bake VS Code machine-scoped settings into the user-data-dir AFTER installing extensions.
# openvscode-server stores User settings in the browser (localStorage), NOT on disk.
# Machine/settings.json IS read from disk server-side, so this is the reliable way
# to enforce settings like security.workspace.trust.enabled=false at startup.
# Settings are placed AFTER --install-extension because the install step re-initialises
# the user-data-dir and would overwrite any Machine/settings.json placed before it.
# See: https://github.com/gitpod-io/openvscode-server/issues/535
RUN mkdir -p /config/.openvscode-server/data/Machine
COPY settings.json /config/.openvscode-server/data/Machine/settings.json
COPY settings.json /opt/prebaked/vscode-settings.json

# Bake a Cline Global Rule restricting answers to workshop / MongoDB scope.
# claude-dev 3.84.0 scans $HOME/Cline/Rules/*.md for global rules ($HOME=/config for user abc).
RUN mkdir -p /config/Cline/Rules
COPY cline-rules/workshop-scope.md /config/Cline/Rules/workshop-scope.md
RUN chown -R 1000:1000 /config/Cline

# =============================================================================
# Pre-bake: repository + dependencies into /opt/prebaked/
# Using /opt/prebaked/ keeps the cache visible even when the PVC is mounted
# at /home/workspace. user_operations.sh seeds the workspace from here on
# first start (avoids full clone), then git pulls only the delta.
# =============================================================================

# MongoDB agent skills for Cline (.cline/skills seeded to workspace at runtime)
RUN git clone --depth 1 --branch ${AGENT_SKILLS_VERSION} https://github.com/mongodb/agent-skills.git /tmp/agent-skills && \
    mkdir -p /opt/prebaked/.cline/skills && \
    cp -r /tmp/agent-skills/skills/. /opt/prebaked/.cline/skills/ && \
    rm -rf /tmp/agent-skills

# Task 1: Clone repository into the pre-bake cache
RUN git clone -b ${REPO_BRANCH} ${REPO_URL} /opt/prebaked/${REPO_NAME}

# Task 4: Dummy backend .env — overwritten at runtime with real Atlas credentials
RUN printf 'PORT=5000\nMONGODB_URI=mongodb+srv://PLACEHOLDER:PLACEHOLDER@PLACEHOLDER/?retryWrites=true&w=majority\nDATABASE_NAME=PLACEHOLDER\n' \
    > /opt/prebaked/${REPO_NAME}/server/.env

# Task 2: Pre-install server dependencies and save package.json checksum
RUN cd /opt/prebaked/${REPO_NAME}/server && \
    npm install --legacy-peer-deps && \
    md5sum package.json > node_modules/.package-checksum

# Task 3: Pre-install and pre-build frontend with dummy .env
# BACKEND_URL is a placeholder — runtime rewrites .env and rebuilds with real URL
RUN cd /opt/prebaked/${REPO_NAME}/app && \
    printf 'WORKSHOP_USER=/app\nBACKEND_URL=https://PLACEHOLDER/backend\n' > .env && \
    npm install --legacy-peer-deps && \
    md5sum package.json > node_modules/.package-checksum && \
    npm run build

# Ensure the runtime user (abc) can read and write the cache.
#
# NOTE: PUID/PGID only remap abc's uid/gid via the base image's own s6-overlay
# entrypoint. The Helm chart's initContainer (workspace-setup) overrides the
# entrypoint with its own "command", so that remapping never runs there — abc
# keeps whatever uid/gid is baked into this image (linuxserver default, NOT
# necessarily 1000:1000). Chown by name, not numeric id, so this stays correct
# regardless of what that baked-in uid/gid is.
RUN chown -R abc:abc /opt/prebaked

# All npm/pip/uv/extension-install commands above run as root during the build, and
# since the base image sets HOME=/config, their caches (notably npm's at /config/.npm,
# plus /config/.openvscode-server extensions/data) end up root-owned. At runtime abc
# runs "npm install" (see above), so a later run in user_operations.sh fails with
# EACCES on those root-owned cache files. Recursively reclaim /config here.
RUN chown -R abc:abc /config
