-- ***************************************************************************************************************************************************
-- * GuildDing.lua                                                                                                                                         *
-- ***************************************************************************************************************************************************
-- * Guild levelup announcer                                                                                                                         *
-- ***************************************************************************************************************************************************
-- * 0.2.0 / 2014.07.08 / Calystos                                                                                                                   *
-- ***************************************************************************************************************************************************

-------------------------------------------------------------------------------

-- Setup various local/global addon variables
local addonInfo, Internal = ...
local addonID = addonInfo.identifier
local addonVER = addonInfo.toc.Version

_GUILDDING = { UI = {} }
local GD = _GUILDDING

-- A few shortcuts to the various API function calls
local CEAttach = Command.Event.Attach
local CMBroadcast = Command.Message.Broadcast
local CMAccept = Command.Message.Accept
local CMSend = Command.Message.Send
local IUDetail = Inspect.Unit.Detail
local IGRDetail = Inspect.Guild.Roster.Detail

-- Local addon global variables
Player = IUDetail("player")
GPlayer = IGRDetail(Player.name)
local userRL = 0
if GPlayer then
	userRL = GPlayer.level
end
local thisUpdate = 0
local lastUpdate = 0
local gd_expire = 0
local minLevel = 15
local OSDMinSize = 10
local OSDMaxSize = 30
local OSDDefSize = 26
local OSDMinCol = 0
local OSDMaxCol = 1
local OSDDefColour = "1 0 1"
local ChatMinCol = 0
local ChatMaxCol = 255
local ChatDefColour = "FF00FF"

-- Addon/User settings variables
local BCDing = true
local OSDDing = true
local ChatDing = true
local debug = false
local OSDSize = 26
local OSDColour = {r = 1, g = 0, b = 1}
local ChatColour = "FF00FF"

-- Addon base shortcut commands
local SlashCommand = "gd"

-------------------------------------------------------------------------------

function round(num, digits)
	local mult = 10^(digits or 0)
	return math.floor(num * mult + .5) / mult
end

-- colour format can be 0->1 (0.5, 0.25, 1), or 0->255 (255, 57, 128), or 00->FF (D3, 0F, FF)
-- "<font color=\"#FFD100\">"
-- "<font color=\"#%02x%02x%02x\", from[1], from[2], from[3]
-- Convert decimal format to hex format, 1 1 1 == FFFFFF
function decToHex(tbl)
	return ("%02X%02X%02X"):format(round(tbl[1] * 255), round(tbl[2] * 255), round(tbl[3] * 255))
end

-- Print a message to chat, much better way than using "print", tag can be either true/false to display addon name at start of text
local function notify(text, tag)
	for id, test in pairs(Inspect.Console.List()) do
		-- Ignore combat tab
		if Inspect.Console.Detail(id).name ~= "*Combat" then
			Command.Console.Display(id, tag, "<font color=\"#FFD100\">" .. text .. "</font>", true)
		end
	end
end

-------------------------------------------------------------------------------

-- Run all the things needed during addon loading, setup/config stuff
local function LoadStart()
	-- Create & setup the OSD/HUD frame for text output/etc
	GD.UI.context = UI.CreateContext(addonID)

	GD.UI.LevelUp = UI.CreateFrame("Text", "GD.UI.LevelUp", GD.UI.context)
	GD.UI.LevelUp:SetVisible(true)
	GD.UI.LevelUp:SetPoint("TOPCENTER", UIParent, "TOPCENTER", 0, 150)
	GD.UI.LevelUp:SetFontSize(OSDSize)
	GD.UI.LevelUp:SetFontColor(OSDColour.r, OSDColour.g, OSDColour.b)
	GD.UI.LevelUp:SetText("")
	GD.UI.LevelUp:SetEffectGlow({strength=48, blurX=24, blurY=24})
end

-------------------------------------------------------------------------------

-- Run all the things needed after the users data/character is fully loaded
local function UnitReady(handle)
	-- Retrieve the players guild roster data
	GPlayer = IGRDetail(Player.name)
	-- Make sure player is in a guild
	if GPlayer == nil then
		if debug == true then
			notify("Guild Ding: No guild information detected", true)
		end
	else
		-- Make a note of the players actual/real current level (guild roster player level does not change regardless of mentoring level)
		userRL = GPlayer.level
	end
end

-------------------------------------------------------------------------------

