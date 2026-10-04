IWTB = IWTB or {}
local IWTB = IWTB
local addonName = "ItWasThisBig"
local fishByName = {}
local fishBySpecies = {}
local rarityRanks = { poor = 1, common = 2, uncommon = 3, rare = 4, epic = 5, legendary = 6 }
local unknownFishIcon = IWTB.UnknownFishIcon
local logLimit = 500
local minimapButton
local fishingChannelActive = false
local savedSoundSettings
local mutedSoundCVars = {
    "Sound_EnableMusic",
    "Sound_EnableAmbience",
    "Sound_EnableDialog"
}

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
    fishBySpecies[fish.name] = fish
    fishByName[NormalizeName(fish.name)] = fish
    for _, alias in ipairs(fish.aliases) do
        fishByName[NormalizeName(alias)] = fish
    end
end

local function GetFishingSkill()
    if not GetNumSkillLines or not GetSkillLineInfo then
        return 0, 300
    end
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, modifier, maxRank = GetSkillLineInfo(i)
        if not isHeader and name and string.lower(name) == "fishing" then
            return (rank or 0) + (modifier or 0), maxRank or 300
        end
    end
    return 0, 300
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

local function GetFishingSpellName()
    if GetSpellInfo then
        local fishingSpellName = GetSpellInfo(7620)
        if fishingSpellName then
            return NormalizeName(fishingSpellName)
        end
    end
    return "fishing"
end

local function RestoreGameSounds()
    if not savedSoundSettings then
        return
    end
    for _, cvar in ipairs(mutedSoundCVars) do
        local value = savedSoundSettings[cvar]
        if value ~= nil then
            SetCVar(cvar, value)
        end
    end
    savedSoundSettings = nil
end

local function MuteGameSounds()
    if savedSoundSettings or not GetCVar or not SetCVar then
        return
    end
    savedSoundSettings = {}
    for _, cvar in ipairs(mutedSoundCVars) do
        local value = GetCVar(cvar)
        if value ~= nil then
            savedSoundSettings[cvar] = value
            SetCVar(cvar, "0")
        end
    end
end

local function UpdateFishingSoundMute()
    if fishingChannelActive and ItWasThisBigDB.settings.muteGameSoundsWhileFishing then
        MuteGameSounds()
    else
        RestoreGameSounds()
    end
end
IWTB.UpdateFishingSoundMute = UpdateFishingSoundMute

local function IsFishingSpell(...)
    local fishingSpellName = GetFishingSpellName()
    for i = 1, select("#", ...) do
        local spell = select(i, ...)
        if spell == 7620 or (type(spell) == "string" and NormalizeName(spell) == fishingSpellName) then
            return true
        end
    end
    return false
end

local function OnFishingSpellcastStart(unit, ...)
    if unit ~= "player" then
        return
    end
    if IsFishingSpell(...) then
        fishingChannelActive = true
        UpdateFishingSoundMute()
    end
end

local function OnFishingSpellcastEnd(unit, ...)
    if unit ~= "player" or not IsFishingSpell(...) then
        return
    end
    fishingChannelActive = false
    UpdateFishingSoundMute()
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
    return nil
end

function IWTB.GetFishIcon(fish)
    if GetItemInfo then
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(fish.aliases[1] or fish.name)
        if texture then
            return texture
        end
    end
    return fish.icon or unknownFishIcon
end

local function PositionMinimapButton()
    if not minimapButton or not Minimap then
        return
    end
    local angle = math.rad(ItWasThisBigDB.settings.minimapAngle or 220)
    local radius = (Minimap:GetWidth() / 2) + 4
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius, math.sin(angle) * radius)
end

function IWTB.UpdateMinimapButton()
    if not minimapButton then
        minimapButton = CreateFrame("Button", "ItWasThisBigMinimapButton", Minimap)
        minimapButton:SetWidth(32)
        minimapButton:SetHeight(32)
        minimapButton:SetFrameStrata("MEDIUM")
        minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 5)
        minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        minimapButton:RegisterForDrag("LeftButton")

        local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
        icon:SetTexture("Interface\\Icons\\INV_Misc_MonsterHead_01")
        icon:SetWidth(20)
        icon:SetHeight(20)
        icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
        minimapButton.icon = icon

        local border = minimapButton:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        border:SetWidth(54)
        border:SetHeight(54)
        border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)

        minimapButton:SetScript("OnClick", function()
            if IWTB.OpenWindow then
                IWTB.OpenWindow()
            end
        end)
        minimapButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
            GameTooltip:SetText("It Was This Big!")
            GameTooltip:AddLine("Click to open your fishing records.", 1, 1, 1)
            GameTooltip:Show()
        end)
        minimapButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        minimapButton:SetScript("OnDragStart", function(self)
            self:SetScript("OnUpdate", function()
                local x, y = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                x = x / scale - Minimap:GetLeft() - (Minimap:GetWidth() / 2)
                y = y / scale - Minimap:GetBottom() - (Minimap:GetHeight() / 2)
                local angle = math.deg(math.atan2(y, x))
                ItWasThisBigDB.settings.minimapAngle = angle
                PositionMinimapButton()
            end)
        end)
        minimapButton:SetScript("OnDragStop", function(self)
            self:SetScript("OnUpdate", nil)
        end)
    end

    if ItWasThisBigDB.settings.minimapButton then
        PositionMinimapButton()
        minimapButton:Show()
    else
        minimapButton:Hide()
    end
