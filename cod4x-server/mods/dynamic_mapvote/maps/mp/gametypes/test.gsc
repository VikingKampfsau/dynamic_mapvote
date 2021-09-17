init()
{
	/*
	thread maps\mp\gametypes\testclients::init();
	
	while(!isDefined(level.players) || level.players.size < 2)
		wait 1;
	*/

	thread initMapvote();
}

initMapvote()
{
	for(i=0;i<9;i++)
		setDvar("mapvote_map" + i, "");

	if(getDvarInt("mapvote_voteableItems") < 2) setDvar("mapvote_voteableItems", 2);
	if(getDvarInt("mapvote_voteableItems") > 9) setDvar("mapvote_voteableItems", 9);

	level.mapvote_voteableItems = getDvarInt("mapvote_voteableItems");
	level.mapvote_mapsToVote = [];
	
	//wait until the end of the current map
	//this waittill is for debugging - later we might need a better one
	level waittill("give_match_bonus");
	
	prepareNextMapvote();
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
	setVoteableMapDvars();

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
			iPrintLnBold("image file not found for " + level.mapvote_mapsToVote[i]);
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

setVoteableMapDvars()
{
	//for debugging i force maps here
	setDvar("mapvote_map0", "mp_convoy");
	setDvar("mapvote_map1", "mp_backlot");
	setDvar("mapvote_map2", "mp_vacant");
	setDvar("mapvote_map3", "mp_bloc");
	setDvar("mapvote_map4", "mp_shipment");
	setDvar("mapvote_map5", "mp_crash");
	setDvar("mapvote_map6", "mp_crash_snow");
	setDvar("mapvote_map7", "mp_bog");
	setDvar("mapvote_map8", "mp_creek");
}