-- Run all the things needed after the addon is fully loaded
local function ConsoleLoadEnd(handle)
	--if GPlayer == nil then
		--notify(string.format("Guild Ding: v%s loaded. No Guild detected! GuildDing will not work unless you are in a Guild!", addonVER), true)
	--else
		LibVersionCheck.register(addonID, addonVER)
		notify(string.format("Guild Ding: v%s loaded. Use /gd for slash commands list.", addonVER), true)
	--end
end

-------------------------------------------------------------------------------

-- Run timer updates, this is called every second
local function SystemTick(handle)
	thisUpdate = Inspect.Time.Frame()

	if thisUpdate - lastUpdate >= 1 then
		local td = gd_expire - thisUpdate

		if td <= 5 and td > 0 then
			GD.UI.LevelUp:SetVisible(true)
		else
			GD.UI.LevelUp:SetVisible(false)
		end

		lastUpdate = thisUpdate
	end
end

-------------------------------------------------------------------------------

-- A mentor level alteration has occurred, check its data
local function MentoredCheck()
	if Player and Player.mentoring == false then
		-- Should we re-get the roster info? WIBBLE
		GPlayer = IGRDetail(Player.name)

		if GPlayer == nil then
			if debug == true then
				notify("Guild Ding: No guild information detected", true)
			end
		else
			-- userRL = Player.level
			userRL = GPlayer.level
		end

		if debug == true then
			notify(tostring(userRL), true)
		end
	end
end

-------------------------------------------------------------------------------
local function LevelUpdate(memberID)
	if type(memberID) ~= "string" then return end

	-- Should we re-get the roster info? WIBBLE
	GPlayer = IGRDetail(Player.name)
	MPlayer = IGRDetail(memberID)

	-- This should never happen
	if Player == nil then
		if debug == true then
			notify("Guild Ding: No player information detected", true)
		end
		return
	end

	-- This should only happen if the user is not in any guild
	if GPlayer == nil then
		if debug == true then
			notify("Guild Ding: No guild information detected", true)
		end
		return
	end

	-- This should only happen if the user is not in any guild
	if MPlayer == nil then
		if debug == true then
			notify("Guild Ding: No guild information detected", true)
		end
		return
	end

	if Player.name ~= MPlayer.name then
		if debug == true then
			notify("Guild Ding: Someone else has levelled up", true)
		end
		return
	end

	level = GPlayer.level

	-- Debug code output, incase of problems
	if debug == true then
		-- Display the users name, the users guild roster name, and the expected guild roster name, these should all match
		notify(string.format("Player.name: %s, GPlayer.name: %s, MPlayer.name: %s", Player.name, GPlayer.name, MPlayer.name), true)
		-- Display the users name, mentoring status, detected player level, guild roster level, backup level, and detected current level
		notify(string.format("Player: %s (mentoring: %s) - PLvl: %s, GPLvl: %s, uRLvl: %s, Lvl: %s", Player.name, tostring(Player.mentoring), tostring(Player.level), tostring(GPlayer.level), tostring(userRL), tostring(level)), true)
	end

	-- BUG HERE WIBBLE
--	if level <= userRL then
--		if debug == true then
--			notify(string.format("Guild Ding: No actual level change occurred. Lvl: %d, uRLvl: %d", tostring(level), tostring(userRL)), true)
--		end
--		return
--	end

	-- Backup/store the current actual level for future comparison
--	userRL = level

	if BCDing == false then
		if debug == true then
			notify("Guild Ding: Broadcasting of ding is disabled", true)
		end
		return
	end

	if level >= minLevel then
		local data = string.format("DING! %s is now level %d!", Player.name, level)

		CMBroadcast("guild", nil, "GuildDing", data, function(failure, data) end);
		if debug == true then
			notify(data, true);
		end
	end
end

-- Level change has occurred
local function RosterLevelUpdate(h, changes)
	for memberID in pairs(changes) do
		print(memberID)
		LevelUpdate(memberID)
	end
end

-- Level change has occurred, check if its a level up or just a mentor level alteration
local function PlayerLevelUpdate()
	-- Should we re-get the roster info? WIBBLE
	GPlayer = IGRDetail(Player.name)

	-- This should never happen
	if Player == nil then
		if debug == true then
			notify("Guild Ding: No player information detected", true)
		end
		return
	end

	-- This should only happen if the user is not in any guild
	if GPlayer == nil then
		if debug == true then
			notify("Guild Ding: No guild information detected", true)
		end
		return
	end

