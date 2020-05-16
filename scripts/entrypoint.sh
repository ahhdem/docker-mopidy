#!/usr/bin/dumb-init /bin/bash

LOG_ROOT=${LOG_ROOT:-/config/}
BAD_SONG_LOG=${BAD_SONG_LOG:-${LOG_ROOT}/bad_songs.log}
MISSING_SONG_LOG=${MISSING_SONG_LOG:-${LOG_ROOT}/missing_songs.log}
FILE_REPAIR_LOG=${FILE_REPAIR_LOG:-${LOG_ROOT}/file_repair.log}
FAILED_REPAIR_LOG=${FAILED_REPAIR_LOG:-${LOG_ROOT}/failed_repair.log}

if [ -z "$PULSE_COOKIE_DATA" ]; then
    echo -ne $(echo $PULSE_COOKIE_DATA | sed -e 's/../\\x&/g') >$HOME/pulse.cookie
    export PULSE_COOKIE=$HOME/pulse.cookie
fi

# EZstreamer (via playlist.sh), will log files not detected as audio to BAD_SONG_LOG
# TODO: support multiple streams defined by input variables
# Name of streams to setup
# i.e. AUTOSTREAMS="radio commercials"
# Playlists to randomize
# AUTOSTREAM_RADIO_PLAYLISTS="classicrock electronic incoming"
# AUTOSTERAM_COMMERCIALS_PLAYLISTS="commercials"

# Add badsong support to each stream? === refactor how it works significantly?
function ezstreamer() {
  [ ! -e $BAD_SONG_LOG ] && touch $BAD_SONG_LOG
  tail -f $BAD_SONG_LOG&
  while true; do
    ezstream -c /config/ezstream.xml&
    local _pid=$!
    # Drop pid to issue signals to (SIGUSR1 -> next track)
    echo $_pid > /tmp/ezstream.pid
    # Resume waiting for ezstream
    tail --pid $_pid -f /dev/null
  done
}

function fixBadSongs() {
  [ ! -e $FAILED_REPAIR_LOG ] && touch $FAILED_REPAIR_LOG
  tail -f $FAILED_REPAIR_LOG&
  # Every 5 mins
  while sleep 300; do
    # Cycle through the mp3 files in the BAD_SONG_LOG
    for song in $(grep -i mp3 $BAD_SONG_LOG); do
      if [ -e "$song" ]; then
        # Preserve timestamp
        local _mtime=$(stat -c %y "$song");
        echo "Trying to repair: ${song}"
        mp3val "$song" -f || {
          # Add to FAILED_REPAIR_LOG on error
          echo "Failed to repair: $song - See ${FILE_REPAIR_LOG} for more details" >>$FAILED_REPAIR_LOG;
        }
        # Restore timestamp
        touch -d "$_mtime" "$song"
      else
        echo "Missing: $song" >>$MISSING_SONG_LOG
      fi
      # Remove from BAD_SONG_LOG so we dont repeatedly try to repair
      sed -i'' -e "/^$(echo $song |sed -e 's/[]\/$*.^[]/\\&/g')/d" ${BAD_SONG_LOG}
    done
  done
}

if [ -n "$USE_EZSTREAM" ]
then
  /tokenize.sh
  ezstreamer&
  # Periodically check BAD_SONG_LOG and attempt to repair mp3 files
  fixBadSongs 2>&1 >>${FILE_REPAIR_LOG}&
  tail -f ${FILE_REPAIR_LOG}&
fi

exec "$@"
