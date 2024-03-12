local DEBUG = false

function arf_print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function debug_print(msg)
  if DEBUG then DEFAULT_CHAT_FRAME:AddMessage(msg) end
end

AutoRF = CreateFrame("Frame")

local defaults = {
  enabled = true,
  watch_names = {},
  kick_if_ghosts = false,
  queue = {},
  delay = 5,
  -- add_queue = {},
  -- kick_queue = {},
}

function pollFriends()
  FriendTable = {}
  for i=1,GetNumFriends() do
    local n, level, class, loc, connected, status = GetFriendInfo(i)
    local name = string.lower(n)
    debug_print(format("%s %d %s %s %s", name, level, class, loc, tostring(connected)))
    FriendTable[name] = {}
    FriendTable[name].level = level
    FriendTable[name].class = class
    FriendTable[name].loc = loc
    FriendTable[name].connected = connected
    FriendTable[name].status = status
  end
  return FriendTable
end

-- if party destruct flag is set, don't invite anyone until the party is disbanded
local in_group = {}
local party_destruct = false
local function OnEvent()
  if AutoRFDB.enabled then
    local rcount = GetNumRaidMembers()
    local pcount = GetNumPartyMembers()
    local no_party = pcount + rcount == 0
    if event == "FRIENDLIST_UPDATE" and (IsPartyLeader("player") or no_party) then
      debug_print("friendlist event")
      for i=1,rcount do
        local id = "raid"..i
        if not UnitIsConnected(id) or (AutoRFDB.kick_if_ghosts and UnitIsGhost(id)) then
          arf_print("AutoRF: Begining party teardown.")
          UninviteFromRaid(UnitInRaid(id))
          party_destruct = true
        end
      end
      debug_print("polling friends")
      local friends = pollFriends()
      if not party_destruct then
        debug_print("not party destruct")
        for n,f in friends do
          if f.connected and AutoRFDB.watch_names[n] and not AutoRFDB.queue[n] then
            local inraid = false
            for i=1,rcount do
              if string.lower(UnitName("raid"..i)) == n then
                debug_print("inraid already")
                inraid = true
                break
              end
            end
            if not inraid then AutoRFDB.queue[n] = 0 end
          end
        end
      end
    elseif event == "RAID_TARGET_UPDATE" then
      debug_print("party changed")
      if no_party and party_destruct then
        arf_print("AutoRF: Finished party teardown.")
        party_destruct = false
      end
      if pcount > 0 and rcount == 0 then
        ConvertToRaid()
      end
    elseif event == "ADDON_LOADED" then
      AutoRF:UnregisterEvent("ADDON_LOADED")
      if not AutoRFDB then
        AutoRFDB = defaults -- initialize default settings
        else -- or check that we only have the current settings format
          local s = {}
          for k,v in pairs(defaults) do
            if AutoRFDB[k] == nil -- specifically nil
              then s[k] = defaults[k]
              else s[k] = AutoRFDB[k] end
          end
          -- is the above just: s[k] = ((AutoManaSettings[k] == nil) and defaults[k]) or AutoManaSettings[k]
          AutoRFDB = s
      end
    end
  end 
end

local function OnUpdate()
  if AutoRFDB.enabled then
    for k,v in pairs(AutoRFDB.queue) do
      AutoRFDB.queue[k] = v + arg1
      if AutoRFDB.queue[k] > AutoRFDB.delay then
        InviteByName(k)
        AutoRFDB.queue[k] = nil
      end
    end
  end
end

-- These events are quite limited I'll need to poll for party changes and offlines
-- go through and update raid recipes

AutoRF:RegisterEvent("FRIENDLIST_UPDATE") -- fired when member goes online or offline
AutoRF:RegisterEvent("PARTY_MEMBERS_CHANGED") -- fired on player join or leaves party or offlines in raid
AutoRF:RegisterEvent("RAID_TARGET_UPDATE") -- fired on player join or leave, or offline, party or raid. also when raid forms
AutoRF:RegisterEvent("ADDON_LOADED")
AutoRF:SetScript("OnEvent", OnEvent)
AutoRF:SetScript("OnUpdate", OnUpdate)

local function handleCommands(msg,editbox)
  local args = {};
  for word in string.gfind(msg,'%S+') do table.insert(args,word) end

  local friends = pollFriends()

  if args[1] == "on" or args[1] == "enable" then
    AutoRFDB.enabled = true
    arf_print("AutoRF enabled.")
  elseif args[1] == "off" or args[1] == "disable" then
    AutoRFDB.enabled = false
    arf_print("AutoRF disabled.")
  elseif args[1] == "toggle" then
    AutoRFDB.enabled = not AutoRFDB.enabled
    arf_print("AutoRF toggled.")
  elseif args[1] == "add" then
    if args[2] then
      local n = string.lower(args[2])
      if friends[n] then
        AutoRFDB.watch_names[n] = true
        arf_print(args[2].." added to the watch list.")
      else
        arf_print(args[2].." isn't in your friends list.")
      end
    else
      arf_print("/autorf add [friendname]")
    end
  elseif args[1] == "rem" then
    if args[2] then
      local n = string.lower(args[2])
      if AutoRFDB.watch_names[n] then
        AutoRFDB.watch_names[n] = nil
        arf_print(args[2].." removed from the watch list.")
      else
        arf_print(args[2].." not in the watch list.")
      end
    end
  elseif args[1] == "list" then
    local t = {}
    for k,_ in pairs(AutoRFDB.watch_names) do table.insert(t,k) end
    arf_print(table.concat(t, ", "))
  elseif args[1] == "ghost" then
    AutoRFDB.kick_if_ghosts = not AutoRFDB.kick_if_ghosts
    arf_print("AutoRF will kick ghosts.")
  elseif args[1] == "delay" then
    local n = tonumber(args[2])
    if n and n > 0 then
      AutoRFDB.delay = n
      arf_print("AutoRF will delay"..n.."seconds before inviting.")
    else
      arf_print("/autoaf delay [positive number]")
    end
  else
    arf_print("Type /autorf followed by:")
    arf_print("[on] or [enable] to enable addon.")
    arf_print("[list] to see who's on the watch list.")
    arf_print("[add] to add a friend to the invite watch list.")
    arf_print("[rem] to remove a friend to the invite watch list.")
    arf_print("[ghost] to kick players if they release.")
    arf_print("[delay] in seconds to set the invite delay, accounts for addon loading.")
  end
end

SLASH_AUTORF1 = "/autorf";
SlashCmdList["AUTORF"] = handleCommands

