#!/bin/bash

ICECAST_HOST=${ICECAST_HOST:-icecast}
ICECAST_PASSWORD=${ICECAST_PASSWORD:-mopidy}
ICECAST_MOUNT=${ICECAST_MOUNT:-live}
ICECAST_EZSTREAM_MOUNT=${ICECAST_EZSTREAM_MOUNT:-fallback}
ICECAST_STREAM_URL=${ICECAST_STREAM_URL:-'http://icecast'}
EZSTREAM_PLAYLISTS=${EZSTREAM_PLAYLISTS:-'rock hip-hop'}
CHUNEBOT_TOKEN=${CHUNEBOT_TOKEN:-'SET CHUNBOT_TOKEN ENV VAR'}

TMPDIR=$(mktemp -d)

function tokenize_config() {
  local _config=$1
  # dont overwrite an existing user config (remove it manually first)
  [ -f /config/${_config} ] && return
  # Copy untokenized configs from protected area
  cp /etc/${_config} ${TMPDIR}

  # Provide config-specific pre-tokenization manipulation
  case $_config in
    mopidy.conf)
      if [ -n "$USE_ICECAST" ]; then
        sed -i'' \
          -e 's|^output.*$|output = lamemp3enc ! shout2send mount=ICECAST_MOUNT ip=ICECAST_HOST port=ICECAST_PORT password=ICECAST_PASSWORD streamname=ICECAST_STREAMNAME|' \
          ${TMPDIR}/${_config}
      fi
    ;;
  esac

  # Tokenize
  sed -i'' \
    -e "s/ICECAST_HOST/${ICECAST_HOST}/g" \
    -e "s/ICECAST_PASSWORD/${ICECAST_PASSWORD}/g" \
    -e "s/ICECAST_MOUNT/${ICECAST_MOUNT}/g" \
    -e "s^ICECAST_STREAM_URL^${ICECAST_STREAM_URL}^g" \
    -e "s/ICECAST_EZSTREAM_MOUNT/${ICECAST_EZSTREAM_MOUNT}/g" \
    -e "s/EZSTREAM_PLAYLISTS/${EZSTREAM_PLAYLISTS}/g" \
    -e "s/GENRE_LIST/${EZSTREAM_PLAYLISTS}/g" \
    ${TMPDIR}/${_config}

  # Copy config to volume location
  cp ${TMPDIR}/${_config} /config
  chmod 600 /config/${_config}
}

sed -i'' -e "s/CHUNEBOT_TOKEN/${CHUNEBOT_TOKEN}/g" /chunebot.py

for conf in ezstream.xml mopidy.conf; do
  tokenize $conf
done

rm -rf $TMPDIR
