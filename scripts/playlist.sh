#!/bin/bash

PLAYLISTS=($EZSTREAM_PLAYLISTS)
MEDIA_DIR=${MEDIA_DIR:-/var/lib/mopidy/media}
PLAYLIST_DIR=${PLAYLIST_DIR:-/var/lib/mopidy/playlists}

until [ -e "$song" ] && (file --mime-type "$song" |grep audio >/dev/null); do
  [ -n "$song" ] && echo "Skipping $song" >> /config/bad_songs.log;
  song="${MEDIA_DIR}/$(shuf ${PLAYLIST_DIR}/${PLAYLISTS[$RANDOM % ${#PLAYLISTS[@]}]}.m3u -n 1)"
done

echo "${song}"
