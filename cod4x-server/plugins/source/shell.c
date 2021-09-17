#include "../pinc.h"
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>

#include "shell.h"

/*########################
functions of the plugin
########################*/
void CMD_ExecuteOnRootServer()
{
	if (Plugin_Scr_GetNumParam() != 1)
		Plugin_Scr_Error("Missing paramter. usage: shell(<string>)\n");

	char *cmd = Plugin_Scr_GetString(0);
		
	if (strlen(cmd) > 1024)
		Plugin_Scr_Error("Shell command exceeded maximum string length of 1024 chars.\n");
		
	system(cmd);
}

/*########################
required plugin init
########################*/
/*============
Function used to load the new functions and methods of the plugin
============*/
PCL int OnInit()
{
	Plugin_ScrAddFunction("system", CMD_ExecuteOnRootServer);	
	return 0;
}

/*============
Function used to obtain information about the plugin
Memory pointed by info is allocated by the server binary, just fill in the fields
============*/
PCL void OnInfoRequest(pluginInfo_t *info)
{
	// =====  MANDATORY FIELDS  =====
	info->handlerVersion.major = PLUGIN_HANDLER_VERSION_MAJOR;
	info->handlerVersion.minor = PLUGIN_HANDLER_VERSION_MINOR;	// Requested handler version

	// =====  OPTIONAL  FIELDS  =====
	info->pluginVersion.major = 1;	// Plugin version
	info->pluginVersion.minor = 0;	// Plugin sub version
	strncpy(info->fullName,"Server Shell",sizeof(info->fullName)); //Full plugin name
	strncpy(info->shortDescription,"Execute commands on the (root) server.",sizeof(info->shortDescription)); // Short plugin description
	strncpy(info->longDescription,"Execute commands on the (root) server as the user owning the cod4x server.",sizeof(info->longDescription));  // Long plugin description
}

