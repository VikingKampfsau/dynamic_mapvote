init()
{
	game["menu_votemap"] = "votemap";
	precacheMenu(game["menu_votemap"]);

	thread initMapvote();
}

/*--------------------------\
|		Mapvote itself		|
\--------------------------*/

initMapvote()
{
	if(getDvarInt("mapvote_votetime") <= 0)	setDvar("mapvote_votetime", 15);
	if(getDvarInt("mapvote_voteableItems") < 2) setDvar("mapvote_voteableItems", 2);
	if(getDvarInt("mapvote_voteableItems") > 9) setDvar("mapvote_voteableItems", 9);

	level.mapvote_voteableItems = getDvarInt("mapvote_voteableItems");
	level.mapvote_mapsToVote = [];
	level.mapVoteStarted = false;
	level.mapvote_votetime = getDvarInt("mapvote_votetime");
	
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
		thread openMapvote();
		thread updateCastVotes();
		wait level.mapvote_votetime;
		thread closeMapvote();
			
		winner = GetVoteWinner();
		iPrintLnBold("Next map: " + winner);
		
		setDvar("sv_maprotation","gametype " + level.gametype + " map " + winner);
		setDvar("sv_maprotationcurrent", "gametype " + level.gametype + " map " + winner);
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
	FS_WriteLine(config, "set mapvote_voteableItems " + level.mapvote_voteableItems);
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
	
		//when the map has no loadscreen image then use an empty one
		if(!fs_testFile(filePathWithName))
			filePathWithName = "/mapvote/images/empty.iwi";

		//abort when the empty image is not found
		if(!fs_testFile(filePathWithName))
		{
			//iPrintLnBold("image file not found for " + level.mapvote_mapsToVote[i]);
			return;
		}
		
		//copy the images to a temp folder
		system("mkdir -p " + serverAndModPath + targetPathNoName);
		system("cp " + serverAndModPath + filePathWithName + " " + serverAndModPath + targetPathWithName);
	}
	
	//create a new mapvote.iwd from temp, containing the images and the config
	system("cd " + serverAndModPath + "/mapvote/temp;zip -r ../../mapvote.iwd *");
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
	
		for(i=0;i<9;i++)
		{
			if(!getMapsFromConfig)
				map = getDvar("mapvote_map" + i);
			else
				map = maps[i];
			
			setDvar("mapvote_map" + i, "");
			
			if(!isDefined(map) || map == "" || map == " ")
				continue;
		
			level.voteableMap[i] = spawnStruct();
			level.voteableMap[i].name = map;
			level.voteableMap[i].votes = 0;
		}
	}
}

openMapvote()
{
	level.mapVoteStarted = true;

	if(isDefined(self) && isPlayer(self))
	{
		self setClientDvars("mapvote_votetime", level.mapvote_votetime,
							"mapvote_voteableItems", level.mapvote_voteableItems);

		self closeMenu();
		self closeInGameMenu();
		self notify("reset_outcome");
		self openMenu(game["menu_votemap"]);
	}
	else
	{
		for(i=0;i<level.players.size;i++)
		{
			level.players[i] setClientDvars(
							"mapvote_votetime", level.mapvote_votetime,
							"mapvote_voteableItems", level.mapvote_voteableItems);

	
			level.players[i] closeMenu();
			level.players[i] closeInGameMenu();
			level.players[i] notify("reset_outcome");
			level.players[i] openMenu(game["menu_votemap"]);
		}
	}
}

closeMapvote()
{
	level.mapVoteStarted = false;

	for(i=0;i<level.players.size;i++)
	{
		level.players[i] closeMenu();
		level.players[i] closeInGameMenu();
	}
}

updateCastVotes()
{
	while(level.mapvote_votetime > 0)
	{
		if(level.mapvote_votetime == int(level.mapvote_votetime))
		{
			for(i=0;i<level.players.size;i++)
			{
				level.players[i] setClientDvars(
									"votes_mapvote_map0", level.voteableMap[0].votes,
									"votes_mapvote_map1", level.voteableMap[1].votes,
									"votes_mapvote_map2", level.voteableMap[2].votes,
									"votes_mapvote_map3", level.voteableMap[3].votes,
									"votes_mapvote_map4", level.voteableMap[4].votes,
									"votes_mapvote_map5", level.voteableMap[5].votes,
									"votes_mapvote_map6", level.voteableMap[6].votes,
									"votes_mapvote_map7", level.voteableMap[7].votes,
									"votes_mapvote_map8", level.voteableMap[8].votes);
			}
		}
	
		wait .05;
		
		//minus 0.01 sometimes results is bad float value
		//example: 3 - 0.01 = 2.899999
		//to avoid that I go this way
		level.mapvote_votetime *= 1000;
		level.mapvote_votetime -= 50;
		level.mapvote_votetime /= 1000;
	}
}

GetVoteWinner()
{
	possibleWinner = [];

	if(!level.players.size)
		return level.voteableMap[randomInt(level.voteableMap.size)].name;

	curAmount = 0;
	for(i=0;i<level.voteableMap.size;i++)
	{
		if(level.voteableMap[i].votes == curAmount)
			possibleWinner[possibleWinner.size] = level.voteableMap[i].name;
		else if(level.voteableMap[i].votes > curAmount)
		{
			curAmount = level.voteableMap[i].votes;
			
			possibleWinner = undefined;
			possibleWinner[0] = level.voteableMap[i].name;
		}
	}

	if(curAmount == 0)
		return level.voteableMap[randomInt(level.voteableMap.size)].name;
	
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