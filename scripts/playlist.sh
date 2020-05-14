#!/bin/bash

PLAYLISTS=($EZSTREAM_PLAYLISTS)
MEDIA_DIR=${MEDIA_DIR:-/var/lib/mopidy/media}
PLAYLIST_DIR=${PLAYLIST_DIR:-/var/lib/mopidy/playlists}
BAD_SONG_LOG=${BAD_SONG_LOG:-/config/bad_songs.log}

# randomly pick songs from playlist until a file that is both
# 1: existing
# 2: has valid audio file headers
# Log files that fail to meet the criteria
until [ -e "$song" ] && (file --mime-type "$song" |grep audio >/dev/null); do
  [ -n "$song" ] && echo "Skipping $song" >> $BAD_SONG_LOG
  song="${MEDIA_DIR}/$(shuf ${PLAYLIST_DIR}/${PLAYLISTS[$RANDOM % ${#PLAYLISTS[@]}]}.m3u -n 1)"
done

echo "${song}"
