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



# --- Makes the script run in a terminal if you don't launch it via the terminal ---
if [ ! -t 0 ]; then
    lxterminal -t "Music Sync" -e "$0"
    exit
fi
# -----------------------------------------------------------------------------------


# Prevent multiple instances of the script running at once
LOCKFILE="${TMPDIR:-/data/local/tmp}/music_sync.lock"
if [ -e "$LOCKFILE" ]; then
    echo "Sync already in progress. Exiting."
    exit 1
fi
touch "$LOCKFILE"
trap "rm -f '$LOCKFILE' *.tmp online_ids.txt local_history_ids.txt; exit" INT TERM EXIT


# Force UTF-8 for special characters
export LC_ALL=C.UTF-8
export LANG=C.UTF-8


cd "$MUSIC_DIR"

echo "Music sync: Welcome"
echo "Do not distrobute anything you have obtained via this script!"
echo ""


# Storage space check
AVAILABLE_KB=$(df . | tail -1 | awk '{print $4}')
AVAILABLE_MB=$((AVAILABLE_KB / 1024))
echo "Storage Check: $AVAILABLE_MB MB remaining."
if [ "$AVAILABLE_MB" -lt 256 ]; then
    echo "Music sync: LOW DISK SPACE ($AVAILABLE_MB MB). Sync cancelled."
    exit 1
fi

echo ""

# Check for WiFi connection by pinging Google, cos uhh, Google is basicaly always up
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


    # The start of the actuall point of the script lol

    # Checks the amount of songs before the download so that it can say how many songs were added or removed
    BEFORE_COUNT=$(ls -1 *.mp3 2>/dev/null | wc -l)

    # Generate a yt-dlp archive from id_filename_map.txt that safe to get corrupted if something goes wrong
    if [ -f "id_filename_map.txt" ]; then
        awk -F'|' '{print "youtube " $1}' id_filename_map.txt > id_filename_map_but_so_its_not_corrupted_during_download.tmp
    else
        touch id_filename_map_but_so_its_not_corrupted_during_download.tmp
    fi

    # The actuall download command
    # Feel free to add/remove the metadata related taggs so that its suited for you :D
    yt-dlp -x --audio-format mp3 --audio-quality 0 \
    --embed-thumbnail --embed-metadata \
    --sub-langs "en.*,ja.*,.*-orig,all" \
    --convert-subs lrc --postprocessor-args "ffmpeg:-id3v2_version 3" \
    --parse-metadata "track_number:%(meta_track)s" \
    --no-part --no-warnings -i --ignore-errors --no-cache-dir \
    --download-archive id_filename_map_but_so_its_not_corrupted_during_download.tmp -o "%(title)s.%(ext)s" # DO NOT REMOVE THIS\
    --exec 'echo "%(id)s|%(title)s.mp3" >> new_songs.tmp' #OR THIS\
    "$PLAYLIST_URL" #Oh, OR THIS AS WELL

    rm -f id_filename_map_but_so_its_not_corrupted_during_download.tmp
    REMOVED_COUNT=0


    # This checks for any new songs so that you get asked if you want to change the title of your newly downloaded songs
    # I found the YouTube song names anoying because alot of them had a bunch of random junk in the names
    if [ -f "new_songs.tmp" ]; then
        echo -e "\nMusic sync: Tagging new songs..."
        # Heres the part where we make sure it asks you for each song because I forgot to do that in some earlier versions of the script
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



    # Deleting songs that aren't on the YouTube playlist anymore
    echo -e "\nMusic sync: Scanning for removed songs..."

    if yt-dlp --get-id --flat-playlist --no-warnings "$PLAYLIST_URL" > online_ids.txt; then

        # Make the deleted files go kapif when they arent in id_filename_map.txt
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
                        echo " -> Removed ID $id and filename id_filename_map.txt."
                        echo "$filename" >> Deleted_files.tmp
                        # Making the script say how many songs were removed in this session cos I like that info
                        REMOVED_COUNT=$((REMOVED_COUNT + 1))
                    fi
                fi
            done < id_filename_map_read.tmp

            rm -f id_filename_map_read.tmp

        else
            # This is so that if the file is deleted somehow you dont loose all your songs, because that would absolutely suck
            echo "Music sync: id_filename_map.txt not found, skipping file deletion. It will be built from future downloads."
        fi

    else
        # Just incase
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


    # Time to make the log!!

    # makes sure negaives aren't shown in the notifacation as that can happen if songs are deleted otherwise for some reason lol
    if [ $ADDED -lt 0 ]; then
        ADDED=0
    fi
        echo "-----------------------------------------------------------------"
        echo "Added: $ADDED songs | Deleted: $REMOVED_COUNT songs"
        echo "Check sync_log.txt in your music directory for more info"
else
    echo "Music sync: $MUSIC_DIR does not exist or could not be found"
fi

# If your reading this comment it is to say that this script was orginaly made by GrenguyAkaTheo on GitHub. I am putting this here so that less people are able to succsessfully sell this script. I know its petty, but them kind of people really piss me off

# Adding to the sync log
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
