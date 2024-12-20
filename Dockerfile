# Base Image
FROM jupyter/minimal-notebook:latest

# Definição de ARGs e ENV
ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=100
ENV NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    HOME=/home/${NB_USER}

USER root

# Instalar pacotes básicos e limpar cache do apt
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    git \
    build-essential \
    python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Mamba para gerenciar o Conda
RUN wget -qO /tmp/micromamba.tar.bz2 https://micromamba.snakepit.net/api/micromamba/linux-64/latest && \
    tar -xvjf /tmp/micromamba.tar.bz2 -C /usr/local/bin --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2

ENV PATH="/usr/local/bin:${PATH}"

# Copiar environment.yml e criar ambiente Conda
COPY --chown=${NB_UID}:${NB_GID} environment.yml /tmp/environment.yml

RUN micromamba install -y --name base -f /tmp/environment.yml && \
    micromamba clean -a -y && \
    rm /tmp/environment.yml

# Ajuste de permissões
RUN fix-permissions /home/${NB_USER}

# Definir o usuário padrão para execução
USER ${NB_USER}

# Definir diretório de trabalho
WORKDIR ${HOME}

# Comando inicial
CMD ["start-notebook.sh"]
