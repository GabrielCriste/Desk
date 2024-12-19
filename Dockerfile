# Usar a imagem base apropriada
FROM ubuntu:20.04

# Configurar argumentos para selecionar o servidor VNC
ARG vncserver=tigervnc

# Definir ambiente não interativo para evitar prompts do apt
ENV DEBIAN_FRONTEND=noninteractive

# Atualizar pacotes e instalar dependências básicas
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    wget \
    curl \
    gnupg \
    python3 \
    python3-pip \
    build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instalar o servidor VNC dependendo do argumento fornecido
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Instalando TigerVNC"; \
        apt-get update -y && \
        apt-get install -y --no-install-recommends \
        tigervnc-standalone-server && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "${vncserver}" = "turbovnc" ]; then \
        echo "Instalando TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor > /etc/apt/trusted.gpg.d/TurboVNC.gpg && \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list && \
        apt-get update -y && \
        apt-get install -y --no-install-recommends \
        turbovnc && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    else \
        echo "Servidor VNC inválido: ${vncserver}"; \
        exit 1; \
    fi

# Instalar e configurar o websockify
RUN pip3 install -U websockify==0.9.0 && \
    ln -s /usr/lib/websockify/rebind.so /usr/local/lib/

# Outras instruções necessárias (substituir conforme necessário)
# EXPOSE <porta>
# CMD ["<comando_principal>"]
