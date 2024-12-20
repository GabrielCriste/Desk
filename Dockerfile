# Base Image
FROM quay.io/jupyter/base-notebook:2024-12-02

# Executar comandos como root inicialmente
USER root

# Atualizar pacotes e instalar dependências básicas
RUN apt-get -y update && apt-get -y install --no-install-recommends \
    dbus-x11 \
    xclip \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xorg \
    xubuntu-icon-theme \
    fonts-dejavu \
    wget \
    gnupg && \
    apt-get -y remove xfce4-screensaver && \
    rm -rf /var/lib/apt/lists/*

# Instalar um servidor VNC (TigerVNC ou TurboVNC)
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Instalando TigerVNC"; \
        apt-get update && apt-get -y install tigervnc-tools && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "${vncserver}" = "turbovnc" ]; then \
        echo "Instalando TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor -o /etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        echo "deb https://packagecloud.io/dcommander/turbovnc/ubuntu/ focal main" > /etc/apt/sources.list.d/TurboVNC.list; \
        apt-get update && apt-get -y install turbovnc && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Configurar o locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Definir variáveis de ambiente
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8
ENV CONDA_DIR=/srv/conda NB_PYTHON_PREFIX=${CONDA_DIR}/envs/notebook
ENV PATH=${NB_PYTHON_PREFIX}/bin:${CONDA_DIR}/bin:${PATH}

# Copiar e instalar o ambiente Conda
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp/environment.yml
RUN mamba env update --quiet --name base --file /tmp/environment.yml && \
    mamba clean -a -y

# Instalar dependências adicionais e ajustar permissões
COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN mamba install -y -q "nodejs>=22" && pip install /opt/install

# Configuração do usuário
USER $NB_USER

# Configurar o diretório de trabalho
WORKDIR /home/$NB_USER

# Entrypoint padrão e comando inicial
ENTRYPOINT ["/usr/local/bin/repo2docker-entrypoint"]
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
