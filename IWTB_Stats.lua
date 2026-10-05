IWTB = IWTB or {}
local IWTB = IWTB
local rarityRanks = { poor = 1, common = 2, uncommon = 3, rare = 4, epic = 5, legendary = 6 }
local fishBySpecies = {}

for _, fish in ipairs(IWTB_Fish) do
    fishBySpecies[fish.name] = fish
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

function IWTB.UpdateCatchStatistics(fish, catch)
    -- Lifetime totals remain independent of the rolling catch log.
    UpdateSpeciesStats(fish, catch)
    if catch.zone then
        ItWasThisBigDB.zoneStats[catch.zone] = (ItWasThisBigDB.zoneStats[catch.zone] or 0) + 1
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
            ItWasThisBigDB.speciesStats[species] = {
                count = 1,
                best = record,
                worst = record,
                bestRarity = record.rarity or "poor"
            }
        else
            if not stats.best or record.weight > stats.best.weight then
                stats.best = record
            end
            if not stats.worst or record.weight < stats.worst.weight then
                stats.worst = record
            end
            if (rarityRanks[record.rarity] or 0) > (rarityRanks[stats.bestRarity] or 0) then
                stats.bestRarity = record.rarity
            end
        end
    end
    ItWasThisBigDB.speciesStatsInitialized = true
end

local function InitializeZoneStats()
    if ItWasThisBigDB.zoneStatsInitialized then
        return
    end

    ItWasThisBigDB.zoneStats = {}
    for _, catch in ipairs(ItWasThisBigDB.log) do
        if catch.zone then
            ItWasThisBigDB.zoneStats[catch.zone] = (ItWasThisBigDB.zoneStats[catch.zone] or 0) + 1
        end
    end
    ItWasThisBigDB.zoneStatsInitialized = true
end

function IWTB.InitializeStatistics()
    InitializeSpeciesStats()
    InitializeZoneStats()
end

function IWTB.GetStatistics()
    local result = {
        mostCaught = nil,
        heaviest = nil,
        lightest = nil,
        topZone = nil
    }

    for _, fish in ipairs(IWTB_Fish) do
        local stats = ItWasThisBigDB.speciesStats[fish.name]
        if stats and stats.count > 0 then
            if not result.mostCaught or stats.count > result.mostCaught.count then
                result.mostCaught = { species = fish.name, count = stats.count }
            end
            if stats.worst and (not result.lightest or stats.worst.weight < result.lightest.weight) then
                result.lightest = stats.worst
            end
        end

        local record = ItWasThisBigDB.records[fish.name]
        if record and (not result.heaviest or record.weight > result.heaviest.weight) then
            result.heaviest = record
        end
    end

    for zone, count in pairs(ItWasThisBigDB.zoneStats) do
        if not result.topZone or count > result.topZone.count then
            result.topZone = { name = zone, count = count }
        end
    end
    return result
end