--[[
upon first connect, store users current/real level
upon level up or mentor level change check users guild level against stored level, if guild level higher than level up has occurred

]]--

	-- level = Player.level
	level = GPlayer.level

	-- Need check against Mentor, display only actual/real level info
--	if Player.mentoring == true then
--		level = GPlayer.level
--	else
		-- Need check against levels, to make sure we're only dinging when an actual level up occurs and not just coming out of mentoring
		-- if level >= userRL then
			-- return
		-- end
--		-- userRL = GPlayer.level
--		level = GPlayer.level
--	end

	-- Debug code output, incase of problems
	if debug == true then
		-- Display the users name
		notify(Player.name, false)
		-- Display the users mentoring status (nil/true)
		notify(tostring(Player.mentoring), false)
		-- Display the users player level (this would also alter depending on mentoring?)
		notify(tostring(Player.level), false)
		-- Display the users actual level (gathered from guild data which does not change when mentoring)
		notify(tostring(GPlayer.level), false)
		-- Previously stored users level, for checking of actual level changes
		notify(tostring(userRL), false)
		-- Detected level from this function
		notify(tostring(level), false)
	end

	-- BUG HERE WIBBLE
	if level <= userRL then
		if debug == true then
			notify("Guild Ding: No actual level change occurred", true)
		end
		return
	end

	-- Backup/store the current actual level for future comparison
	userRL = level

	if BCDing == false then
		if debug == true then
			notify("Guild Ding: Broadcasting of ding is disabled", true)
		end
		return
	end

	if level >= minLevel then
		local data = string.format("DING! %s is now level %d!", Player.name, level)

		CMBroadcast("guild", nil, "GuildDing", data, function(failure, data) end);
		if debug == true then
			notify(data, true);
		end
	end
end

-------------------------------------------------------------------------------

-- Parse received addon-to-addon messages
local function OnMessage(h, from, msgType, channel, identifier, data)
	if msgType == "guild" and identifier == "GuildDing" then
		-- Only display OSD if setting enabled
		if OSDDing then
			gd_expire = Inspect.Time.Frame() + 6
			lastUpdate = 0
			GD.UI.LevelUp:SetText(data)
			GD.UI.LevelUp:SetAlpha(1)
			CEAttach(Event.System.Update.Begin, SystemTick, addonID .. "Event.System.Update.Begin")
		end

		-- Only display in chat if setting enabled
		if ChatDing then
			notify(data, true);
		end
	end
end

-------------------------------------------------------------------------------

-- Toggle broadcasting level changes
local function toggleBCDing()
	if BCDing == false then
		BCDing = true
		notify("Guild Ding: Broadcasting Own Dings enabled", true)
	else
		BCDing = false
		notify("Guild Ding: Broadcasting Own Dings disabled", true)
	end
end

-------------------------------------------------------------------------------

-- Toggle OSD (On Screen Display) output
local function toggleOSDDing()
	if OSDDing == false then
		OSDDing = true
		notify("Guild Ding: On-Screen Display Dings enabled", true)
	else
		OSDDing = false
		notify("Guild Ding: On-Screen Display Dings disabled", true)
	end
end

-------------------------------------------------------------------------------

-- Toggle chat window output
local function toggleChatDing()
	if ChatDing == false then
		ChatDing = true
		notify("Guild Ding: Chat Display Dings enabled", true)
	else
		ChatDing = false
		notify("Guild Ding: Chat Display Dings disabled", true)
	end
end

-------------------------------------------------------------------------------

-- Change/Set the font size for OSD message outputs
local function setOSDSize(size)
	if not size then
		notify("Guild Ding: Invalid OSD Font Size given, must be between " .. OSDMinSize .. " and " .. OSDMaxSize, true)
		return
	end

	if tonumber(size) < OSDMinSize then
		notify("Guild Ding: OSD Font Size needs to be at least " .. OSDMinSize, true)
	elseif tonumber(size) > OSDMaxSize then
		notify("Guild Ding: OSD Font Size needs to be at most " .. OSDMaxSize, true)
	else
		OSDSize = tonumber(size)
		GD.UI.LevelUp:SetFontSize(OSDSize)
		notify("Guild Ding: OSD Font Size changed to " .. OSDSize .. " (default: " .. OSDDefSize .. ")", true)
	end
