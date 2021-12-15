init()
{
	game["menu_votemap"] = "votemap";
	precacheMenu(game["menu_votemap"]);

	FS_FCloseAll();

	thread initMapvote();
}

/*--------------------------\
|		side functions		|
\--------------------------*/

shuffleArray(array)
{
	currentIndex = array.size;
	temporaryValue = undefined;
	randomIndex = undefined;

	// While there remain elements to shuffle...
	while(currentIndex != 0)
	{
		// Pick a remaining element...
		randomIndex = randomInt(currentIndex);
		currentIndex -= 1;

		// And swap it with the current element.
		temporaryValue = array[currentIndex];
		array[currentIndex] = array[randomIndex];
		array[randomIndex] = temporaryValue;
	}
	
	return array;
}

/*--------------------------\
|		Mapvote itself		|
\--------------------------*/

initMapvote()
{
	if(getDvarInt("mapvote_votetime") <= 0)	setDvar("mapvote_votetime", 15);
	if(getDvarInt("mapvote_resulttime") <= 0) setDvar("mapvote_resulttime", 5);
	if(getDvarInt("mapvote_resultdelay") <= 0) setDvar("mapvote_resultdelay", 3);
	if(getDvarInt("mapvote_voteableItems") < 2) setDvar("mapvote_voteableItems", 2);
	if(getDvarInt("mapvote_voteableItems") > 9) setDvar("mapvote_voteableItems", 9);
	if(getDvarInt("mapvote_winner_display") < 0) setDvar("mapvote_winner_display", 0);
	if(getDvarInt("mapvote_winner_display") > 3) setDvar("mapvote_winner_display", 3);

	level.mapVoteStarted = false;
	
	level.mapvote_mapsToVote = [];
	level.mapvote_resulttime = getDvarInt("mapvote_resulttime");
	level.mapvote_resultdelay = getDvarInt("mapvote_resultdelay");
	level.mapvote_votetime = getDvarInt("mapvote_votetime");
	level.mapvote_voteableItems = getDvarInt("mapvote_voteableItems");
	level.mapvote_winner_display = getDvarInt("mapvote_winner_display");
	
	//on very first map the iwd is not up to date
	//so create any mapvote and reboot the map
	if(getDvarInt("mapvote_setupDone") <= 0)
	{	
		prepareNextMapvote();
		
		setDvar("mapvote_setupDone", 1);
		setDvar("sv_maprotation","gametype " + level.gametype + " map " + level.script);
		setDvar("sv_maprotationcurrent", "gametype " + level.gametype + " map " + level.script);
		exitLevel(false);
	}

	thread onPlayerConnect();

	setVoteableMapDvars(true);
	
	level waittill("start_mapvote");
	
	if(level.voteableMap.size > 1)
	{	
		openMapvote();
		updateCastVotes();
		closeMapvote();
	}
	
	prepareNextMapvote();
	
	wait 3;
	
	level notify("end_mapvote");
}

