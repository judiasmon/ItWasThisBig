table.getn = table.getn or function(values)
    return #values
end

local frames = {}
function CreateFrame()
    local frame = { events = {}, scripts = {} }
    function frame:RegisterEvent(eventName)
        self.events[eventName] = true
    end
    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end
    frames[#frames + 1] = frame
    return frame
end

function UnitName()
    return "Test Angler"
end

function GetRealZoneText()
    return "Elwynn Forest"
end

function GetNumSkillLines()
    return 1
end

function GetSkillLineInfo()
    return "Fishing", false, nil, 75, nil, 0, 150
end

function PlaySoundFile()
end

function date()
    return "2026-01-01 12:00"
end

SlashCmdList = {}
YOU = "You"
LOOT_ITEM_SELF = "You receive loot: %s."

dofile("IWTB_Fish.lua")
IWTB = {}
dofile("IWTB_Stats.lua")
dofile("IWTB_Audio.lua")
dofile("ItWasThisBig.lua")

local addonFrame
for _, frame in ipairs(frames) do
    if frame.events.CHAT_MSG_LOOT then
        addonFrame = frame
        break
    end
end
assert(addonFrame, "core loot event frame was not registered")

local function FireLoot(message, source)
    addonFrame.scripts.OnEvent(addonFrame, "CHAT_MSG_LOOT", message, source)
end

local function MakeCatch(species, weight, zone)
    return {
        species = species,
        weight = weight,
        length = 10,
        rarity = "common",
        fishingSkill = 50,
        weightMultiplier = 1.1,
        zone = zone,
        time = "2026-01-01 12:00",
        personalRecord = false
    }
end

local function TestLootCatchUpdatesZoneAndSpeciesStats()
    ItWasThisBigDB = nil
    IWTB.EnsureDatabase()
    FireLoot("You receive loot: [Raw Longjaw Mud Snapper]", YOU)

    assert(#ItWasThisBigDB.log == 1, "self-loot fish was not recorded")
    local catch = ItWasThisBigDB.log[1]
    assert(catch.species == "Longjaw Mud Snapper", "fish alias was not resolved")
    assert(catch.zone == "Elwynn Forest", "current zone was not saved on the catch")
    assert(ItWasThisBigDB.speciesStats[catch.species].count == 1,
        "species lifetime count was not incremented")
    assert(ItWasThisBigDB.zoneStats["Elwynn Forest"] == 1,
        "zone lifetime count was not incremented")

    local stats = IWTB.GetStatistics()
    assert(stats.mostCaught.species == catch.species and stats.mostCaught.count == 1,
        "most-caught summary did not reflect the catch")
    assert(stats.topZone.name == "Elwynn Forest" and stats.topZone.count == 1,
        "top-zone summary did not reflect the catch")
end

local function TestOtherPlayersLootIsIgnored()
    ItWasThisBigDB = nil
    IWTB.EnsureDatabase()
    FireLoot("Other receives loot: [Raw Longjaw Mud Snapper]", "Other")
    assert(#ItWasThisBigDB.log == 0, "another player's loot was recorded")
end

local function TestLifetimeAggregatesOutliveCappedLog()
    ItWasThisBigDB = nil
    IWTB.EnsureDatabase()
    for _ = 1, 502 do
        FireLoot("You receive loot: [Raw Longjaw Mud Snapper]", YOU)
    end

    assert(#ItWasThisBigDB.log == 500, "recent catch log is not capped at 500")
    assert(ItWasThisBigDB.speciesStats["Longjaw Mud Snapper"].count == 502,
        "lifetime species aggregate was reduced with the recent log")
    assert(ItWasThisBigDB.zoneStats["Elwynn Forest"] == 502,
        "lifetime zone aggregate was reduced with the recent log")
    local stats = IWTB.GetStatistics()
    assert(stats.mostCaught.count == 502 and stats.topZone.count == 502,
        "statistics page summaries are not using lifetime aggregates")
end

local function TestLegacySavedDataRebuildsAvailableAggregates()
    local loggedCatch = MakeCatch("Longjaw Mud Snapper", 0.02, "Westfall")
    local recordOnlyCatch = MakeCatch("Redgill", 0.15, nil)
    ItWasThisBigDB = {
        log = { loggedCatch },
        records = {
            ["Longjaw Mud Snapper"] = loggedCatch,
            Redgill = recordOnlyCatch
        },
        speciesStatsInitialized = false
    }
    IWTB.EnsureDatabase()

    assert(ItWasThisBigDB.speciesStats["Longjaw Mud Snapper"].count == 1,
        "legacy species aggregate did not rebuild from saved log")
    assert(ItWasThisBigDB.speciesStats.Redgill.count == 1,
        "legacy species aggregate did not recover a record-only species")
    assert(ItWasThisBigDB.zoneStats.Westfall == 1,
        "legacy zone aggregate did not rebuild from catches with zone data")
    assert(ItWasThisBigDB.zoneStats["Unknown zone"] == nil,
        "legacy catches without zone data were incorrectly assigned a zone")

    IWTB.EnsureDatabase()
    assert(ItWasThisBigDB.speciesStats["Longjaw Mud Snapper"].count == 1
        and ItWasThisBigDB.zoneStats.Westfall == 1,
        "legacy aggregates were counted again on repeated initialization")
end

TestLootCatchUpdatesZoneAndSpeciesStats()
TestOtherPlayersLootIsIgnored()
TestLifetimeAggregatesOutliveCappedLog()
TestLegacySavedDataRebuildsAvailableAggregates()
print("All It Was This Big tests passed.")
