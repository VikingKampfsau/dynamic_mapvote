init()
{
	game["menu_team"] = "team_marinesopfor";
	game["menu_class_allies"] = "class_marines";
	game["menu_changeclass_allies"] = "changeclass_marines_mw";
	game["menu_class_axis"] = "class_opfor";
	game["menu_changeclass_axis"] = "changeclass_opfor_mw";
	game["menu_class"] = "class";
	game["menu_changeclass"] = "changeclass_mw";
	game["menu_changeclass_offline"] = "changeclass_offline";

	game["menu_votemap"] = "votemap"; precacheMenu(game["menu_votemap"]);
	game["menu_callvote"] = "callvote";
	game["menu_muteplayer"] = "muteplayer";
	precacheMenu(game["menu_callvote"]);
	precacheMenu(game["menu_muteplayer"]);
	
	// game summary popups
	game["menu_eog_unlock"] = "popup_unlock";
	game["menu_eog_summary"] = "popup_summary";
	game["menu_eog_unlock_page1"] = "popup_unlock_page1";
	game["menu_eog_unlock_page2"] = "popup_unlock_page2";
	
	precacheMenu(game["menu_eog_unlock"]);
	precacheMenu(game["menu_eog_summary"]);
	precacheMenu(game["menu_eog_unlock_page1"]);
	precacheMenu(game["menu_eog_unlock_page2"]);

	//Lepko
	precacheMenu("gg_welcome_menu");
	precacheMenu("popup_addfavorite");
	precacheMenu("changemodel_marines");
	precacheMenu("changemodel_opfor");
	//End Lepko

	precacheMenu("scoreboard");
	precacheMenu(game["menu_team"]);
	precacheMenu(game["menu_class_allies"]);
	precacheMenu(game["menu_changeclass_allies"]);
	precacheMenu(game["menu_class_axis"]);
	precacheMenu(game["menu_changeclass_axis"]);
	precacheMenu(game["menu_class"]);
	precacheMenu(game["menu_changeclass"]);
	precacheMenu(game["menu_changeclass_offline"]);
	precacheString( &"MP_HOST_ENDED_GAME" );
	precacheString( &"MP_HOST_ENDGAME_RESPONSE" );

	game["menu_vision"] = "vision_settings"; precacheMenu(game["menu_vision"]);

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		
		player setClientDvar("ui_3dwaypointtext", "1");
		player.enable3DWaypoints = true;
		player setClientDvar("ui_deathicontext", "1");
		player.enableDeathIcons = true;
		player.classType = undefined;
		player.selectedClass = false;
		
		player thread onMenuResponse();
	}
}

onMenuResponse()
{
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("menuresponse", menu, response);
		
		iprintlnbold( self getEntityNumber() + " menuresponse: " + menu + " " + response );
		
		if ( response == "vision" )
		{
			self closeMenu();
			self closeInGameMenu();

			self openMenu(game["menu_vision"]);
		}
		if(menu == game["menu_vision"])
		{
			if(response == "vision_settings_reset")
			{
				self setClientDvars(
					"cg_fov", self GetUserinfo("temp_cg_fov"),
					"cg_fovscale", self GetUserinfo("temp_cg_fovscale"),
					"r_fullbright", self GetUserinfo("temp_r_fullbright"));
			}
			else if(response == "vision_settings_closed")
			{
				iPrintLnBold("cg_fov is " + self GetUserinfo("temp_cg_fov"));
				iPrintLnBold("cg_fovscale is " + self GetUserinfo("temp_cg_fovscale"));
				iPrintLnBold("r_fullbright is " + self GetUserinfo("temp_r_fullbright"));
			}
		
			continue;
		}
		
		
		
		//iprintln( self.name + " menuresponse: " + menu + " " + response );
			
		if ( response == "back" )
		{
			self closeMenu();
			self closeInGameMenu();
			continue;
		}
		
		if( getSubStr( response, 0, 7 ) == "loadout" )
		{
			continue;
		}
		
		if( response == "changeteam" )
		{
			self closeMenu();
			self closeInGameMenu();
			self openMenu(game["menu_team"]);
		}
		
		if( response == "openvote" )
		{
			self closeMenu();
			self closeInGameMenu();
			self openMenu(game["menu_votemap"]);
		}
	
		if( response == "changeclass_marines" )
		{
			self closeMenu();
			self closeInGameMenu();
			continue;
		}

		if( response == "changeclass_opfor" )
		{
			self closeMenu();
			self closeInGameMenu();
			continue;
		}
				
		if( response == "endgame" )
		{
			continue;
		}

		if( menu == game["menu_team"] )
		{
			switch(response)
			{
				case "allies":
					self closeMenu();
					self closeIngameMenu();
					self openMenu("changemodel_marines");
					break;
	
				case "axis":
					self closeMenu();
					self closeIngameMenu();
					self openMenu("changemodel_opfor");
					break;
	
				case "autoassign":
					self [[level.autoassign]]();
					break;
	
				case "spectator":
					self [[level.spectator]]();
					break;
			}
			continue;
		}

		if( menu == "changemodel_marines" )
		{
			self.pers["gg_model_number"] = int( response );
			self [[level.allies]]();

			continue;
		}
		else if( menu == "changemodel_opfor" )
		{
			self.pers["gg_model_number"] = int( response );
			self [[level.axis]]();

			continue;
		}

		if(menu == game["menu_quickcommands"])
			maps\mp\gametypes\_quickmessages::quickcommands(response);
		else if(menu == game["menu_quickstatements"])
			maps\mp\gametypes\_quickmessages::quickstatements(response);
		else if(menu == game["menu_quickresponses"])
			maps\mp\gametypes\_quickmessages::quickresponses(response);

	}
}
