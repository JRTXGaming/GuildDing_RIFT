if(not ApiBrowser) then
	return -- Don't process the remaining file if ApiBrowser is not installed
end

local symbols = { }

symbols["LibVersionCheck.register"] = {
	summary = [[
Registers an addon and its current version with the library. This should be called from Addon initialization code, typically in a handler for Event.Addon.Load.End.

It may be put into Event.Addon.Startup.End as well, but beware:
version registration needs to take place before the Event.Addon.Startup.End handler of LibVersionCheck is called, which is done with a priority of -99. So, if you have reason to use Startup.End instead of Load.End, make sure you register the event with default priority, or at least a priority greater than -99.]],
	signatures = {
		"LibVersionCheck.register(addonName, addonVersion)",
	},
	parameter = {
		["addonName"] = "The Name of your Addon, like MyGreatAddon",
		["addonVersion"] = "The Version of your Addon, like 2.0 or V2alpha3",
	},
	result = {
	},
	type = "function",
}

local summary = [[
A library that tries to detect when addons are outdated, by sharing used versions between players.

Whenever a player encounters someone else (by grouping with them, or moving the mouse cursor over them; technically: when Event.Unit.Available.Full fires, the library asks the other player for their addon versions, saving the responses to persistent storage. When the player logs in next time, and any of the saved versions is greater than the one the player's addons registered with, the player will get an information screen. The player can then decide when to show the warning again, with several options between "next login" and "next year", so players who are interested in getting informed will, and players who aren't won't be bothered again.
]]

local Addon = ...
ApiBrowser.AddLibraryWithRiftLikeCatalogIndex(Addon.identifier, Addon.toc.Name, summary, symbols)