end

-------------------------------------------------------------------------------

-- Change/Set the font colour for OSD message outputs
local function setOSDColour(red, green, blue)
	if not red or not green or not blue then
		notify("Guild Ding: Invalid OSD Font Colours given, must be in R G B format (default: " .. OSDDefColour .. ")", true)
		return
	end

	if tonumber(red) < 0 or tonumber(red) > 1 then
		notify("Guild Ding: OSD Font Colour Red needs to be between " .. OSDMinCol .. " and " .. OSDMaxCol, true)
		return
	elseif tonumber(green) < 0 or tonumber(green) > 1 then
		notify("Guild Ding: OSD Font Colour Green needs to be between " .. OSDMinCol .. " and " .. OSDMaxCol, true)
		return
	elseif tonumber(blue) < 0 or tonumber(blue) > 1 then
		notify("Guild Ding: OSD Font Colour Blue needs to be between " .. OSDMinCol .. " and " .. OSDMaxCol, true)
		return
	end

	OSDColour.r = tonumber(red)
	OSDColour.g = tonumber(green)
	OSDColour.b = tonumber(blue)
	GD.UI.LevelUp:SetFontColor(OSDColour.r, OSDColour.g, OSDColour.b)
	notify("Guild Ding: OSD Font Colour changed to: " .. red .. " " .. green .. " " .. blue .. " (default: " .. OSDDefColour .. ")", true)
end

-------------------------------------------------------------------------------

-- Change/Set the font colour for chat message outputs
local function setChatColour(textcol)
	-- Check if textcol is hex or dec
	-- Split up textcol to verify each item is valid

	if not textcol then
		notify("Guild Ding: Invalid Chat Font Colours given, must be in RRGGBB (hex) format or RR GG BB (dec) (hex default: " .. ChatDefColour .. ")", true)
		return
	end

--	if tonumber(textcol) < 0 or tonumber(textcol) > 255 then
--		notify("Guild Ding: Chat Font Colour needs to be between " .. ChatMinCol .. " and " .. ChatMaxCol, true)
--		return
--	end

	ChatColour = tostring(textcol)
	notify("Guild Ding: Chat Font Colour changed to: " .. ChatColour .. " (default: " .. ChatDefColour .. ")", true)
end

-------------------------------------------------------------------------------

-- Run a self test, displays only to local user does not broadcast
local function runSelfTest()
	notify("Guild Ding: Running local self test", true)

	local data = string.format("DING! %s is now level %d!", Player.name, userRL)

	if OSDDing then
		gd_expire = Inspect.Time.Frame() + 6
		lastUpdate = 0
		GD.UI.LevelUp:SetText(data)
		GD.UI.LevelUp:SetAlpha(1)
		CEAttach(Event.System.Update.Begin, SystemTick, addonID .. "Event.System.Update.Begin")
	end

	if ChatDing then
		notify(data, true);
	end
end

-------------------------------------------------------------------------------

-- Toggle debug mode setting
local function toggleDebug()
	if debug == false then
		debug = true
		notify("Guild Ding: Debug mode enabled", true)
	else
		debug = false
		notify("Guild Ding: Debug mode disabled", true)
	end
end

-------------------------------------------------------------------------------

-- Simply display the addons options/settings information
local function printStatus()
	notify("Guild Ding Settings Status:", true)
	notify("    BroadCasting Dings: " .. tostring(BCDing), true)
	notify("    On-Screen Display: " .. tostring(OSDDing), true)
	notify("    Chat Display: " .. tostring(ChatDing), true)
	notify("    OSD Size: " .. tostring(OSDSize), true)
	notify("    OSD Colour: " .. tostring(OSDColour.r) .. " " .. tostring(OSDColour.g) .. " " .. tostring(OSDColour.b), true)
	notify("    Chat Colour: " .. tostring(ChatColour), true)
	notify("    Debug Mode: " .. tostring(debug), true)
end

-------------------------------------------------------------------------------

-- Simply display the addons version information
local function printVersion()
	LibVersionCheck.register(addonID, addonVER)
	notify("Guild Ding: v" .. addonVER .. " loaded.", true)
end

-------------------------------------------------------------------------------

