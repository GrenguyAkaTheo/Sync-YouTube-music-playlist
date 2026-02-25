# Sync-YouTube-music-playlist
This is a relitivly simple bash scrip that uses yt-dlp to download a youtube music playlist and automatically the thumbnail, lyrics, and artists to the metadata of all the songs on the playlist. It will also automaticaly delete songs from your music directory if you remove them from your youtube music playlist. The Album does get set to the file name as of personal preferances, but you can obviously change this if you can find where it does this (I forgot :D)


THIS IS WHAT YOU REALLY REALLY NEED TO READ!!!
For this script to work you must have yt-dlp, and mid3v2 installed or it won't be able to download anything off of youtube, or properly embed metadata for some audio players (Like lollypop)

You MUST edit the .sh file (The actual script) and follow the short and simple instructions from line 6 to line 15, or it will crap the bed when you try to run it

Make sure the file is exicutable by your linux distro with `sudo chmod -x <path to file>/YT_playlist_sync.sh` in the terminal, or whatever command you use to make .sh files exicutable. Then simply run the file by opening it in your file explorer, or typing `bash <path to file>/YT_playlist_sync.sh` in your terminal

DO NOT CHANGE THE ACTUAL FILE NAMES OF THE SONGS! This will cause the song to be deleted when you next run the script. This is because the script checks the file name agains youtubes songs names to see if the song should be removed or not. If the actual file name is diferent to the one on youtube, the script will think you took the song off your youtube playlist

On that note, MAKE SURE THAT ANY SONGS YOU ALREADY HAVE DOWNLOADED ARE IN A DIFFERENT FILE OR THEY WILL GET DELETED FOR THE SAME REASON!!


Please don't use this script to distrabute the songs you download, I really don't want another ana's archive situation that makes youtube change their API's like Spotify did and break this script
