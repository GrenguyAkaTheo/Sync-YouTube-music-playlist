ANY KNOWN ISSUES WILL BE LISTED UNDER THIS LINE;


# Sync-YouTube-music-playlist
This is a relitivly simple bash scrip that uses yt-dlp to download a youtube music playlist and automatically add the thumbnail, lyrics, album, and artists to the metadata of all the songs on the playlist. It will also automaticaly delete songs from your music directory if you remove them from your youtube music playlist

If your on Windows, this may not work as you need bash suppourt. If you get bash suppourt on Windows then feel free to try it out

MAKE SURE THE PLAYLIST YOUR DOWNLOADING IS SET TO PUBLIC ON YOUTUBE


For this script to work you must have yt-dlp, ffmpeg, and mid3v2 installed or it won't be able to download anything off of youtube, or properly embed metadata for some audio players (Like lollypop)

You MUST edit the .sh file (The actual script) and follow the short and simple instructions from line 6 to line 15, or it will crap the bed when you try to run it

Make sure the file is exicutable by your linux distro with `sudo chmod -x <path to file>/YT_playlist_sync.sh` in the terminal, or whatever command you use to make .sh files exicutable. Then simply run the file by opening it in your file explorer, or typing `bash <path to file>/YT_playlist_sync.sh` in your terminal

DO NOT CHANGE THE ACTUAL FILE NAMES OF THE SONGS! This will cause the song to be deleted when you next run the script. This is because the script checks the file name against youtubes songs names to see if the song should be removed or not. If the actual file name is diferent to the one on youtube, the script will think you took the song off your youtube playlist

On that note, MAKE SURE THAT ANY SONGS YOU ALREADY HAVE DOWNLOADED ARE IN A DIFFERENT FILE OR THEY WILL GET DELETED FOR THE SAME REASON!!

DO NOT REMOVE "id_filename_map.txt" ONCE YOU RUN THE SCRIPT. This is effectively a memory for this script, and it keeps the ID's of all the songs in your file. If you delete this file the whole playlist will be downloaded again rather than just the songs that need to be downloaded

All the mp3 files in your music folder will be added to the playlist of all songs. If a song doesn't get added (which is highly unlikely) simply add the file name to a new line in your m3u file

If a song fails to download dew to something along the lines of "video unavalale" but you can get the song in some other way, simply rename the song file to the exact title of the song on youtube music. And then to stop the script from erroring enter "history.txt", and add `youtube <The songs youtube ID (will look something like this "otS3u8227kY")>` as a new line anywhere in the file. This ID can be found in the songs link (like this, at the quoted location after "watch?v=" https://music.youtube.com/watch?v=`otS3u8227kY`&si=MNSqvxaIQXurzefd) 

This tags songs with ID3v2.3 rather than ID3v2.4. This is for better compatibility with older media players like VLC and audatious. You can change this in the yt-dlp download command within the script by changing line 93 to say  `"ffmpeg:-id3v2_version 4"` rather than `"ffmpeg:-id3v2_version 3"`

The album tag is what youtube gives the script to use. If the album gets set to something like the song name (Or nothing at all) this is because of youtube, not the script its self :D


PLEASE DO NOT USE THIS SCRIPT TO DISTROBUTE ANY MEDIA YOU DOWNLOAD!!!

- GrenguyAkaTheo, GitHub
