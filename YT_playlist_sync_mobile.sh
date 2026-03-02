#!/bin/bash



## !!!!!!!READ HERE!!!!!!!!
## ---- DEPENDANCYS ----
# For this script to work you must have yt-dlp, ffmpeg, and mid3v2 installed!!!
# Please read the whole READ ME file before running this script, there is some important information in there

# Set music directory, YT playlist link, and a plalist name for all your songs here
MUSIC_DIR="/storage/emulated/0/Music/Music"
PLAYLIST_URL="https://music.youtube.com/playlist?list=PLDa2t4jsWyNytVVmb7R1GBuC8RKN7vgbn&si=x52NcA1vfXjU3OJy"
PLAYLIST_FILE="All_music.m3u"

## If you tun this script and it closes its self imediatly, restarting your device should sort that. It doesn't happen much, but on my raspberry pi 3B+ I had that issue a couple of times and restating it worked both times
## You'r all set to use the script now :D



# --- AUTO-TERMINAL BOX ---
if [ ! -t 0 ]; then
    lxterminal -t "Music Sync" -e "$0"
    exit
fi

# Prevent multiple instances
##LOCKFILE="/tmp/music_sync.lock"
##if [ -e "$LOCKFILE" ]; then
##    echo "Sync already in progress. Exiting."
##    exit 1
##fi
##touch "$LOCKFILE"
##trap "rm -f $LOCKFILE *.tmp online_ids.txt local_history_ids.txt; exit" INT TERM EXIT

# Force UTF-8 for Japanese/special characters
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

cd "$MUSIC_DIR"

echo "Music sync: Welcome"
echo "Do not distrobute anything you have obtained via this script!"
echo ""
sleep 1


# Storage space check
##AVAILABLE_KB=$(df . --output=avail | tail -1)
##AVAILABLE_MB=$((AVAILABLE_KB / 1024))
##echo "Storage Check: $AVAILABLE_MB MB remaining on USB."

##if [ "$AVAILABLE_MB" -lt 256 ]; then
##    echo "Music sync: LOW DISK SPACE ($AVAILABLE_MB MB). Sync cancelled."
##    exit 1
##fi

echo ""

# --- WiFi Check Logic ---
CONNECTED=false
for i in {1..6}; do
    if ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        CONNECTED=true
        break
    fi
    echo "Music sync: Waiting for WiFi... (Attempt $i)"
    sleep 5
done

echo ""

if [ "$CONNECTED" = false ]; then
    echo "Music sync: No WiFi. Music sync will not procede."
    exit 1
fi

