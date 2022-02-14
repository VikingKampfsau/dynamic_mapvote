# Dynamic Mapvote

## Overview

A little test if it's possible to create a dynamic mapvote.<br/>
This is a menu based mapvote that auto updates its iwd everytime the map ends.<br/>
That way the content of the mapvote is constantly changing without wasteing assets.<br/>

**I never used this in any of my mods so it's not tested on a live server yet**<br/>
**Full source included**<br/>

**LINUX OS ONLY!**<br/>

## Preview
Video might be outdated but still shows the main content of the vote menu.

https://user-images.githubusercontent.com/82271312/143201530-547ea624-5099-4a21-931b-840c9f02451d.mp4

## Installation

When you don't run your fastdl on the same machine as your cod4 server, then please install 'sshpass' in order to upload the iwd to your fastdl *encrypted*, otherwise install 'cURL'.
When you run your fastdl on the same machine as your cod4 server, then a softlink created on the fastdl pointing to the mapvote.iwd is enough.

Note: For sshpass you might have to accept the host fingerprint on the very first run!

###### Install the example files from this repro:
Install cod4x and add the required plugins to it.<br/>
Copy the mod to your mods folder - if you already have an older version then remove it.<br/>

Add the content of the example config to your server config.<br/>

###### Add this repro to your mod project:
Install cod4x and add the required plugins to it.<br/>
Add the content of the example config to your server config.<br/>
Add the content of the example mod.csv to your mod.csv.<br/>
Copy the materials, material_propteries and ui_mp folders to your modtools raw folder.<br/>
Copy the mapvote folder and mapvote.iwd to the root folder of your mod.
Compile your mod.

Modify the maps/mp/gametype/_globallogic.gsc or the script that handles your end of game and map rotation.
Add the following at the desired position:
```
	level notify("start_mapvote"); //start the mapvote
	level waittill("end_mapvote"); //wait for it's end
```

Also do not forget to init the mapvote.
Add the following line to any main function of your scripts:
```
	thread mapvote\script\dynamic_mapvote::init(); //init mapvote
```

## How to add more maps

Add the map to config - dvar "sv_voteable_maps".<br/>
Add the loadscreen.iwi file to \mapvote\images folder.<br/>

## FAQ

Q: I have an loadscreen image in the \mapvote\images folder but the image does not appear ingame.<br/>
A: Your loadscreen image might have a different name than the map itself<br/>
   You can either rename the loadscree image in \mapvote\images to match the map name,<br/>
   or add the reference to the _replacements.csv found in same folder.<br/>
 
Q: The mapvote.iwd is not updating<br/>
A: Check your console log and make sure you installed 'zip' on your server<br/>

Q: The mapvote.iwd is generated empty and players get kicked with "Could not find loadscreen_0.iwi"<br/>
A: Make sure you installed 'zip' on your server<br/>
   Make sure the folder and file permissions are correct<br/>
   Make sure you have set the fs_homepath correctly<br/>

Q: Players get a download loop when downloading the mapvote.iwd<br/>
A: The mod generates a new mapvote.iwd on every map end therefor the file continously changes.<br/>
   To avoid a download loop create a softlink instead.<br/>

Q: Players download the mapvote.iwd from server instead from fastdl<br/>
A: When your fastdl runs on the same machine as your server you can create a softlink at fastdl folder to the mapvote.iwd located in your cod4 server.<br/>
   To upload the mapvote.iwd to a remote server please check your config settings and the login and file permissions on the remote server.<br/>
   The console log should tell you when the upload failed<br/>

## Support
For bug reports and issues, please visit the "Issues" tab at the top.<br><br/>
First look through the issues, maybe your problem has already been reported.<br><br/>
If not, feel free to open a new issue.<br/>

**Keep in mind that we only support the current state of the repository - older versions are not supported anymore!**

However, for any kind of question, feel free to visit our discord server at https://discord.gg/wDV8Eeu!
