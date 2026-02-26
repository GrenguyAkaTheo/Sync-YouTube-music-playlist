                                                                                                                                                                                                                                                               #!/bin/bash
#!/bin/bash



## !!!!!!!READ HERE!!!!!!!!
## ---- DEPENDANCYS ----
# For this script to work you must have yt-dlp, and mid3v2 installed!!!

# Set music directory, YT playlist link, and a plalist name for all your songs here
MUSIC_DIR="<Music folder path here>"
PLAYLIST_URL="<YouTube or YouTube music playlist link here>"
PLAYLIST_FILE="<Name of playlist for all songs in your music folder here (It will make one if you don't have a playlist file)>.m3u"

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
    --embed-thumbnail --embed-metadata --write-subs --embed-subs \
    --no-part --no-warnings -i --ignore-errors --no-cache-dir \
    --download-archive history.txt -o "%(title)s.%(ext)s" \
    --exec 'echo "%(title)s.mp3" >> new_songs.tmp' \
    "$PLAYLIST_URL"

    # --- Interactive Metadata & Playlist Addition ---
    if [ -f "new_songs.tmp" ]; then
        echo -e "\nMusic sync: Tagging new songs..."

        if [ ! -f "$PLAYLIST_FILE" ] || ! head -n 1 "$PLAYLIST_FILE" | grep -q "#EXTM3U"; then
            echo "#EXTM3U" > "$PLAYLIST_FILE"
        fi

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

                # Using < /dev/null ensures mid3v2 doesn't look at stdin at all
                mid3v2 --convert --v2.3 -t "$CLEAN_TITLE" -A "${filename%.*}" "$filename" >/dev/null 2>&1 < /dev/null

                if ! grep -qFx "$filename" "$PLAYLIST_FILE"; then
                    printf "#EXTINF:-1,%s\n%s\n" "$CLEAN_TITLE" "$filename" >> "$PLAYLIST_FILE"
                fi

                echo " -> Saved and added to playlist as: $CLEAN_TITLE"
            fi
        done 3< new_songs.tmp  # Connect FD 3 to the file

        else
        echo "Music sync: No new songs downloaded, skipping tagging."
    fi
    # 2. Cleanup Audit & Active Deletion
    REMOVED_COUNT=$1
    echo -e "\nMusic sync: Scanning for removed songs..."
    if yt-dlp --get-id --flat-playlist --no-warnings "$PLAYLIST_URL" > online_ids.txt; then
        REMOVED_COUNT=0
        grep "youtube " history.txt | awk '{print $2}' | tr -d '\r' > local_history_ids.txt
        while read -r id; do
            [ -z "$id" ] && continue
            if ! grep -qFx -- "$id" online_ids.txt; then
                EXPECTED_NAME=$(yt-dlp --get-filename -o "%(title)s.mp3" -- "$id" 2>/dev/null)
                if [ -f "$EXPECTED_NAME" ]; then
                    rm "$EXPECTED_NAME"
                    echo "$(date +'%Y-%m-%d %H:%M') | ID: $id | File: $EXPECTED_NAME" >> session_deletions.tmp
                    echo "$EXPECTED_NAME" >> Deleted_files.tmp
                    grep -v "$id" history.txt > history.tmp && mv history.tmp history.txt
                    REMOVED_COUNT=$((REMOVED_COUNT + 1))
                else
                    REAL_FILE=$(find . -maxdepth 1 -type f -name "*$id*.mp3" -print -quit)
                    if [ -n "$REAL_FILE" ]; then
                        rm "$REAL_FILE"
                        echo "$(date +'%Y-%m-%d %H:%M') | ID: $id | File: $(basename "$REAL_FILE")" >> session_deletions.tmp
                        grep -v "$id" history.txt > history.tmp && mv history.tmp history.txt
                        REMOVED_COUNT=$((REMOVED_COUNT + 1))
                    fi
                fi
            fi
        done < local_history_ids.txt

        [ -f session_deletions.tmp ] && cat session_deletions.tmp >> Deleted.txt
        [ -f session_deletions.tmp ] && cat session_deletions.tmp > Session_deletions.txt
        rm -f online_ids.txt local_history_ids.txt
    fi

    AFTER_COUNT=$(ls -1 *.mp3 2>/dev/null | wc -l)
    ADDED=$((AFTER_COUNT - BEFORE_COUNT))

    # --- SMART PLAYLIST CLEANUP ---
    # Rebuilds the playlist by reading metadata/path pairs and checking file existence
    if [[ -f "new_songs.tmp" || $REMOVED_COUNT -gt 0 ]]; then
        if [ -f "$PLAYLIST_FILE" ]; then
            echo "Music sync: Updating playlist entries..."
            mv "$PLAYLIST_FILE" "old_list.tmp"
            echo "#EXTM3U" > "$PLAYLIST_FILE"
            # Skip the header, then read line1 (#EXTINF) and line2 (path)
            grep -v "^#EXTM3U" "old_list.tmp" | while read -r line1; do
                read -r line2
                if [ -f "$line2" ]; then
                    echo "$line1" >> "$PLAYLIST_FILE"
                    echo "$line2" >> "$PLAYLIST_FILE"
                fi
            done
            rm old_list.tmp
        fi
    fi
    # 3. Notification Logic
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
