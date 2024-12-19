FROM quay.io/jupyter/base-notebook:2024-12-02

USER root

# Instalar dependências necessárias
RUN apt-get -y -qq update && \
    apt-get -y -qq install \
        dbus-x11 \
        xclip \
        xsel \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
        curl \
        wget \
        gnupg2 \
        lsb-release \
        ca-certificates \
        chromium \
        firefox && \
    apt-get -y -qq remove xfce4-screensaver && \
    mkdir -p /opt/install && \
    chown -R $NB_UID:$NB_GID $HOME /opt/install && \
    rm -rf /var/lib/apt/lists/*

# Instalar servidor VNC
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Installing TigerVNC"; \
        apt-get -y -qq update && \
        apt-get -y -qq install tigervnc-standalone-server && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Instalar TurboVNC (opcional)
ENV PATH=/opt/TurboVNC/bin:$PATH
RUN if [ "${vncserver}" = "turbovnc" ]; then \
        echo "Installing TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg && \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list && \
        apt-get -y -qq update && \
        apt-get -y -qq install turbovnc && \
        rm -rf /var/lib/apt/lists/*; \
    fi

USER $NB_USER

# Clonar dois repositórios
RUN git clone https://github.com/jupyterhub/jupyter-remote-desktop-proxy.git /opt/install/repo1 && \
    git clone <URL_DO_SEGUNDO_REPOSITORIO> /opt/install/repo2

# Combinar os arquivos necessários
RUN cp -r /opt/install/repo2/* /opt/install/repo1/

# Atualizar ambiente Conda
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml

# Instalar pacotes do repositório combinado
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=22" && \
    pip install /opt/install/repo1
    