if [ -d "$MUSIC_DIR" ]; then
    echo "Music sync: WiFi connected and checking for new music..."
    echo ""

    BEFORE_COUNT=$(ls -1 *.mp3 2>/dev/null | wc -l)

    # Generate a yt-dlp compatible archive from id_filename_map.txt
    if [ -f "id_filename_map.txt" ]; then
        awk -F'|' '{print "youtube " $1}' id_filename_map.txt > history.tmp
    else
        touch history.tmp
    fi

    # 1. Run the download (New songs)
    yt-dlp -x --audio-format mp3 --audio-quality 0 \
    --embed-thumbnail --embed-metadata \
    --sub-langs "en.*,ja.*,.*-orig,all" \
    --convert-subs lrc --postprocessor-args "ffmpeg:-id3v2_version 3" \
    --parse-metadata "track_number:%(meta_track)s" \
    --no-part --no-warnings -i --ignore-errors --no-cache-dir \
    --download-archive history.tmp -o "%(title)s.%(ext)s" \
    --exec 'echo "%(id)s|%(title)s.mp3" >> new_songs.tmp' \
    "$PLAYLIST_URL"

    rm -f history.tmp
    REMOVED_COUNT=0

    if [ -f "new_songs.tmp" ]; then
        echo -e "\nMusic sync: Tagging new songs..."
        while IFS='|' read -r id filename <&3; do
            if [ -f "$filename" ]; then
                echo -e "\n-----------------------------------------------------------------"
                echo "NEW FILE: $filename"
                read -p "DISPLAY NAME (Leave blank to use filename): " user_input
                if [ -z "$user_input" ]; then
                    CLEAN_TITLE="${filename%.*}"
                else
                    CLEAN_TITLE="$user_input"
                fi
                mid3v2 -t "$CLEAN_TITLE" "$filename"
                echo " -> Saved title tag as: $CLEAN_TITLE"
                echo "$id|$filename" >> id_filename_map.txt
            fi
        done 3< new_songs.tmp
    else
        echo "Music sync: No new songs downloaded, skipping tagging."
        echo ""
    fi



    # 2. Cleanup Audit & Active Deletion (Name + ID Purge)
    echo -e "\nMusic sync: Scanning for removed songs..."

    if yt-dlp --get-id --flat-playlist --no-warnings "$PLAYLIST_URL" > online_ids.txt; then

        # Now delete local files whose ID is no longer online
        if [ -f "id_filename_map.txt" ]; then
            cp id_filename_map.txt id_filename_map_read.tmp

            while IFS='|' read -r id filename; do
                [ -z "$id" ] && continue
                if ! grep -qFx -- "$id" online_ids.txt; then
                    if [ -f "$filename" ]; then
                        echo ""
                        echo " -> Deleting removed song: $filename"
                        rm "$filename"
                        grep -v "^$id|" id_filename_map.txt > id_map.tmp && mv id_map.tmp id_filename_map.txt
                        echo " -> Purged ID $id from map."
                        echo "$filename" >> Deleted_files.tmp
                        REMOVED_COUNT=$((REMOVED_COUNT + 1))
                    fi
                fi
            done < id_filename_map_read.tmp

            rm -f id_filename_map_read.tmp

        else
            echo "Music sync: id_filename_map.txt not found, skipping file deletion. It will be built from future downloads."
        fi

    else
        echo "Music sync: Could not reach YouTube to verify playlist."
    fi

    AFTER_COUNT=$(ls -1 *.mp3 2>/dev/null | wc -l)
    ADDED=$((AFTER_COUNT - BEFORE_COUNT))

    # Playlist update if songs were added or removed
    if [[ $ADDED -gt 0 || $REMOVED_COUNT -gt 0 ]]; then
        echo ""
        echo "Music sync: Songs were added or removed, updating playlist"
        ls -1 *.mp3 | grep -v "^\." > "$PLAYLIST_FILE"
    fi

    # 3. Logging Logic
    # makes sure negaives aren't shown in the notifacation as that can happen if songs are deleted otherwise lol
    if [ $ADDED -lt 0 ]; then
        ADDED=0
    fi
        echo "-----------------------------------------------------------------"
        echo "Added: $ADDED songs | Deleted: $REMOVED_COUNT songs"
        echo "Check sync_log.txt in your music directory for more info"
else
    echo "Music sync: USB Drive not found at $MUSIC_DIR"
fi

# If your reading this comment it is to say that this script was orginaly made by GrenguyAkaTheo on GitHub. I am putting this here so that less people are able to succsessfully sell this script. I know its petty, but them kind of people really piss me off

# Log output
LOG_FILE="$MUSIC_DIR/sync_log.txt"
{
  echo "Sync Session: $(date)"
  echo "Added: $ADDED | Deleted: $REMOVED_COUNT"
  echo ""
  echo "Songs added (YouTube ID|File name);"
  cat new_songs.tmp 2>/dev/null
  echo ""
  echo "Songs deleted (File name);"
  cat Deleted_files.tmp 2>/dev/null
  echo "-----------------------------------------------------------------"
} >> "$LOG_FILE"

rm Deleted_files.tmp 2>/dev/null
rm new_songs.tmp 2>/dev/null

echo ""
read -p "Music sync complete. Press [Enter] to exit..."


# Thanks for reading this. It was heavily vibe coded as this is the first bash script I've ever made, so I used gemini and claud to help me learn
# I do use this scrip on my rasberry pi 3B+ wth pi OS, and my Bazzite PC. So uhh, it does work lol
