# Use a imagem base oficial do Jupyter
FROM quay.io/jupyter/base-notebook:2024-12-02

# Use o usuário root para instalar dependências
USER root

# Instale as dependências adicionais necessárias
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

# Instale o servidor VNC (TigerVNC como padrão)
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        apt-get -y -qq update && \
        apt-get -y -qq install tigervnc-standalone-server && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Instale o TurboVNC (opcional)
RUN if [ "${vncserver}" = "turbovnc" ]; then \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg && \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list && \
        apt-get -y -qq update && \
        apt-get -y -qq install turbovnc && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Troque para o usuário jovyan
USER $NB_USER

# Configure o ambiente Conda a partir de um arquivo YAML
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp/
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml && \
    rm /tmp/environment.yml

# Copie os arquivos do repositório para o diretório de trabalho
COPY --chown=$NB_UID:$NB_GID src/ /home/jovyan/work/

# Defina o diretório de trabalho
WORKDIR /home/jovyan/work

# Defina o comando de inicialização padrão
CMD ["start-notebook.sh"]
