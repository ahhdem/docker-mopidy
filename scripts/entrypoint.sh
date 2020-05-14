#!/usr/bin/dumb-init /bin/bash

BAD_SONG_LOG=${BAD_SONG_LOG:-/config/bad_songs.log}
MISSING_SONG_LOG=${MISSING_SONG_LOG:-/config/missing_songs.log}
FILE_REPAIR_LOG=${FILE_REPAIR_LOG:-/config/file_repair.log}
FAILED_REPAIR_LOG=${FAILED_REPAIR_LOG:-/config/failed_repair.log}

if [ -z "$PULSE_COOKIE_DATA" ]; then
    echo -ne $(echo $PULSE_COOKIE_DATA | sed -e 's/../\\x&/g') >$HOME/pulse.cookie
    export PULSE_COOKIE=$HOME/pulse.cookie
fi

function ezstreamer() {
  while true; do
    ezstream -c /config/ezstream.xml
  done
}

function fixBadSongs() {
  # Every 5 mins
  while sleep 300; do
    # Cycle through the mp3 files in the bad song log
    for song in $(grep -i mp3 $BAD_SONG_LOG); do
      if [ -e "$song" ]; then
        # Preserver timestamp
        local _mtime=$(stat -c %y "$song");
        # Try to repair file
        mp3val "$song" -f || {
          # Add to FAILED_REPAIR_LOG on error
          echo "$song" >>$FAILED_REPAIR_LOG;
        }
        # Restore timestamp
        touch -d "$_mtime" "$song"
      else
        echo "$song" >>$MISSING_SONG_LOG
      fi
      # Remove from BAD_SONG_LOG so we dont repeatedly try to repair
      sed -i'' -e "s|$(echo $song |sed -e 's/[]\/$*.^[]/\\&/g')|d" ${BAD_SONG_LOG}
    }
}

if [ -n "$USE_EZSTREAM" ]
then
  /tokenize.sh
  # EZstreamer using playlist.sh, will log files not detected as audio to BAD_SONGLOG
  ezstreamer&
  # Periodically check BAD_SONG_LOG and attempt to repair mp3 files
  fixBadSongs 2>&1 >>${FILE_REPAIR_LOG}&
fi

exec "$@"
