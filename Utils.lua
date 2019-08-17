local purps=PurpsAddon
local LSM=LibStub:GetLibrary("LibSharedMedia-3.0")
local unpack,ipairs,pairs,wipe=unpack,ipairs,pairs,table.wipe

purps.colors={
    ["epic"]={0.64,0.21,0.93},
    ["epic_hex"]="136207",
}

purps.predefined_messages={
    ["name"]="|cffa335eePurps|r",
    ["add_items_none_found"]="No items were found. Type '/purps add' followed by shift-clicking relevant items to add them to the session.",
    ["help_message"]=function() return ("This is the %s help message,"):format(purps.predefined_messages.name) end,
    ["raid_ping"]=function(a,b) return ("%s pinged the %s."):format(a or "N/A",b:lower()) end,
}


function purps:send_user_message(key,...)
    local msg,s=(self.predefined_messages[key] or key) or "NO KEY GIVEN",""
    if type(msg)=="string" then
        s=msg
    elseif type(msg)=="function" then 
        s=msg(...)
    else
        s="UNRCOGNIZED TYPE"
    end
    
    print(("%s: %s"):format(self.predefined_messages.name,s))
    
    
end

local GetItemInfo=GetItemInfo
function purps:itemlink_info(ilink)
    local itemName,itemLink,itemRarity,itemLevel,itemMinLevel,itemType,itemSubType,_,itemEquipLoc,itemIcon,_,itemClassID,itemSubClassID=GetItemInfo(ilink)
    
    return {
        itemName=itemName,
        itemLink=itemLink,
        itemRarity=itemRarity,
        itemLevel=itemLevel,
        itemMinLevel=itemMinLevel,
        itemType=itemType,
        itemSubType=itemSubType,
        itemEquipLoc=itemEquipLoc,
        itemIcon=itemIcon,
        itemClassID=itemClassID,
        itemSubClassID=itemSubClassID,
        itemTertiary=purps:get_tertiary_stats(itemLink),
        }
end

local help_table1={}
local GetItemStats=GetItemStats
function purps:get_tertiary_stats(itemLink)
    --mostly borrowed from RCLootCouncil
    --https://www.curseforge.com/wow/addons/rclootcouncil
	local delimiter=self.para.tertiary_stats_delimiter or "/"
	wipe(help_table1)
	GetItemStats(itemLink,help_table1)
	local text = ""
	for k, _ in pairs(help_table1) do
		if k:find("SOCKET") then
			text = "Socket"
			break
		end
	end
    
	if help_table1["ITEM_MOD_CR_AVOIDANCE_SHORT"] then
		if text ~= "" then text = text..delimiter end
		text = text.._G.ITEM_MOD_CR_AVOIDANCE_SHORT
	end
	if help_table1["ITEM_MOD_CR_LIFESTEAL_SHORT"] then
		if text ~= "" then text = text..delimiter end
		text = text.._G.ITEM_MOD_CR_LIFESTEAL_SHORT
	end
	if help_table1["ITEM_MOD_CR_SPEED_SHORT"] then
		if text ~= "" then text = text..delimiter end
		text = text.._G.ITEM_MOD_CR_SPEED_SHORT
	end
	if help_table1["ITEM_MOD_CR_STURDINESS_SHORT"] then -- Indestructible
		if text ~= "" then text = text..delimiter end
		text = text.._G.ITEM_MOD_CR_STURDINESS_SHORT
	end    
    return text
end

--/script DEFAULT_CHAT_FRAME:AddMessage("\124cffff8000\124Hitem:77949::::::::120:::::\124h[Golad, Twilight of Aspects]\124h\124r");
--/script DEFAULT_CHAT_FRAME:AddMessage("\124cff0070dd\124Hitem:158030::::::::120::::2:42:4803:\124h[Bleakweald Vambraces]\124h\124r");
local sgsub=string.gsub
function purps:separate_itemlinks(msg)
    local s=sgsub(msg,"]|h|r","]|h|r ")
    return sgsub(s,"|c%x+|Hitem"," %0")
end

local sfind=string.find
function purps:is_itemlink(msg)
    if not (type(msg)=="string") then return false end
    return sfind(msg,"|Hitem")
end


function purps:RGBToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end


local LibS =LibStub:GetLibrary("AceSerializer-3.0")
local LibD=LibStub:GetLibrary("LibDeflate")

function purps:serialize_compress_encode(tbl)
    if (not tbl) or (not type(tbl)=="table") then return nil end
    local s1=LibS:Serialize(tbl)
    local s2=LibD:CompressDeflate(s1)
    local s3=LibD:EncodeForWoWAddonChannel(s2)
    return s3
end

function purps:decode_decompress_deserialize(str)
    if (not str) or (not type(str)=="string") then return nil end
    local s1=LibD:DecodeForWoWAddonChannel(str)
    local s2=LibD:DecompressDeflate(s1)
    local _,s3=LibS:Deserialize(s2)
    return s3
end

local sfind=string.find
function purps:convert_to_full_name(s)
    if (not s) or not (type(s)=="string") then return s end
    local realm=GetRealmName()
    if not sfind(s,"-") then s=("%s-%s"):format(s,realm) end
    return s
end

local strsub=string.sub
function purps:remove_realm(s)
    if (not s) or not (type(s)=="string") then return s end
    return strsub(s,1,(s:find("-") or 0)-1)
end

function purps:table_deep_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:table_deep_copy(orig_key)] = self:table_deep_copy(orig_value)
        end
        setmetatable(copy, self:table_deep_copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local raid_units={}
for i=1,40 do raid_units[i]="raid"..tostring(i) end
local party_units={"player","party1","party2","party3","party4"}
local player_list={"player"}
function purps:get_units_list()
    if not IsInGroup() then return player_list end
    return (IsInRaid() and raid_units) or party_units
end


