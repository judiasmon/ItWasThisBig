IWTB = IWTB or {}
local IWTB = IWTB
local addonName = "ItWasThisBig"
local fishByName = {}
local unknownFishIcon = IWTB.UnknownFishIcon
local logLimit = 500

local function NormalizeName(name)
    if not name then
        return ""
    end
    name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
    name = string.gsub(name, "|r", "")
    name = string.gsub(name, "^%s*(.-)%s*$", "%1")
    return string.lower(name)
end

for _, fish in ipairs(IWTB_Fish) do
    fishByName[NormalizeName(fish.name)] = fish
    for _, alias in ipairs(fish.aliases) do
        fishByName[NormalizeName(alias)] = fish
    end
end

local function GetFishingSkill()
    if GetProfessions and GetProfessionInfo then
        local _, _, _, fishingProfession = GetProfessions()
        if fishingProfession then
            local _, _, rank, maxRank = GetProfessionInfo(fishingProfession)
            if rank then
                return rank, maxRank or 300
            end
        end
    end

    if GetNumSkillLines and GetSkillLineInfo then
        for i = 1, GetNumSkillLines() do
            local name, isHeader, _, rank, _, modifier, maxRank = GetSkillLineInfo(i)
            if not isHeader and name and string.lower(name) == "fishing" then
                return (rank or 0) + (modifier or 0), maxRank or 300
            end
        end
    end
    return 0, 300
end

local function GetCurrentZone()
    local zone = GetRealZoneText and GetRealZoneText()
    if not zone or zone == "" then
        zone = GetZoneText and GetZoneText()
    end
    if not zone or zone == "" then
        return "Unknown zone"
    end
    return zone
end

local function GetWeightMultiplier(skill, maxSkill)
    if maxSkill <= 0 then
        maxSkill = 300
    end
    return 1 + math.min(skill / maxSkill, 1) * 0.5
end

local function GetFish(itemName)
    return fishByName[NormalizeName(itemName)]
end

local function NormalSample(mean, deviation)
    local u1 = math.random()
    if u1 <= 0 then
        u1 = 0.000001
    end
    local u2 = math.random()
    local value = mean + deviation * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    if value < 0 then
        return 0
    end
    return value
end

local function GetRarity(length, fish)
    local standardDeviations = (length - fish.length) / fish.lengthSD
    if standardDeviations < 0 then
        return "poor"
    elseif standardDeviations < 1 then
        return "common"
    elseif standardDeviations < 2 then
        return "uncommon"
    elseif standardDeviations < 3 then
        return "rare"
    elseif standardDeviations < 4 then
        return "epic"
    end
    return "legendary"
end

function IWTB.FormatWeight(weight)
    if weight < 1 then
        return string.format("%.0f g", weight * 1000)
    end
    return string.format("%.2f kg", weight)
end

local function GetItemName(message)
    local _, _, linkedName = string.find(message or "", "|h%[(.-)%]|h")
    if linkedName then
        return linkedName
    end
    local _, _, itemName = string.find(message or "", "%[(.-)%]")
    return itemName
end

local function GetItemLink(message)
    return string.match(message or "", "|Hitem:.-|h%[.-%]|h")
end

local function IsPlayerLootMessage(message, source)
    local playerName = UnitName("player")
    if source and (source == playerName or source == YOU or source == "You") then
        return true
    end

    local selfLootPrefix = LOOT_ITEM_SELF and string.match(LOOT_ITEM_SELF, "^(.-)%%s")
    if selfLootPrefix and string.sub(message, 1, string.len(selfLootPrefix)) == selfLootPrefix then
        return true
    end
    return string.find(message, "You receive loot:", 1, true) == 1
end

function IWTB.GetFishIcon(fish)
    local savedIcon = ItWasThisBigDB.fishIcons and ItWasThisBigDB.fishIcons[fish.name]
    if savedIcon then
        return savedIcon
    end
    local record = ItWasThisBigDB.records[fish.name]
    local itemLink = fish.itemLink or (record and record.itemLink)
    local itemID = itemLink and tonumber(string.match(itemLink, "|Hitem:(%d+)"))
    itemID = itemID or fish.itemID
    local texture

    if itemID and GetItemIcon then
        texture = GetItemIcon(itemID)
    end
    if not texture and itemID and C_Item and C_Item.GetItemIconByID then
        texture = C_Item.GetItemIconByID(itemID)
    end
    if GetItemInfo then
        if not texture then
            local _, _, _, _, _, _, _, _, _, itemTexture =
                GetItemInfo(itemLink or itemID or fish.aliases[1] or fish.name)
            texture = itemTexture
        end
        if not texture and itemID then
            local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
            texture = itemTexture
        end
    end
    if texture then
        ItWasThisBigDB.fishIcons = ItWasThisBigDB.fishIcons or {}
        ItWasThisBigDB.fishIcons[fish.name] = texture
        return texture
    end
    return fish.icon or unknownFishIcon
end

