ANY KNOWN ISSUES WILL BE LISTED UNDER THIS LINE;
Yeah so uhh, the lyrics just like, don't download. Not sure exactly *why*, but I have a feeling its to do with how YouTube is providing the lyrics. I really can't be arsed with figuring that out because that'll be to do with yt-dlp or YouTube them selves (neither of which im able to change the code of :D). So yeah, i guess we all just need to wait if we want a fix for that


# Sync-YouTube-music-playlist
This is a relitivly simple bash scrip that uses yt-dlp to download a youtube music playlist and automatically add the thumbnail, lyrics, album, and artists to the metadata of all the songs on the playlist. It will also automaticaly delete songs from your music directory if you remove them from your youtube music playlist

If your on Windows, this may not work as you need bash suppourt. If you get bash suppourt on Windows then feel free to try it out. I do know that Visual Studio Code has a Shell extention called "Code runner". This should allow the script to run, but you will need to find a way to install the dependancys and get the /bin/bash path to exist

MAKE SURE THE PLAYLIST YOUR DOWNLOADING IS SET TO PUBLIC ON YOUTUBE


For this script to work you must have yt-dlp, ffmpeg, and mid3v2 installed or it won't be able to download anything off of youtube, or embed some of the metadata (which will cause the script to crash as it wont know what tf some of the commands are trying to say). To install yt-dlp run 'sudo apt install yt-dlp', this should also imstall ffmpeg automatically (if not, you can run 'sudo apt install ffmpeg'). To install mid3v2 you must imstall it along side mutagen with pip (or uv tool if you have it), this can be done with 'pip install mutagen' (or 'uv tool install mutagen' if you have uv tool) (I recommend you install this after yt-dlp, as yt-dlp will install pip automatically so you wont have to install it yourself if you dont already have it)

You MUST edit the .sh file (The actual script) and follow the short and simple instructions from line 5 to line 16, or it will crap the bed when you try to run it

Make sure the file is exicutable by your linux distro with `sudo chmod -x <path to file>/YT_playlist_sync.sh` in the terminal, or whatever command you use to make .sh files exicutable. Then simply run the file by opening it in your file explorer, or typing `bash <path to file>/YT_playlist_sync.sh` in your terminal

DO NOT CHANGE THE ACTUAL FILE NAMES OF THE SONGS! This will cause the song to be deleted when you next run the script. This is because the script checks the file name against youtubes songs names to see if the song should be removed or not. If the actual file name is diferent to the one on youtube, the script will think you took the song off your youtube playlist

On that note, MAKE SURE THAT ANY SONGS YOU ALREADY HAVE DOWNLOADED THAT WERENT DOWNLOADED FROM THIS SCRIPT ARE IN A DIFFERENT FILE OR THEY WILL GET DELETED FOR THE SAME REASON!!

DO NOT REMOVE "id_filename_map.txt" ONCE YOU RUN THE SCRIPT. This is effectively a memory for this script, and it keeps the ID's of all the songs in your file. If you delete this file the whole playlist will be downloaded again rather than just the songs that need to be downloaded

All the mp3 files in your music folder will be added to the playlist of all songs. If a song doesn't get added (which is highly unlikely) simply add the file name to a new line in your m3u file

If a song fails to download dew to something along the lines of "video unavalale" but you can get the song in some other way, simply rename the song file to the exact title of the song on youtube music. And then to stop the script from erroring enter "id_filename_map.txt", and add `<The songs youtube ID (will look something like this "otS3u8227kY")>|<The songs filename with the file type>` as a new line anywhere in the file. This ID can be found in the songs link (like this, at the quoted location after "watch?v=" https://music.youtube.com/watch?v=`otS3u8227kY`&si=MNSqvxaIQXurzefd. also this song im using as an example is absolutely peak, I highly recommend you listen to it, you just need to remove the quotes from the URL to look it up) 

This script tags songs with ID3v2.3 rather than ID3v2.4. This is for better compatibility with older media players like VLC and audatious. You can change this in the yt-dlp download command within the script by changing line 93 to say  `"ffmpeg:-id3v2_version 4"` rather than `"ffmpeg:-id3v2_version 3"`

If you downloaded s song with charictors like a /, you will likely have to remove these from id_filename_map.txt and your music folder manualy if you remove it from your YouTube music playlist. This is because your device will think that its looking for a diferent folder all together, and fail to find the song to delete, and then give up with removing it from id_filename_map.txt. Also because of this, if your downloading a songs with a / in the name you may been to ad this ID and filename to id_filename_map.txt manually (In the format <YouTube ID>|<Filename>)

The album tag is what youtube gives the script to use. If the album gets set to something like the song name (Or nothing at all) this is because of youtube, not the script its self :D. One way to solve this is to add the version of the song you want from the album rather than its music video as the music videos often dont contain the album there from

I recomend you format your drives partition to something like BTRFS as this is caps sensitive. Any form of FAT formatting and NTFS are not caps sensitive, which can rarely cause issues.



PLEASE DO NOT USE THIS SCRIPT TO DISTROBUTE ANY MEDIA YOU DOWNLOAD!!!



---- Anything under this line is only relivent to the mobile version ----

If you are running this on your phone you do need terminal access. I recommend you use Fdroid-Termix for this (but any bash terminal *should* do). I do not know if this works on Apple, but it theoretically should as iOS is also Linux based, but you will need some other way to get a terminal as Termix is an Fdroid application (And is only available on Android)

The same dependacies apply if your using it on your phone. The script is EXACTLY the same, there is no version of the script specifically for mobile. The one script should run on pretty much all desktop linux distros, Andoid, and iOS (I am unable to test iOS, but theroretically it should work)

If you are using Termix sudo won't work, however you don't need sudo. simply run the same commands to install the dependencies but without 'sudo'

The set up is exactly the same as on PC. Please read through the part of the READ ME for PC to set it up, as once again, it's exactly the same script

You will likely have an issue or two while installing these. One of them will likely be a permission issue, but it will show up as a missing directory error, and has a one comand fix (I can't remember the command though). I won't know exactly what other issues you may have, so I won't list the fixes here (If you read what I said for the rest of the mobile, it should work regardless). They are very easy to find fixes for on Google if you just take a screenshot of Termix, and send it to Gemini (Shut up about AI, this is one of the moments where it's actually useful for once) and say with the image "I have had this error on Termix. How can I fix it" (or something similar, this is just a prompt I'm providing that should give you a decent answer). If you run AI's fix and you get a different error, simply go through the same prosses again with the same prompt


- GrenguyAkaTheo, GitHub