prepareNextMapvote()
{
	//get the location of the game and mod files
	fs_homepath = getDvar("fs_homepath");
	fs_game = getDvar("fs_game");
	
	//no game/mod found
	if(fs_homepath == "" || fs_game == "")
		return;
		
	//fix the path strings
	if(getSubStr(fs_homepath, 0, 1) != "/") fs_homepath = "/" + fs_homepath;
	if(getSubStr(fs_game, 0, 1) != "/") fs_game = "/" + fs_game;
	
	//fix the path strings
	fs_homepath = StrRepl(fs_homepath, "//", "/");
	fs_game = StrRepl(fs_game, "//", "/");
	
	//open/create a config file
	config = fs_fOpen("/mapvote/temp/dynamic_mapvote.cfg", "write");
	
	//config not writeable
	if(config <= 0)
		return;

	//build a random vote from rotation
	setVoteableMapDvars(false);

	//import the new items for the next vote
	for(i=0;i<level.mapvote_voteableItems;i++)
		level.mapvote_mapsToVote[i] = getDvar("mapvote_map" + i);
		
	//update config file
	FS_WriteLine(config, "//mapvote value import");
	FS_WriteLine(config, "set mapvote_votetime " + (level.mapvote_votetime*1000));
	FS_WriteLine(config, "set mapvote_resulttime " + (level.mapvote_resulttime*1000));
	FS_WriteLine(config, "set mapvote_resultdelay " + (level.mapvote_resultdelay*1000));
	FS_WriteLine(config, "set mapvote_winner_display " + level.mapvote_winner_display);
	FS_WriteLine(config, "set mapvote_voteableItems " + level.mapvote_voteableItems);
	FS_WriteLine(config, "set mapvote_columns " + ceil(level.mapvote_voteableItems/3));
	FS_WriteLine(config, "set mapvote_rows " + ceil(level.mapvote_voteableItems/3)); //int(floor((int((level.mapvote_voteableItems-0.5)*10) % int(3*10))/10)+1));
	
	for(i=0;i<level.mapvote_mapsToVote.size;i++)
		FS_WriteLine(config, "set mapvote_map" + i + "_realname " + getMapDisplayname(level.mapvote_mapsToVote[i]));

	//close config file
	fs_fClose(config);
	
	//collect the images for the next mapvote and copy them to a temp folder
	serverAndModPath = fs_homepath + fs_game;
	for(i=0;i<level.mapvote_mapsToVote.size;i++)
	{
		filePathWithName = "/mapvote/images/loadscreen_" + level.mapvote_mapsToVote[i] + ".iwi";

		targetPathNoName = "/mapvote/temp/images";
		targetPathWithName = targetPathNoName + "/loadscreen_" + i + ".iwi";
	
		//when the map has no loadscreen image then check the replacement table for an entry
		if(!fs_testFile(filePathWithName))
		{
			//iPrintLnBold("image file '" + filePathWithName + "' not found");
		
			replacePathWithName = "/mapvote/images/_replacements.csv";
			if(fs_testFile(replacePathWithName))
			{
				//open replacement file
				replace = fs_fOpen(replacePathWithName, "read");
				
				if(replace <= 0)
				{
					replace = fs_fOpen(replacePathWithName, "write");
					
					if(replace > 0)
					{
						FS_WriteLine(replace, "FullMapName,LoadscreenImageName");
						closeFile(replace);
					}
				}
				else
				{
					line = "";
					while(isDefined(line))
					{
						line = fReadLn(replace);

						if(!isDefined(line) || line == "" || line == " ")
							line = undefined;
						else
						{
							tokens = strToK(line, ",");
							
							if(isDefined(tokens) && tokens.size >= 2)
							{
								if(tokens[0] == level.mapvote_mapsToVote[i])
								{
									//iPrintLnBold("found new image '" + tokens[1] + "' for '" + level.mapvote_mapsToVote[i] +"'\n");
									filePathWithName = "/mapvote/images/" + tokens[1] + ".iwi";
									break;
								}
							}
						}
					}
					
					closeFile(replace);
				}
			}

			//when the table does not refer to a loadscreen image then use an empty one
			if(!fs_testFile(filePathWithName))
			{
				iPrintLnBold("image file '" + filePathWithName + "' not found\n");
				filePathWithName = "/mapvote/images/empty.iwi";
			}
		}

		//abort when the empty image is not found
		if(!fs_testFile(filePathWithName))
		{
			//iPrintLnBold("fallback image 'empty.iwi' not found");
			return;
		}
		
		//copy the images to a temp folder
		system("mkdir -p " + serverAndModPath + targetPathNoName);
		system("cp " + serverAndModPath + filePathWithName + " " + serverAndModPath + targetPathWithName);
	}
	
	//create a new mapvote.iwd from temp, containing the images and the config
	system("cd " + serverAndModPath + "/mapvote/temp;zip -r ../../mapvote.iwd *");
	
	//in case the fastdownload is on a different server or the host did not set a simlink try to upload the new iwd to the fastdl server
	if(getDvar("mapvote_fastdl_ip") != "")
	{
		if(getDvarInt("mapvote_fastdl_encrypted") == 1)
			system("sshpass -p '" + getDvar("mapvote_fastdl_password") + "' scp " + serverAndModPath + "/mapvote.iwd " + getDvar("mapvote_fastdl_username") + "@" + getDvar("mapvote_fastdl_ip") + ":" + getDvar("mapvote_fastdl_folder") + fs_game + "/");
		else
			system("curl -T " + serverAndModPath + "/mapvote.iwd -u " + getDvar("mapvote_fastdl_username") + ":" + getDvar("mapvote_fastdl_password") + " ftp://" + getDvar("mapvote_fastdl_ip") + "/" + getDvar("mapvote_fastdl_folder") + fs_game + "/");
	}
}

