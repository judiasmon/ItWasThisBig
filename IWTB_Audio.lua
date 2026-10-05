IWTB = IWTB or {}
local IWTB = IWTB

local fishingCastActive = false
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

local function IsFishingSpell(...)
    local fishingSpellName = "fishing"
    if GetSpellInfo then
        local spellName = GetSpellInfo(7620)
        if spellName then
            fishingSpellName = NormalizeName(spellName)
        end
    end

    for i = 1, select("#", ...) do
        local spell = select(i, ...)
        if spell == 7620 or (type(spell) == "string" and NormalizeName(spell) == fishingSpellName) then
            return true
        end
    end
    return false
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

function IWTB.UpdateFishingSoundMute()
    if fishingCastActive and ItWasThisBigDB.settings.muteGameSoundsWhileFishing then
        MuteGameSounds()
    else
        RestoreGameSounds()
    end
end

function IWTB.OnFishingLootReceived()
    fishingCastActive = false
    IWTB.UpdateFishingSoundMute()
end

local function PlayCatchSound(file)
    if PlaySoundFile then
        PlaySoundFile(file, "Master")
    elseif PlaySound then
        PlaySound("RaidWarning")
    end
end

function IWTB.AlertCatch(catch)
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

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", function(_, eventName, unit, ...)
    if eventName == "PLAYER_LOGOUT" then
        fishingCastActive = false
        RestoreGameSounds()
    elseif unit == "player" and IsFishingSpell(...) then
        if eventName == "UNIT_SPELLCAST_START" or eventName == "UNIT_SPELLCAST_CHANNEL_START" then
            fishingCastActive = true
            IWTB.UpdateFishingSoundMute()
        elseif eventName == "UNIT_SPELLCAST_INTERRUPTED" or eventName == "UNIT_SPELLCAST_FAILED" then
            fishingCastActive = false
            IWTB.UpdateFishingSoundMute()
        end
    end
end)
