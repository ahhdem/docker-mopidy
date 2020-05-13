FROM debian:buster-slim

COPY config/stable.pref /etc/apt/preferences.d/stable.pref
COPY config/testing.pref /etc/apt/preferences.d/testing.pref

COPY config/testing.list /etc/apt/sources.list.d/testing.list


RUN set -ex \
    # Official Mopidy install for Debian/Ubuntu along with some extensions
    # (see https://docs.mopidy.com/en/latest/installation/debian/ )
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        dumb-init \
        gcc \
        gnupg \
        gstreamer1.0-alsa \
        gstreamer1.0-plugins-bad \
        liquidsoap \
        python3 \
        python3-crypto \
        python3-pip \
        apt-transport-https \
        ca-certificates \
 && apt-cache policy python3-pykka \
 && curl -L https://apt.mopidy.com/mopidy.gpg | apt-key add - \
 && curl -L https://apt.mopidy.com/mopidy.list -o /etc/apt/sources.list.d/mopidy.list \
 && mv /etc/apt/sources.list /etc/apt/sources.list.d/stable.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ezstream \
        mopidy \
        mopidy-soundcloud \
        mopidy-spotify \
 && pip3 install -U six pyasn1 requests[security] cryptography \
 && pip3 install \
        Mopidy-Iris \
        Mopidy-Moped \
        Mopidy-GMusic \
        Mopidy-InternetArchive \
        Mopidy-Pandora \
        Mopidy-YouTube \
        Mopidy-Scrobbler \
        Mopidy-SomaFM \
        Mopidy-Bassdrive \
        Mopidy-Party \
        Mopidy-Podcast \
        Mopidy-Mowecl \
        pyopenssl \
        youtube-dl \
 && mkdir -p /var/lib/mopidy/.config \
 && ln -s /config /var/lib/mopidy/.config/mopidy \
    # Clean-up
 && apt-get purge --auto-remove -y \
        curl \
        gcc \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

# Start helper script.
COPY entrypoint.sh /entrypoint.sh
COPY tokenize.sh /tokenize.sh
COPY playlist.sh /playlist.sh

# Default configuration.
COPY config/mopidy.conf /config/mopidy.conf
COPY config/ezstream.xml /config/ezstream.xml

# Copy the pulse-client configuratrion.
COPY config/pulse-client.conf /etc/pulse/client.conf

# Allows any user to run mopidy, but runs by default as a randomly generated UID/GID.
ENV HOME=/var/lib/mopidy
RUN set -ex \
 && usermod -G audio,sudo mopidy \
 && chown mopidy:audio -R $HOME /entrypoint.sh \
 && chmod go+rwx -R $HOME /entrypoint.sh /playlist.sh /tokenize.sh

# Runs as mopidy user by default.
USER mopidy

VOLUME ["/var/lib/mopidy/local", "/var/lib/mopidy/media"]

EXPOSE 6600 6680 5555/udp

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["/usr/bin/mopidy"]
