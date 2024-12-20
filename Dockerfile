FROM quay.io/jupyter/base-notebook:2024-12-02

# Define variáveis de ambiente para o usuário do notebook
USER root

# Instala pacotes necessários para o VNC e XFCE4
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
    mkdir -p /opt/install && \
    chown -R $NB_UID:$NB_GID $HOME /opt/install && \
    rm -rf /var/lib/apt/lists/*

# Instala o VNC Server
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Installing TigerVNC"; \
        apt-get -y -qq update; \
        apt-get -y -qq install tigervnc-standalone-server; \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "${vncserver}" = "turbovnc" ]; then \
        echo "Installing TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
        apt-get -y -qq update; \
        apt-get -y -qq install turbovnc; \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Volta para o usuário padrão do notebook
USER $NB_USER

# Copia o arquivo `environment.yml` para instalar dependências Conda
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp/
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml && \
    rm /tmp/environment.yml

# Copia o conteúdo do diretório `src/` para o diretório de trabalho do usuário no container
COPY --chown=$NB_UID:$NB_GID src/ /home/jovyan/work/

# Adiciona o diretório ao PATH
ENV PATH="/home/jovyan/work:${PATH}"

# Define o comando padrão para iniciar o container
CMD ["start-notebook.sh"]
