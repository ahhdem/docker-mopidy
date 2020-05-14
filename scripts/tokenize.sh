#!/bin/bash

ICECAST_HOST=${ICECAST_HOST:-icecast}
ICECAST_PASSWORD=${ICECAST_PASSWORD:-mopidy}
ICECAST_MOUNT=${ICECAST_MOUNT:-live}
ICECAST_EZSTREAM_MOUNT=${ICECAST_EZSTREAM_MOUNT:-fallback}
ICECAST_STREAM_URL=${ICECAST_STREAM_URL:-'http://icecast'}
EZSTREAM_PLAYLISTS=${EZSTREAM_PLAYLISTS:-'rock hip-hop'}

TMPDIR=$(mktemp -d)

# Copy untokenized configs frmo protected area
cp /etc/ezstream.xml ${TMPDIR}
# Tokenize
sed -i'' \
  -e "s/ICECAST_HOST/${ICECAST_HOST}/g" \
  -e "s/ICECAST_PASSWORD/${ICECAST_PASSWORD}/g" \
  -e "s/ICECAST_MOUNT/${ICECAST_MOUNT}/g" \
  -e "s^ICECAST_STREAM_URL^${ICECAST_STREAM_URL}^g" \
  -e "s/ICECAST_EZSTREAM_MOUNT/${ICECAST_EZSTREAM_MOUNT}/g" \
  -e "s/GENRE_LIST/${EZSTREAM_PLAYLISTS}/g" \
  ${TMPDIR}/ezstream.xml

# Don't replace a potentially user-created config 
[ ! -f /config/ezstream.xml ] && cp ${TMPDIR}/ezstream.xml /config
chmod 600 /config/ezstream.xml

# Repeat
cp /etc/mopidy.conf ${TMPDIR}
if [ -n "$USE_ICECAST" ]; then
  sed -i'' \
    -e 's|^output.*$|output = lamemp3enc ! shout2send mount=${ICECAST_MOUNT} ip=${ICECAST_HOST} port=8000 password=${ICECAST_PASSWORD}|' \
    ${TMPDIR}/mopidy.conf
fi

[ ! -f /config/mopidy.conf ] && cp ${TMPDIR}/mopidy.conf /config
chmod 600 /config/mopidy.conf
