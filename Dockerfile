# Etapa 1: Base da imagem Jupyter
FROM quay.io/jupyter/base-notebook:2024-12-02

# Etapa 2: Definir o usuário root para permissões administrativas
USER root

# Etapa 3: Instalar dependências do sistema
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
        firefox \
        git && \
    apt-get -y -qq remove xfce4-screensaver && \
    mkdir -p /opt/install && \
    chown -R $NB_UID:$NB_GID $HOME /opt/install && \
    rm -rf /var/lib/apt/lists/*

# Etapa 4: Instalar servidor VNC
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Instalando TigerVNC"; \
        apt-get -y -qq update && \
        apt-get -y -qq install tigervnc-standalone-server && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Etapa 5: Instalar TurboVNC (opcional)
ENV PATH=/opt/TurboVNC/bin:$PATH
RUN if [ "${vncserver}" = "turbovnc" ]; then \
        echo "Instalando TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg && \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list && \
        apt-get -y -qq update && \
        apt-get -y -qq install turbovnc && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Etapa 6: Trocar para o usuário padrão do Jupyter
USER $NB_USER

# Etapa 7: Clonar os repositórios necessários
RUN git clone https://github.com/jupyterhub/jupyter-remote-desktop-proxy.git /opt/install/repo1 && \
    git clone https://github.com/sbrunk/storch.git /opt/install/repo2

# Etapa 8: Combinar arquivos dos repositórios
RUN cp -r /opt/install/repo2/* /opt/install/repo1/

# Etapa 9: Adicionar o arquivo environment.yml
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp

# Etapa 10: Atualizar o ambiente Conda
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml

# Etapa 11: Instalar pacotes do repositório combinado
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=22" && \
    pip install /opt/install/repo1
    
