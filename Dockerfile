FROM python:3.8-slim-buster
ENV DEBIAN_FRONTEND noninteractive

COPY etc /etc
COPY scripts /

EXPOSE 6600 6680 5555/udp

VOLUME ["/var/lib/mopidy/local", "/var/lib/mopidy/media"]

RUN set -ex \
 && apt-get update \
 && apt-get install -y \
    git \
    curl \
    dumb-init \
    deborphan \
    gcc \
    git \
    gnupg \
    mp3val \
    procps \
    python3-crypto \
    apt-transport-https \
    ca-certificates \
  # Official Mopidy install for Debian/Ubuntu along with some extensions
  # (see https://docs.mopidy.com/en/latest/installation/debian/ )
 && pip3 install -U six pyasn1 pyopenssl requests[security] cryptography xmltodict git+http://github.com/ahhdem/mopidy-bassdrive.git \
 && python -c "import requests; print(requests.get('https://apt.mopidy.com/mopidy.gpg').text)" | apt-key add - \
 && python -c "import requests; print(requests.get('https://apt.mopidy.com/mopidy.list').text)" > /etc/apt/sources.list.d/mopidy.list \
 && apt-get update \
 && apt-get install -y \
    gstreamer1.0-plugins-good \ 
    mopidy \
    mopidy-soundcloud \
    mopidy-spotify \
 && pip3 install \
    Mopidy-Iris \
    Mopidy-Moped \
    Mopidy-GMusic \
    Mopidy-InternetArchive \
    Mopidy-Pandora \
    Mopidy-YouTube \
    Mopidy-Scrobbler \
    Mopidy-SomaFM \
    Mopidy-Party \
    Mopidy-Podcast \
    Mopidy-Mowecl \
    youtube-dl \
 && mkdir -p /var/lib/mopidy/.config \
 && ln -s /config /var/lib/mopidy/.config/mopidy \
  # Clean-up
 && apt-get purge --auto-remove -y \
    git \
    curl \
    gcc \
    g++ \
    build-essential \
    cpp \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

#   Allows any user to run mopidy, but runs by default as a randomly generated UID/GID.
ENV HOME=/var/lib/mopidy
RUN set -ex \
 && usermod -G audio,sudo mopidy \
 && chown mopidy:audio -R $HOME /entrypoint.sh /etc/mopidy.conf \
 && chmod go+rwx -R $HOME /entrypoint.sh

# Runs as mopidy user by default.
USER mopidy
ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["/usr/bin/mopidy"]
