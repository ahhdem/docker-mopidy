FROM debian:buster-slim
ENV DEBIAN_FRONTEND noninteractive

COPY etc /etc
COPY scripts /

EXPOSE 6600 6680 5555/udp

VOLUME ["/var/lib/mopidy/local", "/var/lib/mopidy/media"]


RUN set -ex \
    # Official Mopidy install for Debian/Ubuntu along with some extensions
    # (see https://docs.mopidy.com/en/latest/installation/debian/ )
 && apt-get update \
 && apt-get install -y \
        git \
        curl \
        dumb-init \
        gcc \
        git \
        gnupg \
        gstreamer1.0-alsa \
        gstreamer1.0-plugins-bad \
        mp3val \
        procps \
        python3 \
        python3-crypto \
        python3-pip \
        apt-transport-https \
        ca-certificates \
 && curl -L https://apt.mopidy.com/mopidy.gpg | apt-key add - \
 && curl -L https://apt.mopidy.com/mopidy.list -o /etc/apt/sources.list.d/mopidy.list \
 && mv /etc/apt/sources.list /etc/apt/sources.list.d/stable.list

RUN apt-get update \
 && apt-get install -y \
        lame \
        ezstream \
        mopidy \
        mopidy-soundcloud \
        mopidy-spotify \
 && pip3 install -U six pyasn1 requests[security] cryptography git+http://github.com/ahhdem/bassdrive-mopidy \
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
        pyopenssl \
        youtube-dl \
 && mkdir -p /var/lib/mopidy/.config \
 && ln -s /config /var/lib/mopidy/.config/mopidy \
    # Clean-up
 && apt-get purge --auto-remove -y \
        git \
        curl \
        gcc \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

# Allows any user to run mopidy, but runs by default as a randomly generated UID/GID.
ENV HOME=/var/lib/mopidy
RUN set -ex \
 && usermod -G audio,sudo mopidy \
 && chown mopidy:audio -R $HOME /entrypoint.sh /etc/mopidy.conf /etc/ezstream.xml /playlist.sh \
 && chmod 0770 /playlist.sh \
 && chmod go+rwx -R $HOME /entrypoint.sh /tokenize.sh

# Runs as mopidy user by default.
USER mopidy
ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["/usr/bin/mopidy"]
