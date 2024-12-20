# Base Image
FROM quay.io/jupyter/base-notebook:2024-12-02

# Executar comandos como root inicialmente
USER root

# Atualizar pacotes e instalar dependências básicas
RUN apt-get -y -qq update && \
    apt-get -y -qq install \
        dbus-x11 \
        xclip \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu && \
    apt-get -y -qq remove xfce4-screensaver && \
    mkdir -p /opt/install /srv/conda && \
    chown -R $NB_UID:$NB_GID $HOME /opt/install /srv/conda && \
    rm -rf /var/lib/apt/lists/*

# Instalar um servidor VNC (TigerVNC ou TurboVNC)
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Instalando TigerVNC"; \
        apt-get -y -qq update; \
        apt-get -y -qq install tigervnc-standalone-server; \
        rm -rf /var/lib/apt/lists/*; \
    fi

ENV PATH=/opt/TurboVNC/bin:$PATH
RUN if [ "${vncserver}" = "turbovnc" ]; then \
        echo "Instalando TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
        apt-get -y -qq update; \
        apt-get -y -qq install turbovnc; \
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
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml

# Instalar dependências adicionais e ajustar permissões
COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=22" && \
    pip install /opt/install

# Configuração do usuário
USER $NB_USER

# Configurar o diretório de trabalho
WORKDIR /home/$NB_USER

# Entrypoint padrão e comando inicial
ENTRYPOINT ["/usr/local/bin/repo2docker-entrypoint"]
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
