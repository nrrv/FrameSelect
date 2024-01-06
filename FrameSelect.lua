FrameSelect = LibStub("AceAddon-3.0"):NewAddon("FrameSelect", "AceEvent-3.0", "AceHook-3.0")

local defaults = {
	profile = {
		enabled = true,
		color = "GREEN",
		DEBUG = false,
		enableTexture = true
	}
}

local texCoords = {
	["Raid-AggroFrame"] = {  0.00781250, 0.55468750, 0.00781250, 0.27343750 },
	["Raid-TargetFrame"] = { 0.00781250, 0.55468750, 0.28906250, 0.55468750 },
}

function FrameSelect:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("FrameSelectDB", defaults, true)

	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")

	-- self:RegisterEvent("GROUP_ROSTER_UPDATE", "doRosterUpdate")
	-- self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "doArenaPrep")
	-- self:RegisterEvent("PLAYER_ENTERING_WORLD", "doArenaPrep")

	self.frames = {}
	self.DEFAULT_TEXTURE = "Interface\\RaidFrame\\Raid-FrameHighlights"

	self.COLORS = {
		DEFAULT = {1, 1, 1},
		GREY = {0.69, 0.69, 0.69, 1},
		YELLOW = {1, 1, 0.5, 1},
		ORANGE = {1, 0, 0, 1},
		RED = {1, 0, 0, 1},
		GREEN = {0, 1, 0, 0.9},
		BLUE = {0, 0, 1, 1}
	}

	SlashCmdList.FrameSelect = function(msg)
		FrameSelect:SlashCommands(msg)
	end

	SLASH_FrameSelect1 = "/fs"
	SLASH_FrameSelect2 = "/frameselect"
end

function FrameSelect:Refresh()
	-- self:debug("Refresh", "Refresh")
end

function FrameSelect:OnEnable()
	-- self:debug("onEnable", "OnEnable")

	hooksecurefunc("DefaultCompactUnitFrameSetup", function(frame)
		FrameSelect:doSelectOverride(frame, "DefaultCompactUnitFrameSetup")
	end)

	hooksecurefunc("DefaultCompactMiniFrameSetup", function(frame)
		FrameSelect:doSelectOverride(frame, "DefaultCompactMiniFrameSetup")
	end)

	-- unnecessary to iterate through all of these, but does work.
	-- This also reduces the massive amount of unit frames that have GetName == nil
	-- hooksecurefunc("CompactUnitFrame_UpdateAll", function(frame)
	-- 	FrameSelect:doSelectOverride(frame, "CompactUnitFrame_UpdateAll")
	-- end)

end

function FrameSelect:doSelectOverride(frame, source)
	if not FrameSelect.db.profile.enabled then return end

	if frame:IsForbidden() then return end

	local name = frame:GetName()
	-- todo -- confirm that we do not need to include Arena Frame
	if not name or (not name:match("^CompactParty") and not name:match("^CompactRaid")) then
		-- if(name == nil) then name = "undefined name"; end -- For reporting purposes.
		-- self:debug(frame, "doSelectOverride: "..source.." | Ignore!");
		return
	end

	if (not UnitExists(frame.displayedUnit)) then
		-- self:debug(name, "doSelectOverride: !UnitExists: "..source);
		return
	end

	self:debug(frame, "doSelectOverride: exec: "..source);
	FrameSelect.frames[frame] = true	-- store reference for toggling later
	FrameSelect:doCustomSelection(frame)
end

function FrameSelect:doCustomSelection(frame)
	if frame:IsForbidden() then return end


	if self.db.profile.enableTexture then
		frame.selectionHighlight:SetTexture(FrameSelect.DEFAULT_TEXTURE);
		frame.selectionHighlight:SetTexCoord(unpack(texCoords["Raid-AggroFrame"]));
		frame.selectionHighlight:SetAllPoints(frame);
	else
		-- In case the user toggled texture, but wants the addon enabled.
		FrameSelect:doBlizzardSelection(frame)
	end

	local colors = FrameSelect.COLORS[self.db.profile.color];
	frame.selectionHighlight:SetVertexColor(unpack(colors));
