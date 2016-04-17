local exoticlib = include("exoticlib.lua")

function readCfg(portion)
	textdata = file.Read("autoadmincfg.txt")
	portions = string.Explode("-- SPLIT CFG --", textdata)
	if (portion == "AUTOCENSOR") then return(portions[4])
	elseif (portion == "AUTOCENSORCFG") then return(portions[3])
	elseif (portion == "ANTISPAM") then return(portions[1])
	elseif (portion == "ANTIGHOST") then return(portions[2])
	end
end

function censor(ply, text, public)
	if (file.Exists("autoadmincfg.txt","DATA")) then
		textdata = readCfg("AUTOCENSOR")
		cfg = readCfg("AUTOCENSORCFG")
		RunString(cfg)
		if enabled then
			cfgs = string.Explode("\n", textdata)   
			for i, line in ipairs(cfgs) do
				if (line ~= nil and line ~= "") then
					data = string.Explode(";", line)
					bannedword = data[1]
					timeoutlength = 1
					if tonumber(timeoutlength) == nil then
						timeoutlength = 1
					else
						timeoutlength = tonumber(data[2])
					end
					if (string.find(string.lower(text),bannedword) and timeoutlength ~= nil) then
						if (timeoutlength >= 0) then
							RunConsoleCommand("ulx", "mute", ply:Name())
							PrintMessage(HUD_PRINTTALK, ply:Name().. " has been automatically muted for "..timeoutlength.." seconds for using a banned word/phrase.")
							timer.Create("AutoUnmute",timeoutlength,1,function() RunConsoleCommand("ulx", "unmute", ply:Name()) end)
							return(false)
						else
							RunConsoleCommand("ulx", "mute", ply:Name())
							PrintMessage(HUD_PRINTTALK, ply:Name().. " has been automatically muted indefinitely for using a banned word/phrase.")
							return(false)
						end
					end
				end
			end
		end
	else
		PrintMessage(HUD_PRINTTALK, "Configuration file for AutoAdmin (autoadmincfg.txt) has been created in your server's garrysmod/data folder! To add new banned words/phrases, put them on a new line in the file like this!")
		PrintMessage(HUD_PRINTTALK, "banned word or phrase;amount of time (in seconds)")
		PrintMessage(HUD_PRINTTALK, "EXAMPLE: Hello World!;300")
		PrintMessage(HUD_PRINTTALK, "The above example mutes whoever says 'Hello World!' for 300 seconds.")
		file.Write("autoadmincfg.txt","llama;10")
	end
end
chats = {}
function chatspam(ply, text, public)
	textdata = readCfg("ANTISPAM")
	RunString(textdata)
	if (enabled == true) then
		if (chats[ply:SteamID()] != nil) then
			chats[ply:SteamID()] = chats[ply:SteamID()] + 1
		else
			chats[ply:SteamID()] = 1
		end
		timer.Create("chatspamclear",spamperiod,0,function() chats = {} end)
		if (chats[ply:SteamID()] >= amounttomute) then
			PrintMessage(HUD_PRINTTALK, ply:Name().. " has been automatically muted for ".. mutetime .." seconds for spamming chat.")
			RunConsoleCommand("ulx", "mute", ply:Name())
			timer.Create("AutoUnmute",mutetime,1,function() RunConsoleCommand("ulx", "unmute", ply:Name()) end)
			chats[ply:SteamID()] = 0
			return(false)
		end
	else return(true) end
end

function antighost(ply, commandName, translated_args)
	antighostcfg = readCfg("ANTIGHOST")
	RunString(antighostcfg)
	if (enabled == true) then
		if (commandName == "ulx psay") then
			ply2 = translated_args[2]
			msg = translated_args[3]
			if (ply:Alive() == false and ply2:Alive() == true) then 
				for i, line in ipairs(blacklist) do
					if (line ~= nil and line ~= "") then
						returnedstring, amount = string.gsub(msg,line,line)
						if (amount > 0) then
							staff = exoticlib.checkPlayerRanks(rankstoinformofwarn,player.GetAll())
							if periodbeforewarn > 0 then
								for i, player in ipairs(staff) do
									ply:PrintMessage(HUD_PRINTTALK,"AUTOADMIN ANTIGHOST: "..ply:Name().." has triggered ANTIGHOST with the following message which was sent to "..ply2:Name()..": ".."'"..msg.."'")
									ply:PrintMessage(HUD_PRINTTALK,ply:Name().." will be automatically warned for Ghosting in "..periodbeforewarn.." second(s). Type '!antighost_stop "..ply:Name().."' to stop this from happening.")
								end
								timer.Create("ANTIGHOST"..ply:Name(),periodbeforewarn,1,function() RunConsoleCommand("awarn_warn", ply:Name(), "Ghosting (AUTOMATED)") end)
							else RunConsoleCommand("awarn_warn", ply:Name(), "Ghosting (AUTOMATED)") end
							return
						end
					end
				end
			else
				return
			end
		else
			return
		end
	else return end
end

function chatCommand(ply, text, public)
    if (string.sub( string.lower(text), 1, 15) == "!antighost_stop" and table.HasValue(rankstoinformofwarn,ply:GetNWString("usergroup"))) then
			antighostcfg = readCfg("ANTIGHOST")
			RunString(antighostcfg)
			args = text:gsub("!antighost_stop ","")
			if (timer.Exists("ANTIGHOST"..args) == true) then
				timer.Remove("ANTIGHOST"..args)
			end
        return(false)
    end
end
hook.Add("PlayerSay", "chatCommand", chatCommand);

hook.Add("PlayerSay", "censor", censor)
hook.Add("PlayerSay", "chatspam", chatspam)
hook.Add("ULibPostTranslatedCommand", "antighost", antighost)
