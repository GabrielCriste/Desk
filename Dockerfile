<<<<<<< HEAD
FROM quay.io/jupyter/base-notebook:2024-12-02

USER root

RUN apt-get -y -qq update \
 && apt-get -y -qq install \
        dbus-x11 \
        # xclip is added as jupyter-remote-desktop-proxy's tests requires it
        xclip \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
    # Disable the automatic screenlock since the account password is unknown
 && apt-get -y -qq remove xfce4-screensaver \
    # chown $HOME to workaround that the xorg installation creates a
    # /home/jovyan/.cache directory owned by root
    # Create /opt/install to ensure it's writable by pip
 && mkdir -p /opt/install \
 && chown -R $NB_UID:$NB_GID $HOME /opt/install \
 && rm -rf /var/lib/apt/lists/*

# Install a VNC server, either TigerVNC (default) or TurboVNC
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Installing TigerVNC"; \
        apt-get -y -qq update; \
        apt-get -y -qq install \
            tigervnc-standalone-server \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi
ENV PATH=/opt/TurboVNC/bin:$PATH
RUN if [ "${vncserver}" = "turbovnc" ]; then \
        echo "Installing TurboVNC"; \
        # Install instructions from https://turbovnc.org/Downloads/YUM
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
        apt-get -y -qq update; \
        apt-get -y -qq install \
            turbovnc \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi

USER $NB_USER

# Install the environment first, and then install the package separately for faster rebuilds
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml

COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=22" && \
    pip install /opt/install
=======
FROM jupyter/base-notebook

USER root
RUN apt-get update -y -q && \
    apt-get install -y -q \
        curl \
        lxde \
        net-tools \
        novnc \
        tigervnc-standalone-server

RUN apt-get install -y -q python-pip
# Force an upgrade https://github.com/novnc/noVNC/issues/1276
RUN /usr/bin/pip install -U websockify==0.9.0
# pip doesn't rebuild rebind.so though so use the old version
RUN ln -s /usr/lib/websockify/rebind.so /usr/local/lib/

# Patch novnc to automatically connect
ADD websocket-path-ui-js.patch /usr/share/novnc/include
RUN cd /usr/share/novnc/include/ && \
    patch -p0 < websocket-path-ui-js.patch

USER jovyan
# Custom jupyter-server-proxy to load vnc.html instead of /
RUN /opt/conda/bin/pip install https://github.com/manics/jupyter-server-proxy/archive/indexpage.zip
ADD jupyter_notebook_config.py /home/jovyan/.jupyter/

# websockify --web /usr/share/novnc 5901 -- vncserver -verbose -xstartup startlxde -SecurityTypes None -geometry 1024x768 -fg :1

# Both these should work:
# http://localhost:5901/vnc.html
# http://127.0.0.1:8888/lxde
>>>>>>> restore-files
