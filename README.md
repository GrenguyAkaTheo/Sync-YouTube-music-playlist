# Sync-YouTube-music-playlist
This is a relitivly simple bash scrip that uses yt-dlp to download a youtube music playlist and automatically the thumbnail, lyrics, and artists to the metadata of all the songs on the playlist. The Album does get set to the file name as of personal preferances, but you can obviously change this if you can find where it does this (I forgot :D)


THIS IS WHAT YOU REALLY REALLY NEED TO READ!!!
For this script to work you must have yt-dlp, and mid3v2 installed or it won't be able to download anything off of youtube, or properly embed metadata for some audio players (Like lollypop)

You MUST edit the .sh file (The actual script) and follow the short and simple instructions from line 6 to line 15, or it will crap the bed when you try to run it

Make sure the file is exicutable by your linux distro with `sudo chmod -x <path to file>/YT_playlist_sync.sh` in the terminal, or whatever command you use to make .sh files exicutable. Then simply run the file by opening it in your file explorer, or typing `bash <path to file>/YT_playlist_sync.sh` in your terminal


Please don't use this script to distrabute the songs you download, I really don't want another ana's archive situation that makes youtube change their API's like Spotify did and break this script
