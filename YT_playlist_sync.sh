                                                                                                                                                                                                                                                               #!/bin/bash
#!/bin/bash



## !!!!!!!READ HERE!!!!!!!!
## ---- DEPENDANCYS ----
# For this script to work you must have yt-dlp, ffmpeg, and mid3v2 installed!!!
# Please read the whole READ ME file before running this script, there is some important information in there

# Set music directory, YT playlist link, and a plalist name for all your songs here
MUSIC_DIR="<Path to your music folder>"
PLAYLIST_URL="<Your YouTube playlist's link (make sure the playlist is set to public)>"
PLAYLIST_FILE="<What you want your playlist to be called on your device>.m3u"

## If you tun this script and it closes its self imediatly, restarting your device should sort that. It doesn't happen much, but on my raspberry pi 3B+ I had that issue a couple of times and restating it worked both times
## You'r all set to use the script now :D


# --- AUTO-TERMINAL BOX ---
if [ ! -t 0 ]; then
    lxterminal -t "Music Sync" -e "$0"
    exit
fi

# Prevent multiple instances
LOCKFILE="/tmp/music_sync.lock"
if [ -e "$LOCKFILE" ]; then
    echo "Sync already in progress. Exiting."
    exit 1
fi
touch "$LOCKFILE"
trap "rm -f $LOCKFILE *.tmp online_ids.txt local_history_ids.txt; exit" INT TERM EXIT

# Force UTF-8 for Japanese/special characters
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

cd "$MUSIC_DIR"

echo "Music sync: Welcome"
echo ""
sleep 1



# Storage space check
AVAILABLE_KB=$(df . --output=avail | tail -1)
AVAILABLE_MB=$((AVAILABLE_KB / 1024))
echo "Storage Check: $AVAILABLE_MB MB remaining on USB."

if [ "$AVAILABLE_MB" -lt 256 ]; then
    echo "Music sync: LOW DISK SPACE ($AVAILABLE_MB MB). Sync cancelled."
    exit 1
fi

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

    # 1. Run the download (New songs)
    yt-dlp -x --audio-format mp3 --audio-quality 0 \
    --embed-thumbnail --embed-metadata \
    --sub-langs "en.*,ja.*,.*-orig,all" \
    --convert-subs lrc --postprocessor-args "ffmpeg:-id3v2_version 3" \
    --parse-metadata "track_number:%(meta_track)s" \
    --no-part --no-warnings -i --ignore-errors --no-cache-dir \
    --download-archive history.txt -o "%(title)s.%(ext)s" \
    --exec 'echo "%(title)s.mp3" >> new_songs.tmp' \
    "$PLAYLIST_URL"

    # --- Interactive Metadata & Playlist Addition ---
    if [ -f "new_songs.tmp" ]; then
        echo -e "\nMusic sync: Tagging new songs..."

        # Open new_songs.tmp on File Descriptor 3
        while read -r filename <&3; do
            if [ -f "$filename" ]; then
                echo -e "\n--------------------------------------------------"
                echo "NEW FILE: $filename"

                # Now 'read' can use standard stdin (keyboard) naturally
                read -p "DISPLAY NAME (Leave blank to use filename): " user_input

                if [ -z "$user_input" ]; then
                    CLEAN_TITLE="${filename%.*}"
                else
                    CLEAN_TITLE="$user_input"
                fi

                # Write new title to metadata
                mid3v2 -t "$CLEAN_TITLE" "$filename"

                echo " -> Saved title tag as: $CLEAN_TITLE"
            fi
        done 3< new_songs.tmp  # Connect FD 3 to the file

    else
        echo "Music sync: No new songs downloaded, skipping tagging."
    fi

    # 2. Cleanup Audit & Active Deletion (Name + ID Purge)
    echo -e "\nMusic sync: Scanning for removed songs..."

    # 1. Get a list of all current Titles from the YouTube Playlist
    if yt-dlp --get-id --flat-playlist --no-warnings "$PLAYLIST_URL" > online_ids.txt; then
        yt-dlp --get-filename -o "%(title)s" --flat-playlist --no-warnings "$PLAYLIST_URL" > online_titles.txt
        REMOVED_COUNT=0

        grep "youtube" history.txt | awk '{print $2}' | tr -d '\r' > local_history_ids.txt

        while read -r id; do
            [ -z "$id" ] && continue

            if ! grep -qFx -- "$id" online_ids.txt; then
                sed -i "/$id/d" history.txt
            fi
        done < local_history_ids.txt

        # Build a title->ID map from the live playlist
        yt-dlp --flat-playlist --no-warnings \
            --print "%(id)s %(title)s" \
            "$PLAYLIST_URL" > online_title_id_map.txt

        for local_file in *.mp3; do
            [ -e "$local_file" ] || continue
            base_name="${local_file%.*}"

            if ! grep -qF " $base_name" online_title_id_map.txt; then
                echo " -> Deleting removed song: $local_file"

                # Find the matching ID from the map
                MATCHING_ID=$(grep -F " $base_name" online_title_id_map.txt | awk '{print $1}' | head -n 1)

                # Fallback: search history.txt by any partial name match
                if [ -z "$MATCHING_ID" ]; then
                    MATCHING_ID=$(grep -F "$base_name" history.txt | awk '{print $2}' | head -n 1)
                fi

                rm "$local_file"

                if [ -n "$MATCHING_ID" ]; then
                    grep -v "$MATCHING_ID" history.txt > history.tmp && mv history.tmp history.txt
                    echo " -> Purged ID $MATCHING_ID from history."
                else
                    echo " -> WARNING: Could not find ID for $base_name, manual history.txt cleanup may be needed."
                fi

                echo "$local_file" >> Deleted_files.tmp
                REMOVED_COUNT=$((REMOVED_COUNT + 1))
            fi
        done

        rm -f online_title_id_map.txt online_titles.txt

    else
        echo "Music sync: Could not reach YouTube to verify playlist names."
    fi

    AFTER_COUNT=$(ls -1 *.mp3 2>/dev/null | wc -l)
    ADDED=$((AFTER_COUNT - BEFORE_COUNT))

    # Playlist update if songs were added or removed
    if [[ $ADDED -gt 0 || $REMOVED_COUNT -gt 0 ]]; then
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

# Log output
LOG_FILE="$MUSIC_DIR/sync_log.txt"
{
  echo "Sync Session: $(date)"
  echo "Added: $ADDED | Deleted: $REMOVED_COUNT"
  echo ""
  echo "Songs added (Listed as file names);"
  cat new_songs.tmp 2>/dev/null
  echo ""
  echo "Songs deleted (Listed as file names);"
  cat Deleted_files.tmp 2>/dev/null
  echo "-----------------------------------------------------------------"
} >> "$LOG_FILE"

rm Deleted_files.tmp 2>/dev/null
rm new_songs.tmp 2>/dev/null

echo ""
read -p "Music sync complete. Press [Enter] to exit..."


# Thanks for reading this. It was heavily vibe coded as this is the first bash script I've ever made, so I used gemini to help me learn
# I do use this scrip on my rasberry pi 3B+ wth pi OS, and my Bazzite PC. So uhh, it does work lol
