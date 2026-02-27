# Sync-YouTube-music-playlist
This is a relitivly simple bash scrip that uses yt-dlp to download a youtube music playlist and automatically the thumbnail, lyrics, and artists to the metadata of all the songs on the playlist. It will also automaticaly delete songs from your music directory if you remove them from your youtube music playlist

If your on Windows, this may not work as you need bash suppourt. If you get bash suppourt on Windows then feel free to try it out

MAKE SURE THE PLAYLIST YOUR DOWNLOADING IS SET TO PUBLIC ON YOUTUBE


For this script to work you must have yt-dlp, and mid3v2 installed or it won't be able to download anything off of youtube, or properly embed metadata for some audio players (Like lollypop)

You MUST edit the .sh file (The actual script) and follow the short and simple instructions from line 6 to line 15, or it will crap the bed when you try to run it

Make sure the file is exicutable by your linux distro with `sudo chmod -x <path to file>/YT_playlist_sync.sh` in the terminal, or whatever command you use to make .sh files exicutable. Then simply run the file by opening it in your file explorer, or typing `bash <path to file>/YT_playlist_sync.sh` in your terminal

DO NOT CHANGE THE ACTUAL FILE NAMES OF THE SONGS! This will cause the song to be deleted when you next run the script. This is because the script checks the file name against youtubes songs names to see if the song should be removed or not. If the actual file name is diferent to the one on youtube, the script will think you took the song off your youtube playlist

On that note, MAKE SURE THAT ANY SONGS YOU ALREADY HAVE DOWNLOADED ARE IN A DIFFERENT FILE OR THEY WILL GET DELETED FOR THE SAME REASON!!

DO NOT REMOVE "history.txt" ONCE YOU RUN THE SCRIPT. This is effectively a memory for this script, and it keeps the ID's of all the songs in your file. If you delete this file the whole playlist will be downloaded again rather than just the songs that need to be downloaded

If your downloading songs with charicters from a different langwage (eg: Japaneise) it may skip title metadata. I have experianced this, about 5 of the 20 songs I downloaded with Japaneise titles did have this issue. The file does get downloaded, but you may have to manually add it to the playlist file. If you do have to do this, it should be formated as followed (I'm using a file I downloaded with this issue as an example);
`#EXTINF:-1,Ambassador` <-- display name/Title of song
`了冫⧸ヽ″廾勺″ー (feat. 重音テト).mp3` <-- Actual file name

If a song fails to download dew to something along the lines of "video unavalale" but you can get the song in some other way, simply rename the song file to the exact title of the song on youtube music. And then to stop the script from erroring enter "history.txt", and add `youtube <The songs youtube ID (will look something like this "otS3u8227kY")>` as a new line anywhere in the file. This ID can be found in the songs link (like this, at the quoted location after "watch?v=" https://music.youtube.com/watch?v=`otS3u8227kY`&si=MNSqvxaIQXurzefd) 

The album tag is what youtube gives the script to use. If the album gets set to something like the song name (Or nothing at all) this is because of youtube, not the script its self :D


Please don't use this script to distrabute the songs you download, I really don't want another ana's archive situation that makes youtube change their API's like Spotify did and break this script

- GrenguyAkaTheo, GitHub