local function RecordCatch(fish, itemName, itemLink)
    local length = NormalSample(fish.length, fish.lengthSD)
    local fishingSkill, maxFishingSkill = GetFishingSkill()
    local weightMultiplier = GetWeightMultiplier(fishingSkill, maxFishingSkill)
    local weight = NormalSample(fish.weight * weightMultiplier, fish.weightSD * weightMultiplier)
    local rarity = GetRarity(length, fish)
    local record = ItWasThisBigDB.records[fish.name]
    local isRecord = not record or weight > record.weight
    local catch = {
        species = fish.name,
        item = itemName,
        itemLink = itemLink,
        length = length,
        weight = weight,
        rarity = rarity,
        fishingSkill = fishingSkill,
        weightMultiplier = weightMultiplier,
        zone = GetCurrentZone(),
        time = date("%Y-%m-%d %H:%M"),
        personalRecord = isRecord
    }

    table.insert(ItWasThisBigDB.log, 1, catch)
    while table.getn(ItWasThisBigDB.log) > logLimit do
        table.remove(ItWasThisBigDB.log)
    end
    if isRecord then
        ItWasThisBigDB.records[fish.name] = catch
    end
    IWTB.UpdateCatchStatistics(fish, catch)
    IWTB.AlertCatch(catch)
    if IWTB.MainFrame and IWTB.MainFrame:IsShown() then
        IWTB.RefreshRows()
    end
end

function IWTB.EnsureDatabase()
    if not ItWasThisBigDB then
        ItWasThisBigDB = {}
    end
    if not ItWasThisBigDB.log then
        ItWasThisBigDB.log = {}
    end
    if not ItWasThisBigDB.records then
        ItWasThisBigDB.records = {}
    end
    if not ItWasThisBigDB.settings then
        ItWasThisBigDB.settings = {}
    end
    local oldRareSound = ItWasThisBigDB.settings.rareSound
    if ItWasThisBigDB.settings.rareSound == nil then
        ItWasThisBigDB.settings.rareSound = oldRareSound ~= false
    end
    if ItWasThisBigDB.settings.epicSound == nil then
        ItWasThisBigDB.settings.epicSound = oldRareSound ~= false
    end
    if ItWasThisBigDB.settings.legendarySound == nil then
        ItWasThisBigDB.settings.legendarySound = oldRareSound ~= false
    end
    if ItWasThisBigDB.settings.recordSound == nil then
        ItWasThisBigDB.settings.recordSound = true
    end
    if ItWasThisBigDB.settings.minimapButton == nil then
        ItWasThisBigDB.settings.minimapButton = true
    end
    if ItWasThisBigDB.settings.minimapAngle == nil then
        ItWasThisBigDB.settings.minimapAngle = 220
    end
    if ItWasThisBigDB.settings.muteGameSoundsWhileFishing == nil then
        ItWasThisBigDB.settings.muteGameSoundsWhileFishing = false
    end
    if not ItWasThisBigDB.speciesStats then
        ItWasThisBigDB.speciesStats = {}
    end
    if not ItWasThisBigDB.fishIcons then
        ItWasThisBigDB.fishIcons = {}
    end
    if not ItWasThisBigDB.zoneStats then
        ItWasThisBigDB.zoneStats = {}
    end
    IWTB.InitializeStatistics()
end

function IWTB.ClearCatchLog()
    ItWasThisBigDB.log = {}
    if IWTB.MainFrame and IWTB.MainFrame:IsShown() then
        IWTB.RefreshRows()
    end
end

local function OnLootMessage(message, source)
    local itemName = GetItemName(message)
    if not itemName then
        return
    end
    if not IsPlayerLootMessage(message, source) then
        return
    end
    IWTB.OnFishingLootReceived()
    local fish = GetFish(itemName)
    if not fish then
        return
    end
    local itemLink = GetItemLink(message)
    fish.itemLink = itemLink
    IWTB.GetFishIcon(fish)
    local quantity = 1
    local _, _, amount = string.find(message, "|h%s*[xX](%d+)")
    if amount then
        quantity = math.min(tonumber(amount), 99)
    end
    for _ = 1, quantity do
        RecordCatch(fish, itemName, itemLink)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:SetScript("OnEvent", function(self, eventName, ...)
    local loadedAddon = ...
    if eventName == "ADDON_LOADED" and loadedAddon == addonName then
        IWTB.EnsureDatabase()
        IWTB.UpdateMinimapButton()
    elseif eventName == "CHAT_MSG_LOOT" then
        local message = loadedAddon
        local _, source = ...
        IWTB.EnsureDatabase()
        OnLootMessage(message, source)
    elseif eventName == "GET_ITEM_INFO_RECEIVED" then
        if IWTB.MainFrame and IWTB.MainFrame:IsShown() then
            IWTB.RefreshRows()
        end
    end
end)

SLASH_ITWASTHISBIG1 = "/iwtb"
SLASH_ITWASTHISBIG2 = "/bigfish"
SlashCmdList["ITWASTHISBIG"] = function()
    IWTB.OpenWindow()
end
