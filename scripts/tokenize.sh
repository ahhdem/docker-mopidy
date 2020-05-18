#!/bin/bash

ICECAST_HOST=${ICECAST_HOST:-icecast}
ICECAST_MOUNT=${ICECAST_MOUNT:-live}
ICECAST_PASSWORD=${ICECAST_PASSWORD:-mopidy}
ICECAST_PORT=${ICECAST_PORT:-8000}
ICECAST_STREAMNAME=${ICECAST_STREAMNAME:-'miradio'}

TMPDIR=$(mktemp -d)

function icecast_tokenize() {
  local _file=$1

  # Tokenize
  sed -i'' \
    -e "s/ICECAST_HOST/${ICECAST_HOST}/g" \
    -e "s/ICECAST_MOUNT/${ICECAST_MOUNT}/g" \
    -e "s/ICECAST_PASSWORD/${ICECAST_PASSWORD}/g" \
    -e "s/ICECAST_PORT/${ICECAST_PORT}/g" \
    -e "s^ICECAST_STREAMNAME^${ICECAST_STREAMNAME}^g" \
    ${TMPDIR}/${_config}
}

function initConfig() {
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
        icecast_tokenize $_config
      fi
    ;;
  esac

  # Copy config to volume location
  cp ${TMPDIR}/${_config} /config
  chmod 600 /config/${_config}
}

for conf in mopidy.conf; do
  initConfig $conf
done

rm -rf $TMPDIR