end

function FrameSelect:doBlizzardSelection(frame)
	if frame:IsForbidden() then return end
	frame.selectionHighlight:SetTexture(FrameSelect.DEFAULT_TEXTURE);
	frame.selectionHighlight:SetTexCoord(unpack(texCoords["Raid-TargetFrame"]));
	frame.selectionHighlight:SetAllPoints(frame);
	frame.selectionHighlight:SetVertexColor(unpack(FrameSelect.COLORS.DEFAULT));
end

function FrameSelect:doBlizzardReset(reset)
	-- self:debug("reset", "doBlizzardReset")

	for frame, _ in pairs(FrameSelect.frames) do
		if(reset) then
			FrameSelect:doBlizzardSelection(frame)
		else
			FrameSelect:doCustomSelection(frame)
		end
	end
end

function FrameSelect:SlashCommands(msg)
	if msg == "" then return end
	local options = { strsplit(" ", string.lower(msg)) } -- strsplit does not return a table.
	
	if options[1] == "enable" then
		self.db.profile.enabled = not self.db.profile.enabled
		if self.db.profile.enabled == true then
			print("|cFF50C0FFEnable: |cFFADFF2F".. tostring(self.db.profile.enabled) .."|r")
			FrameSelect:doBlizzardReset(false)
		else
			print("|cFF50C0FFEnable: |cFFFF4500".. tostring(self.db.profile.enabled) .."|r")
			FrameSelect:doBlizzardReset(true)
		end
	elseif options[1] == "toggletexture" then
		self.db.profile.enableTexture = not self.db.profile.enableTexture
		if self.db.profile.enableTexture == true then
			print("|cFF50C0FFToggleTexture: |cFFADFF2F".. tostring(self.db.profile.enableTexture) .."|r")
			FrameSelect:doBlizzardReset(false)
		else
			print("|cFF50C0FFToggleTexture: |cFFFF4500".. tostring(self.db.profile.enableTexture) .."|r")
			FrameSelect:doBlizzardReset(false)
		end
	elseif options[1] == "color" then
		if(not options[2]) then
			print("|cFF50C0FFPlease specify one of these color options: default, grey, red, green, blue, orange, yellow |r")
			return
		end
		local colorUpper = string.upper(options[2])
		local colorTable = FrameSelect.COLORS[colorUpper] -- ensure proper value for later
		if(not colorTable) then
			print("|cFF50C0FFColor unchanged. Please specify one of these options: default, grey, red, green, blue, orange, yellow |r")
		else
			FrameSelect.db.profile.color = colorUpper
			print("|cFF50C0FFColor: ".. tostring(string.lower(self.db.profile.color)) .."|r")
			FrameSelect:doBlizzardReset(false)
		end
	elseif options[1] == "help" then
		print("FrameSelect SlashCommands")
		print("/fs enable")
		print("/fs color green")
		print("Colors available: default, grey, red, green, blue, orange, yellow")
		print("/fs toggleTexture")
	end
end

function FrameSelect:debug(data, label)
	if not self.db.profile.DEBUG then return end

	if DevTool then
		DevTool:AddData(data, label)
	else
		local dataStr = type(data) == "string" and data or "[object]"
		print("FS: debug: "..label..": "..dataStr)
	end

end

-- inactive, but functional - was attempting to track down missing SetVertexColor
-- function FrameSelect:doRosterUpdate()
-- 	if not FrameSelect.db.profile.enabled then return end

-- 	-- self:debug("GROUP_ROSTER_UPDATE", "doRosterUpdate")
-- 	FrameSelect:doBlizzardReset(false)
-- end

-- function FrameSelect:doArenaPrep()
-- 	if not FrameSelect.db.profile.enabled then return end

-- 	self:debug("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "doArenaPrep")
-- 	FrameSelect:doBlizzardReset(false)
-- end
