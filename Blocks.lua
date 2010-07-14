local aname, atbl = ...
local addon = CreateFrame("Frame", aname)
local ldb = LibStub("LibDataBroker-1.1")

local function TextUpdate(self, event, name, key, value)
	self:SetText(value)
end

local function scall(func, ...)
	if func then func(...) end
end

local function OnClick(self, button)
	if button == "RightButton" and IsShiftKeyDown() then
		self:Hide()
		BlocksDB[self.name].hidden = true
	else
		scall(self.dobj.OnClick, self, button)
	end
end


local function GetUIParentAnchor(frame)
	local w, h, x, y = UIParent:GetWidth(), UIParent:GetHeight(), frame:GetCenter()
	local hhalf, vhalf = (x > w/2) and "RIGHT" or "LEFT", (y > h/2) and "TOP" or "BOTTOM"
	local dx = hhalf == "RIGHT" and math.floor(frame:GetRight() + 0.5) - w or math.floor(frame:GetLeft() + 0.5)
	local dy = vhalf == "TOP" and math.floor(frame:GetTop() + 0.5) - h or math.floor(frame:GetBottom() + 0.5)

	return vhalf..hhalf, dx, dy
end

local function GetQuadrant(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "BOTTOMLEFT", "BOTTOM", "LEFT" end
	local hhalf = (x > UIParent:GetWidth()/2) and "RIGHT" or "LEFT"
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, vhalf, hhalf
end

local function OnEnter(self)
	local dobj = self.dobj
	scall(dobj.OnEnter, self)
	if dobj.OnTooltipShow then
		local tt = dobj.tooltip or GameTooltip
		tt:ClearLines()
		tt:SetOwner(self, "ANCHOR_NONE")
		local quad, vhalf, hhalf = GetQuadrant(self)
		tt:SetPoint(quad, self, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf)
		dobj.OnTooltipShow(tt)
		tt:Show()
	end
end

local function OnLeave(self)
	local dobj = self.dobj
	scall(dobj.OnLeave, self)
	if dobj.tooltip then dobj.tooltip:Hide()
	else GameTooltip:Hide()
	end
end
	
local function OnDragStart(self, ...)
	scall(self.dobj.OnLeave, self)
	self:StartMoving()
end

local function OnDragStop(self)
	self:StopMovingOrSizing()
	BlocksDB[self.name].point, BlocksDB[self.name].x, BlocksDB[self.name].y = GetUIParentAnchor(self)
	self:ClearAllPoints()
	self:SetPoint(BlocksDB[self.name].point, BlocksDB[self.name].x, BlocksDB[self.name].y)
	scall(self.dobj.OnEnter, self)
end



function addon:CreateBlock(dobj, name, point, x, y)
	local but = CreateFrame("Button", nil, UIParent)
	but:SetHeight(10)
	but:SetPoint(point, x, y)
	local fs = but:CreateFontString(nil, nil, "NumberFontNormalRight")
	fs:SetJustifyH("RIGHT")
	fs:SetPoint("CENTER")
	but:SetFontString(fs)
	do
		local orig = but.SetText
		function but:SetText(...)
			orig(self, ...)
			self:SetWidth(fs:GetStringWidth())
		end
	end

	but:SetText(dobj.text)
	but.TextUpdate = TextUpdate
	ldb.RegisterCallback(but, "LibDataBroker_AttributeChanged_"..name.."_text", "TextUpdate")
	
	but:RegisterForClicks("anyUp")
	but:SetScript("OnEnter", OnEnter)
	but:SetScript("OnLeave", OnLeave)
	but:SetScript("OnClick", OnClick)
	
	but:RegisterForDrag("RightButton")
	but:SetMovable(true)
	but:SetClampedToScreen(true)
	but:SetScript("OnDragStart", OnDragStart)
	but:SetScript("OnDragStop", OnDragStop)
	
	but.dobj = dobj
	but.name = name
end

function addon:DataObjectCreated(event, name, dobj)
	if dobj.type ~= "data source" then return end
	local tbl = BlocksDB[name]
	if not tbl.hidden then
		addon:CreateBlock(dobj, name, tbl.point, tbl.x, tbl.y)
	end
end


addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self)
	BlocksDB = setmetatable(BlocksDB or {}, {__index = function(self, k)
		local v = {point = "CENTER", x = 0, y = 0}
		self[k] = v
		return v
	end})
	local tbl
	for name, dobj in ldb:DataObjectIterator() do
		self:DataObjectCreated(nil, name, dobj)
	end
	ldb.RegisterCallback(self, "LibDataBroker_DataObjectCreated", "DataObjectCreated")
end)
	