getMapDisplayname(map)
{
	map = StrRepl(map, "_", " ");
	tokens = strToK(map, " ");

	mapname = "";
	for(i=0;i<tokens.size;i++)
	{
		if(isDefined(tokens[i]) && tokens[i] != "")
		{
			if(tokens[i] != "mp")
			{
				tokens[i] = toUpper(getSubStr(tokens[i], 0, 1)) + getSubStr(tokens[i], 1, tokens[i].size);
				mapname = mapname + tokens[i] + " ";
			}
		}
	}

	return mapname;
}

setVoteableMapDvars(voteIsForThisMap)
{
	if(!isDefined(voteIsForThisMap) || !voteIsForThisMap)
	{
		maps = strTok(getDvar("sv_voteable_maps") , ";");
		maps = shuffleArray(maps);

		if(maps.size < level.mapvote_voteableItems)
			level.mapvote_voteableItems = maps.size;

		for(i=0;i<maps.size;i++)
		{
			if(i > 8)
				break;
			else
			{
				if(!isDefined(maps[i]) || maps[i] == "" || maps[i] == " ")
				{
					for(j=i;j<=8;j++)
						setDvar("mapvote_map" + j, "");
						
					break;
				}
			
				setDvar("mapvote_map" + i, maps[i]);
			}
		}
	}
	else
	{
		level.voteableMap = [];
	
		maps = undefined;
		getMapsFromConfig = false;
		if(getDvar("mapvote_map0") == "")
		{
			getMapsFromConfig = true;
			maps = strTok(getDvar("sv_voteable_maps") , ";");
		}
	
		for(i=0;i<level.mapvote_voteableItems;i++)
		{
			if(!getMapsFromConfig)
				map = getDvar("mapvote_map" + i);
			else
				map = maps[i];
			
			setDvar("mapvote_map" + i, "");
			
			if(!isDefined(map) || map == "" || map == " ")
				continue;
		
			level.voteableMap[i] = spawnStruct();
			level.voteableMap[i].id = i;
			level.voteableMap[i].menuid = i+1;
			level.voteableMap[i].name = map;
			level.voteableMap[i].votes = 0;
		}
	}
}

openMapvote()
{
	level.mapVoteStarted = true;

	//a player is joining a vote in progress
	if(isDefined(self) && isPlayer(self))
	{
		self closeMenu();
		self closeInGameMenu();
		self notify("reset_outcome");
		self openMenu(game["menu_votemap"]);

		wait .05;

		if(isDefined(self) && isPlayer(self))
			self setClientDvar("mapvote_votetime", level.remainingVoteTime);
	}
	else
	{
		for(i=0;i<level.players.size;i++)
		{
			level.players[i] closeMenu();
			level.players[i] closeInGameMenu();
			level.players[i] notify("reset_outcome");
			level.players[i] openMenu(game["menu_votemap"]);
		}
	}
}

closeMapvote()
{
	if(level.mapvote_winner_display > 0)
	{
		wait getDvarInt("mapvote_resultdelay");
		wait 0.8; //check the menu for the move (in) time of the winner image WINNER_ANIM_MOVESPEED
	}

	wait getDvarInt("mapvote_resulttime");

	for(i=0;i<level.players.size;i++)
		level.players[i] setClientDvar("mapvote_anim_moveout", 1);

	wait 0.6; //check the menu for the move (out) time ANIM_MOVESPEED

	for(i=0;i<level.players.size;i++)
	{
		level.players[i] closeMenu();
		level.players[i] closeInGameMenu();
	}
}

