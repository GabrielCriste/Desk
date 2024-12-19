FROM quay.io/jupyter/base-notebook:2024-12-02

USER root

# Atualizar pacotes e instalar dependências necessárias
RUN apt-get -y -qq update \
 && apt-get -y -qq install \
        dbus-x11 \
        xclip \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
        curl \
        lxde \
        net-tools \
        novnc \
        tigervnc-standalone-server \
    # Desabilitar bloqueio automático de tela e limpar cache
 && apt-get -y -qq remove xfce4-screensaver \
 && mkdir -p /opt/install \
 && chown -R $NB_UID:$NB_GID $HOME /opt/install \
 && rm -rf /var/lib/apt/lists/*

# Instalar servidor VNC adicional (TurboVNC ou TigerVNC)
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Instalando TigerVNC"; \
        apt-get -y -qq update; \
        apt-get -y -qq install \
            tigervnc-standalone-server \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "${vncserver}" = "turbovnc" ]; then \
        echo "Instalando TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
        apt-get -y -qq update; \
        apt-get -y -qq install \
            turbovnc \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Instalar e configurar ambiente Python
RUN apt-get install -y -q python-pip && \
    pip install -U websockify==0.9.0 && \
    ln -s /usr/lib/websockify/rebind.so /usr/local/lib/

# Corrigir noVNC para conexão automática
ADD websocket-path-ui-js.patch /usr/share/novnc/include
RUN cd /usr/share/novnc/include/ && \
    patch -p0 < websocket-path-ui-js.patch

USER $NB_USER

# Instalar dependências Python do projeto
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml

COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=22" && \
    pip install /opt/install
    
