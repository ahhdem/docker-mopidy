#!/bin/bash
PLAYLISTS=($EZSTREAM_PLAYLISTS)
MEDIA_DIR=/var/lib/mopidy/media
PLAYLIST_DIR=/var/lib/mopidy/playlists

playlist=$(shuf -i 0-${#PLAYLISTS[@]} -n 1)
song=$(shuf ${PLAYLIST_DIR}/${PLAYLISTS[$playlist]}.m3u -n 1)
echo "${MEDIA_DIR}/${song}"