updateCastVotes()
{
	wait 0.6; //check the menu for the move (in) time ANIM_MOVESPEED

	update = 0;
	curWinner = -1;
	level.remainingVoteTime = level.mapvote_votetime * 1000;
	while(level.remainingVoteTime > 0)
	{
		update = level.remainingVoteTime % 1000;
		if(update == 0 || update == 500)
		{
			winner = GetVoteWinner();
			thread sendVotesToPlayers(winner);
		}
	
		wait .05;
		
		level.remainingVoteTime -= 50;
	}
	
	level.mapVoteStarted = false;
	
	winner = GetVoteWinner();
	thread sendVotesToPlayers(winner);
	
	setDvar("sv_maprotation","gametype " + level.gametype + " map " + winner.name);
	setDvar("sv_maprotationcurrent", "gametype " + level.gametype + " map " + winner.name);

}

sendVotesToPlayers(winner)
{
	tempArray = [];
	for(i=0;i<=8;i++)
	{
		if(i < level.voteableMap.size)
			tempArray[i] = level.voteableMap[i].votes;
		else
			tempArray[i] = 0;
	}
	
	if(!isDefined(winner))
		winner = 0;
	else
		winner = winner.menuid;
	
	for(i=0;i<level.players.size;i++)
	{
		level.players[i] setClientDvars(
							"votes_mapvote_map0", tempArray[0],
							"votes_mapvote_map1", tempArray[1],
							"votes_mapvote_map2", tempArray[2],
							"votes_mapvote_map3", tempArray[3],
							"votes_mapvote_map4", tempArray[4],
							"votes_mapvote_map5", tempArray[5],
							"votes_mapvote_map6", tempArray[6],
							"votes_mapvote_map7", tempArray[7],
							"votes_mapvote_map8", tempArray[8],
							"mapvote_winner", winner);
	}
}

GetVoteWinner()
{
	possibleWinner = [];

	if(!level.players.size)
	{
		if(level.mapVoteStarted)
			return undefined;
	
		return level.voteableMap[randomInt(level.voteableMap.size)];
	}

	curAmount = 0;
	for(i=0;i<level.voteableMap.size;i++)
	{
		if(level.voteableMap[i].votes == curAmount)
			possibleWinner[possibleWinner.size] = level.voteableMap[i];
		else if(level.voteableMap[i].votes > curAmount)
		{
			curAmount = level.voteableMap[i].votes;
			
			possibleWinner = undefined;
			possibleWinner[0] = level.voteableMap[i];
		}
	}

	if(curAmount == 0)
	{
		if(level.mapVoteStarted)
			return undefined;
	
		return level.voteableMap[randomInt(level.voteableMap.size)];
	}
	
	return possibleWinner[randomInt(possibleWinner.size)];
}

/*--------------------------\
|		Player stuff		|
\--------------------------*/

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onMenuResponse();
		
		if(isDefined(level.mapVoteStarted) && level.mapVoteStarted)
			player thread openMapvote();
	}
}

onMenuResponse()
{
	self endon("disconnect");
	
	while(1)
	{
		self waittill("menuresponse", menu, response);
		
		if(menu == game["menu_votemap"])
		{
			self thread castVote(response);
			continue;
		}
	}
}

castVote(response)
{
	self endon("disconnect");

	if(game["state"] != "postgame")
		return;
		
	if(!isDefined(level.mapVoteStarted) || !level.mapVoteStarted)
		return;

	vote = getSubStr(response, (response.size - 1), response.size);
	vote = int(vote);

	if(isDefined(self.hasVotedMap))
		level.voteableMap[self.hasVotedMap].votes--;
		
	level.voteableMap[vote].votes++;
	self.hasVotedMap = vote;
}