FrameSelect = LibStub("AceAddon-3.0"):NewAddon("FrameSelect", "AceEvent-3.0", "AceHook-3.0")

local defaults = {
	profile = {
		enabled = true,
		color = "GREEN"
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

	self.frames = {}
	self.DEFAULT_TEXTURE = "Interface\\RaidFrame\\Raid-FrameHighlights"

	self.COLORS = {
		DEFAULT = {1, 1, 1},
		GREY = {0.69, 0.69, 0.69, 1},
		YELLOW = {1, 1, 0.47, 1},
		ORANGE = {1, 0.6, 0, 1},
		RED = {1, 0, 0, 1},
		GREEN = {0.0, 1, 0.0, 0.9},
		BLUE = {0.0, 0.0, 1, 1}
	}

	SlashCmdList.FrameSelect = function(msg)
		FrameSelect:SlashCommands(msg)
	end

	SLASH_FrameSelect1 = "/fs"
	SLASH_FrameSelect2 = "/frameselect"
end

function FrameSelect:Refresh()
	-- print "FS: Refresh"
end

function FrameSelect:OnEnable()
	-- print("FS: OnEnable")


	hooksecurefunc("DefaultCompactUnitFrameSetup", function(frame)
		FrameSelect:doSelectOverride(frame)
	end)

	hooksecurefunc("DefaultCompactMiniFrameSetup", function(frame)
		FrameSelect:doSelectOverride(frame)
	end)

	hooksecurefunc("CompactUnitFrame_UpdateAll", function(frame)
		if frame:IsForbidden() then return end

		local name = frame:GetName()
		if not name or not name:match("^Compact") then
			return
		end

		if (not UnitExists(frame.displayedUnit)) then return end
		FrameSelect:doSelectOverride(frame)
	end)

end

function FrameSelect:doSelectOverride(frame)
	if not FrameSelect.db.profile.enabled then return end

	if frame:IsForbidden() then return end
	FrameSelect.frames[frame] = true	-- store reference for toggling later
	FrameSelect:doSetCustomSelection(frame)
end

function FrameSelect:doSetCustomSelection(frame)
	if frame:IsForbidden() then return end
	frame.selectionHighlight:SetTexture(FrameSelect.DEFAULT_TEXTURE);
	frame.selectionHighlight:SetTexCoord(unpack(texCoords["Raid-AggroFrame"]));
	frame.selectionHighlight:SetVertexColor(unpack(FrameSelect.COLORS[FrameSelect.db.profile.color]));
	frame.selectionHighlight:SetAllPoints(frame);
end

function FrameSelect:doSetBlizzardSelection(frame)
	if frame:IsForbidden() then return end
	frame.selectionHighlight:SetTexture(FrameSelect.DEFAULT_TEXTURE);
	frame.selectionHighlight:SetTexCoord(unpack(texCoords["Raid-TargetFrame"]));
	frame.selectionHighlight:SetVertexColor(unpack(FrameSelect.COLORS.DEFAULT));
	frame.selectionHighlight:SetAllPoints(frame);
end

function FrameSelect:doBlizzardReset(reset)
	for frame, _ in pairs(FrameSelect.frames) do
		if(reset) then
			FrameSelect:doSetBlizzardSelection(frame)
		else
			FrameSelect:doSetCustomSelection(frame)
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
	elseif options[1] == "color" then
		if(not options[2]) then
			print("FrameSelect: Please specify a color: default, grey, red, green, blue, orange, yellow")
			return
		end
		local colorUpper = string.upper(options[2])
		local colorTable = FrameSelect.COLORS[colorUpper] -- ensure proper value for later
		if(not colorTable) then
			FrameSelect.db.profile.color = "DEFAULT"
		else
			FrameSelect.db.profile.color = colorUpper
		end
		FrameSelect:doBlizzardReset(false)
	elseif options[1] == "help" then
		print("FrameSelect SlashCommands")
		print("/fs enable")
		print("/fs color green")
		print("Colors available: default, grey, red, green, blue, orange, yellow")
	end
end
