# Dynamic Mapvote

## Overview

A little test if it's possible to create a dynamic mapvote.<br/>
This is a menu based mapvote that auto updates it's iwd everytime the map ends.<br/>
That way the content of the mapvote is constantly changing without wasteing assets.<br/>

**I never used this in any of my mods so it's not tested on a live server yet**<br/>
**Full source included**<br/>

## Installation

Install cod4x and add the required plugins to it.<br/>
Copy the mod to your mods folder - if you already have an older version then remove it.<br/>

Add the content of the example config to your server config.<br/>

## How to add more maps

Add the map to config - dvar "sv_voteable_maps".<br/>
Add the loadscreen.iwi file to \mapvote\images folder.<br/>

## FAQ
 
- The mapvote.iwd is not updating<br/>
-> check your console and make sure you installed 'zip' on your server<br/>

- The mapvote.iwd is generated empty and players get kicked with "Could not find loadscreen_0.iwi"<br/>
-> Make sure you installed 'zip' on your server<br/>
-> Make sure the folder and file permissions are correct<br/>
-> Make sure you have set the fs_homepath correctly<br/>

- Players get a download loop when downloading the mapvote.iwd<br/>
-> The mod generates a new mapvote.iwd on every map end therefor the file continously changes.<br/>
-> To avoid a download loop create a softlink instead.<br/>

## Support
For bug reports and issues, please visit the "Issues" tab at the top.<br/>
First look through the issues, maybe your problem has already been reported.<br/>
If not, feel free to open a new issue.<br/>

**Keep in mind that we only support the current state of the repository - older versions are not supported anymore!**

However, for any kind of question, feel free to visit our discord server at https://discord.gg/wDV8Eeu!