end

local function PlayCatchSound(file)
    if PlaySoundFile then
        PlaySoundFile(file, "Master")
    elseif PlaySound then
        PlaySound("RaidWarning")
    end
end

local function AlertCatch(catch)
    if catch.personalRecord and ItWasThisBigDB.settings.recordSound then
        PlayCatchSound("Sound\\Interface\\LevelUp.ogg")
    end
    if catch.rarity == "rare" and ItWasThisBigDB.settings.rareSound then
        PlayCatchSound("Sound\\Interface\\RaidWarning.ogg")
    elseif catch.rarity == "epic" and ItWasThisBigDB.settings.epicSound then
        PlayCatchSound("Sound\\Interface\\LevelUp.ogg")
    elseif catch.rarity == "legendary" and ItWasThisBigDB.settings.legendarySound then
        PlayCatchSound("Sound\\Interface\\iQuestComplete.ogg")
    end
end

local function UpdateSpeciesStats(fish, catch)
    local stats = ItWasThisBigDB.speciesStats[fish.name]
    if not stats then
        stats = { count = 0, bestRarity = "poor" }
        ItWasThisBigDB.speciesStats[fish.name] = stats
    end
    stats.count = stats.count + 1
    if not stats.best or catch.weight > stats.best.weight then
        stats.best = catch
    end
    if not stats.worst or catch.weight < stats.worst.weight then
        stats.worst = catch
    end
    if (rarityRanks[catch.rarity] or 0) > (rarityRanks[stats.bestRarity] or 0) then
        stats.bestRarity = catch.rarity
    end
end

local function RecordCatch(fish, itemName)
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
        length = length,
        weight = weight,
        rarity = rarity,
        fishingSkill = fishingSkill,
        weightMultiplier = weightMultiplier,
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
    UpdateSpeciesStats(fish, catch)
    AlertCatch(catch)
    if IWTB.MainFrame and IWTB.MainFrame:IsShown() then
        IWTB.RefreshRows()
    end
end

local function InitializeSpeciesStats()
    if ItWasThisBigDB.speciesStatsInitialized then
        return
    end
    ItWasThisBigDB.speciesStats = {}
    for i = table.getn(ItWasThisBigDB.log), 1, -1 do
        local catch = ItWasThisBigDB.log[i]
        local fish = fishBySpecies[catch.species]
        if fish then
            UpdateSpeciesStats(fish, catch)
        end
    end
    for species, record in pairs(ItWasThisBigDB.records) do
        local stats = ItWasThisBigDB.speciesStats[species]
        if not stats then
            stats = {
                count = 1,
                best = record,
                worst = record,
                bestRarity = record.rarity or "poor"
            }
            ItWasThisBigDB.speciesStats[species] = stats
        elseif not stats.best or record.weight > stats.best.weight then
            stats.best = record
        end
        if not stats.worst or record.weight < stats.worst.weight then
            stats.worst = record
        end
        if (rarityRanks[record.rarity] or 0) > (rarityRanks[stats.bestRarity] or 0) then
            stats.bestRarity = record.rarity
        end
    end
    ItWasThisBigDB.speciesStatsInitialized = true
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
    InitializeSpeciesStats()
end

local function OnLootMessage(message, source)
    local itemName = GetItemName(message)
    if not itemName then
        return
    end
    local playerName = UnitName("player")
    if source and source ~= "" and source ~= playerName then
        return
    end
    if not source and not string.find(message, "You receive loot", 1, true) then
        return
    end
    fishingChannelActive = false
    UpdateFishingSoundMute()
    local fish = GetFish(itemName)
    if not fish then
        return
    end
    local quantity = 1
    local _, _, amount = string.find(message, "|h%s*[xX](%d+)")
    if amount then
        quantity = math.min(tonumber(amount), 99)
    end
    for _ = 1, quantity do
        RecordCatch(fish, itemName)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
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
    elseif eventName == "UNIT_SPELLCAST_CHANNEL_START" then
        OnFishingSpellcastStart(...)
    elseif eventName == "UNIT_SPELLCAST_START" then
        OnFishingSpellcastStart(...)
    elseif eventName == "UNIT_SPELLCAST_INTERRUPTED"
        or eventName == "UNIT_SPELLCAST_FAILED" then
        OnFishingSpellcastEnd(...)
    elseif eventName == "PLAYER_LOGOUT" then
        fishingChannelActive = false
        RestoreGameSounds()
    end
end)

SLASH_ITWASTHISBIG1 = "/iwtb"
SLASH_ITWASTHISBIG2 = "/bigfish"
SlashCmdList["ITWASTHISBIG"] = function()
    IWTB.OpenWindow()
end
