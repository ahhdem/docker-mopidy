#!/bin/bash
PLAYLISTS=($1)
MEDIA_DIR=/var/lib/mopidy/media
PLAYLIST_DIR=/var/lib/mopidy/playlists

playlist=$(shuf -i 0-${#PLAYLISTS[@]} -n 1)
pushd $PLAYLIST_DIR
song=$(shuf ${PLAYLISTS[$playlist]}.m3u -n 1)
echo "${MEDIA_DIR}/${song}"