-- Display the total slash commands output for all commands
local function helpInfo()
	notify("Guild Ding: Usage: /gd help | version | status | bc | osd | chat | size | osdcol | chatcol | test | debug", true)
	notify("    help - Display this help information on all commands", true)
	notify("    version - Display version information", true)
	notify("    status - Display current options/settings information", true)
	notify("    bc - Toggle broadcasting own level up announcement", true)
	notify("    osd - Toggle OSD level up announcement", true)
	notify("    chat - Toggle Chat level up announcement", true)
	notify("    size [size] - Change/set the OSD font size", true)
	notify("    osdcol [R G B] - Change/set the OSD font colour (rgb value)", true)
	notify("    chatcol [RRGGBB or RR GG BB] - Change/set the chat font colour (hex or dec value)", true)
	notify("    test - Run a self/local test to display current settings output", true)
	notify("    debug - Toggle debug mode setting", true)
end

-------------------------------------------------------------------------------

-- Parse any slash commands we receive
local function slashHandler(h, args)
	local r = {}
	local numargs = 1
	local inquote = false
	local token, tmptoken
	for token in string.gmatch(args, "[^%s]+") do
		if token:sub(1, 1) == "\"" then
			tmptoken=""
			token=token:sub(2) -- handle "abc" case
			inquote=true
		end
		if inquote then
			if token:sub(-1) == "\"" then
				inquote=false
				token=token:sub(1, -2)
				token=tmptoken .. token
			else
				tmptoken=tmptoken .. token .. " "
			end
		end
		if not inquote then
			r[numargs] = token
			numargs=numargs+1
		end
	end
	if numargs>1 then
		if r[1] == "help" then
			helpInfo()
		elseif r[1] == "version" then
			printVersion()
		elseif r[1] == "status" then
			printStatus()
		elseif r[1] == "bc" then
			toggleBCDing()
		elseif r[1] == "osd" then
			toggleOSDDing()
		elseif r[1] == "chat" then
			toggleChatDing()
		elseif r[1] == "size" then
			setOSDSize(r[2])
		elseif r[1] == "osdcol" then
			setOSDColour(r[2], r[3], r[4])
		elseif r[1] == "chatcol" then
			setChatColour(r[2])
		elseif r[1] == "test" then
			runSelfTest()
		elseif r[1] == "debug" then
			toggleDebug()
		else
			notify("Guild Ding: Usage: /gd help | version | status | bc | osd | chat | size | osdcol | chatcol | test | debug", true)
		end
	else
		notify("Guild Ding: Usage: /gd help | version | status | bc | osd | chat | size | osdcol | chatcol | test | debug", true)
	end
end

-------------------------------------------------------------------------------

-- Initialize everything
LoadStart()

-- Setup the various event hooks
-- CEAttach(Event.Unit.Detail.Level, PlayerLevelUpdate, addonID .. ".Event.Unit.Detail.Level");
CEAttach(Event.Guild.Roster.Detail.Level, RosterLevelUpdate, addonID .. ".Event.Guild.Roster.Detail.Level");
-- CEAttach(Event.Unit.Detail.Mentoring, MentoredCheck, addonID .. "Event.Unit.Detail.Mentoring")
CEAttach(Event.Message.Receive, OnMessage, addonID .. ".Event.Message.Receive");
CEAttach(Event.System.Update.Begin, SystemTick, addonID .. "Event.System.Update.Begin")

CEAttach(Event.Unit.Availability.Full, UnitReady, addonID .. "Event.Unit.Availability.Full")
--CEAttach(Event.Addon.Load.End, LoadEnd, addonID .. "Event.Addon.Load.End")
--CEAttach(Event.Addon.Startup.End, StartupEnd, addonID .. "Event.Addon.Startup.End")
--CEAttach(Event.Addon.SavedVariables.Load.End, SVLoadEnd, addonID .. ".Event.Addon.SavedVariables.Load.End")
UI.Native.Console1:EventAttach(Event.UI.Native.Loaded, ConsoleLoadEnd, addonID .. "_Native_Console_Loaded")

-- Make sure we accept messages to/from this addon
CMAccept("guild", "GuildDing");

-- Setup the slash "/" command shortcuts
CEAttach(Command.Slash.Register("gd"), slashHandler, addonID .. "Command.Slash.Register")
CEAttach(Command.Slash.Register("gding"), slashHandler, addonID .. "Command.Slash.Register")
CEAttach(Command.Slash.Register("guildding"), slashHandler, addonID .. "Command.Slash.Register")

-------------------------------------------------------------------------------
