IWTB = IWTB or {}
local IWTB = IWTB
local mainFrame
local currentView = "log"
local scrollOffset = 0
local rowFrames = {}
local iconFrames = {}
local tabs = {}
local selectedFish
local buttonSerial = 0

local function GetFishForHabitat()
    local fishRows = {}
    for _, fish in ipairs(IWTB_Fish) do
        if fish.habitat == currentView then
            table.insert(fishRows, fish)
        end
    end
    return fishRows
end

local function CreateText(parent, fontObject, text, point, relativeTo, relativePoint, x, y)
    local textFrame = parent:CreateFontString(nil, "OVERLAY", fontObject)
    textFrame:SetPoint(point, relativeTo, relativePoint, x, y)
    textFrame:SetText(text)
    return textFrame
end
IWTB.CreateText = CreateText

local function CreateButton(parent, text, width, height, onClick)
    buttonSerial = buttonSerial + 1
    IWTB.ButtonSerial = buttonSerial
    local button = CreateFrame("Button", "ItWasThisBigButton" .. buttonSerial,
        parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

StaticPopupDialogs["IWTB_CLEAR_LOG"] = {
    text = "Clear the recent catch log? Lifetime statistics and personal records will be kept.",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        IWTB.ClearCatchLog()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

local function GetDisplayRows()
    local rows = {}
    if currentView == "log" then
        for _, catch in ipairs(ItWasThisBigDB.log) do
            table.insert(rows, {
                text = string.format("%s  %.1f cm  %s  %s  %s%s",
                    catch.species, catch.length, IWTB.FormatWeight(catch.weight), catch.time,
                    catch.zone or "Zone unknown",
                    catch.personalRecord and "  [RECORD]" or ""),
                rarity = catch.rarity
            })
        end
    end
    return rows
end

local function FormatStatisticCatch(catch)
    if not catch then
        return "No catches yet"
    end
    return string.format("%s  |  %s  |  %s",
        catch.species, IWTB.FormatWeight(catch.weight), catch.zone or "Zone unknown")
end

local function UpdateStatistics()
    local stats = IWTB.GetStatistics()
    mainFrame.statsMostCaught:SetText(stats.mostCaught
        and string.format("Most caught: %s (%d)", stats.mostCaught.species, stats.mostCaught.count)
        or "Most caught: No catches yet")
    mainFrame.statsHeaviest:SetText("Heaviest fish: " .. FormatStatisticCatch(stats.heaviest))
    mainFrame.statsLightest:SetText("Lightest fish: " .. FormatStatisticCatch(stats.lightest))
    mainFrame.statsTopZone:SetText(stats.topZone
        and string.format("Zone with most catches: %s (%d)", stats.topZone.name, stats.topZone.count)
        or "Zone with most catches: No zone data yet")
end

local function FormatCatchSummary(catch)
    if not catch then
        return "No catch recorded"
    end
    return string.format("%.1f cm  %s  (%s)", catch.length, IWTB.FormatWeight(catch.weight), catch.time)
end

local function UpdateFishDetail()
    local fish = selectedFish
    local stats = fish and ItWasThisBigDB.speciesStats[fish.name]
    if not fish or not stats then
        mainFrame.detailFrame:Hide()
        return
    end

    local color = IWTB.RarityColors[stats.bestRarity] or IWTB.RarityColors.common
    mainFrame.detailIcon:SetTexture(IWTB.GetFishIcon(fish))
    mainFrame.detailIconFrame:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    mainFrame.detailName:SetText(fish.name)
    mainFrame.detailType:SetText(string.format("%s fish  |  Level %d  |  Best rarity: %s",
        fish.habitat == "fresh" and "Freshwater" or "Saltwater", fish.level, stats.bestRarity or "common"))
    mainFrame.detailCount:SetText(string.format("Caught: %d", stats.count))
    mainFrame.detailBest:SetText("Best (heaviest): " .. FormatCatchSummary(stats.best))
    mainFrame.detailWorst:SetText("Lightest: " .. FormatCatchSummary(stats.worst))
    local skill = stats.best and stats.best.fishingSkill or 0
    local multiplier = stats.best and stats.best.weightMultiplier or 1
    mainFrame.detailSkill:SetText(string.format("Fishing skill at best catch: %d  (+%d%% estimated weight)",
        skill, math.floor((multiplier - 1) * 100 + 0.5)))
    mainFrame.detailEstimate:SetText(string.format("Typical size: %.1f cm, %s",
        fish.length, IWTB.FormatWeight(fish.weight)))
    mainFrame.detailLore:SetText(fish.lore or "No field notes are available for this fish yet.")
    mainFrame.detailFrame:Show()
end

local function UpdateLogRows(rows)
    for i, rowFrame in ipairs(rowFrames) do
        local row = currentView == "log" and rows[i + scrollOffset] or nil
        if row then
            local color = IWTB.RarityColors[row.rarity] or IWTB.RarityColors.common
            rowFrame.label:SetText(row.text)
            rowFrame:SetBackdropBorderColor(color[1], color[2], color[3], 1)
            rowFrame:Show()
        else
            rowFrame:Hide()
        end
    end
end

local function UpdateFishGrid(habitatFish, showFishGrid)
    for i, iconFrame in ipairs(iconFrames) do
        local fish = showFishGrid and habitatFish[i + scrollOffset] or nil
        if fish then
            local stats = ItWasThisBigDB.speciesStats[fish.name]
            local color = stats and IWTB.RarityColors[stats.bestRarity] or IWTB.RarityColors.poor
            iconFrame.icon:SetTexture(stats and IWTB.GetFishIcon(fish) or IWTB.UnknownFishIcon)
            iconFrame.label:SetText(stats and fish.name or "???")
            iconFrame:SetBackdropBorderColor(color[1], color[2], color[3], 1)
            iconFrame.fish = stats and fish or nil
            iconFrame:Show()
        else
            iconFrame.fish = nil
            iconFrame:Hide()
        end
    end
end

local function UpdateSelectedView(fishPage)
    if fishPage and selectedFish then
        UpdateFishDetail()
    elseif mainFrame.detailFrame then
        mainFrame.detailFrame:Hide()
    end
end

local function UpdateEmptyState(rows)
    if mainFrame.emptyLabel then
        local isEmpty = currentView == "log" and table.getn(rows) == 0
        mainFrame.emptyLabel:SetText("No catches yet. Your fish will appear here.")
        if isEmpty then
            mainFrame.emptyLabel:Show()
        else
            mainFrame.emptyLabel:Hide()
        end
    end
end

local function UpdateAuxiliaryViews()
    local showSettings = currentView == "settings"
    local showStatistics = currentView == "stats"
    local showLog = currentView == "log"
    if showSettings then
        IWTB.UpdateSettingCheckboxes()
    end
    if showStatistics then
        UpdateStatistics()
        mainFrame.statsPanel:Show()
    else
        mainFrame.statsPanel:Hide()
    end
    if showLog then
        mainFrame.clearLogButton:Show()
        mainFrame.clearLogButton:SetEnabled(table.getn(ItWasThisBigDB.log) > 0)
    else
        mainFrame.clearLogButton:Hide()
    end
    for _, checkbox in ipairs(IWTB.SettingChecks) do
        if showSettings then
            checkbox:Show()
            checkbox.label:Show()
        else
            checkbox:Hide()
            checkbox.label:Hide()
        end
    end
end

local function UpdateCountLabel()
    if mainFrame.countLabel then
        if currentView == "log" then
            mainFrame.countLabel:SetText(string.format("%d catches", table.getn(ItWasThisBigDB.log)))
        elseif currentView == "fresh" or currentView == "salt" then
            local discovered = 0
            local total = 0
            for _, fish in ipairs(IWTB_Fish) do
                if fish.habitat == currentView then
                    total = total + 1
                    if ItWasThisBigDB.speciesStats[fish.name] then
                        discovered = discovered + 1
                    end
                end
            end
            if selectedFish then
                mainFrame.countLabel:SetText("Fish details")
            else
                mainFrame.countLabel:SetText(string.format("%d / %d found", discovered, total))
            end
        elseif currentView == "stats" then
            mainFrame.countLabel:SetText("Statistics")
        else
            mainFrame.countLabel:SetText("Preferences")
        end
    end
end

local function UpdateTabSelection()
    for _, tab in ipairs(tabs) do
        if tab.view == currentView then
            tab:SetAlpha(1)
        else
            tab:SetAlpha(0.7)
        end
    end
end

local function RefreshRows()
    local rows = GetDisplayRows()
    local fishPage = currentView == "fresh" or currentView == "salt"
    local showFishGrid = fishPage and not selectedFish
    local habitatFish = showFishGrid and GetFishForHabitat() or {}
    local maxOffset
    if showFishGrid then
        maxOffset = math.max(0, math.ceil((table.getn(habitatFish) - table.getn(iconFrames)) / 6) * 6)
    else
        maxOffset = math.max(0, table.getn(rows) - table.getn(rowFrames))
    end
    scrollOffset = math.min(scrollOffset, maxOffset)

    UpdateLogRows(rows)
    UpdateFishGrid(habitatFish, showFishGrid)
    UpdateSelectedView(fishPage)
    UpdateEmptyState(rows)
    UpdateAuxiliaryViews()
    UpdateCountLabel()
    UpdateTabSelection()
end

local function SetView(view)
    currentView = view
    scrollOffset = 0
    selectedFish = nil
    RefreshRows()
end

local function BuildWindow()
    mainFrame = CreateFrame("Frame", "ItWasThisBigFrame", UIParent, "BackdropTemplate")
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, "ItWasThisBigFrame")
    IWTB.MainFrame = mainFrame
    mainFrame:SetWidth(560)
    mainFrame:SetHeight(440)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    mainFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    mainFrame:SetBackdropColor(0.04, 0.05, 0.08, 0.96)
    mainFrame:SetBackdropBorderColor(0.65, 0.55, 0.32, 1)

    CreateText(mainFrame, "GameFontNormalLarge", "It Was This Big!", "TOPLEFT", mainFrame, "TOPLEFT", 18, -16)
    mainFrame.countLabel = CreateText(mainFrame, "GameFontHighlightSmall", "", "TOPRIGHT", mainFrame, "TOPRIGHT", -52, -21)

    local close = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() mainFrame:Hide() end)

    local tabSpecs = {
        { view = "settings", label = "Settings", width = 90 },
        { view = "fresh", label = "Freshwater", width = 105 },
        { view = "salt", label = "Saltwater", width = 100 },
        { view = "log", label = "Log", width = 75 },
        { view = "stats", label = "Stats", width = 70 }
    }
    local previousTab
    for _, spec in ipairs(tabSpecs) do
        local view = spec.view
        local tab = CreateButton(mainFrame, spec.label, spec.width, 24, function()
            SetView(view)
        end)
        tab.view = view
        if previousTab then
            tab:SetPoint("LEFT", previousTab, "RIGHT", 5, 0)
        else
            tab:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -44)
        end
        table.insert(tabs, tab)
        previousTab = tab
    end

    mainFrame.clearLogButton = CreateButton(mainFrame, "Clear log", 90, 22, function()
        if table.getn(ItWasThisBigDB.log) > 0 then
            StaticPopup_Show("IWTB_CLEAR_LOG")
        end
    end)
    mainFrame.clearLogButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -20, -73)

    IWTB.CreateSettingCheckbox(mainFrame, "Rare catch sound alert", "rareSound", -104)
    IWTB.CreateSettingCheckbox(mainFrame, "Epic catch sound alert", "epicSound", -134)
    IWTB.CreateSettingCheckbox(mainFrame, "Legendary catch sound alert", "legendarySound", -164)
    IWTB.CreateSettingCheckbox(mainFrame, "Personal record sound alert", "recordSound", -194)
    IWTB.CreateSettingCheckbox(mainFrame, "Minimap icon", "minimapButton", -224, IWTB.UpdateMinimapButton)
    IWTB.CreateSettingCheckbox(mainFrame, "Mute music, ambience and dialog while fishing",
        "muteGameSoundsWhileFishing", -254, IWTB.UpdateFishingSoundMute)
    mainFrame.emptyLabel = CreateText(mainFrame, "GameFontHighlight",
        "", "CENTER", mainFrame, "CENTER", 0, -15)
    mainFrame.statsPanel = CreateFrame("Frame", nil, mainFrame)
    mainFrame.statsPanel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 30, -96)
    mainFrame.statsPanel:SetWidth(500)
    mainFrame.statsPanel:SetHeight(250)
    mainFrame.statsTitle = CreateText(mainFrame.statsPanel, "GameFontNormalLarge",
        "Fishing Statistics", "TOPLEFT", mainFrame.statsPanel, "TOPLEFT", 0, 0)
    mainFrame.statsMostCaught = CreateText(mainFrame.statsPanel, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.statsTitle, "BOTTOMLEFT", 0, -25)
    mainFrame.statsHeaviest = CreateText(mainFrame.statsPanel, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.statsMostCaught, "BOTTOMLEFT", 0, -22)
    mainFrame.statsLightest = CreateText(mainFrame.statsPanel, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.statsHeaviest, "BOTTOMLEFT", 0, -22)
    mainFrame.statsTopZone = CreateText(mainFrame.statsPanel, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.statsLightest, "BOTTOMLEFT", 0, -22)
    mainFrame.statsPanel:Hide()
    mainFrame.detailFrame = CreateFrame("Frame", nil, mainFrame)
    mainFrame.detailFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -82)
    mainFrame.detailFrame:SetWidth(520)
    mainFrame.detailFrame:SetHeight(330)
    mainFrame.detailBackButton = CreateButton(mainFrame.detailFrame, "Back to fish", 105, 24, function()
        selectedFish = nil
        RefreshRows()
    end)
    mainFrame.detailBackButton:SetPoint("TOPLEFT", mainFrame.detailFrame, "TOPLEFT", 0, 0)

    mainFrame.detailIconFrame = CreateFrame("Frame", nil, mainFrame.detailFrame, "BackdropTemplate")
    mainFrame.detailIconFrame:SetWidth(60)
    mainFrame.detailIconFrame:SetHeight(60)
    mainFrame.detailIconFrame:SetPoint("TOPLEFT", mainFrame.detailFrame, "TOPLEFT", 6, -37)
    mainFrame.detailIconFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    mainFrame.detailIcon = mainFrame.detailIconFrame:CreateTexture(nil, "ARTWORK")
    mainFrame.detailIcon:SetWidth(56)
    mainFrame.detailIcon:SetHeight(56)
    mainFrame.detailIcon:SetPoint("CENTER", mainFrame.detailIconFrame, "CENTER", 0, 0)
    mainFrame.detailName = CreateText(mainFrame.detailFrame, "GameFontNormalLarge", "",
        "TOPLEFT", mainFrame.detailFrame, "TOPLEFT", 82, -43)
    mainFrame.detailType = CreateText(mainFrame.detailFrame, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.detailName, "BOTTOMLEFT", 0, -7)
    mainFrame.detailCount = CreateText(mainFrame.detailFrame, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.detailFrame, "TOPLEFT", 8, -117)
    mainFrame.detailBest = CreateText(mainFrame.detailFrame, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.detailCount, "BOTTOMLEFT", 0, -8)
    mainFrame.detailWorst = CreateText(mainFrame.detailFrame, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.detailBest, "BOTTOMLEFT", 0, -6)
    mainFrame.detailSkill = CreateText(mainFrame.detailFrame, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.detailWorst, "BOTTOMLEFT", 0, -6)
    mainFrame.detailEstimate = CreateText(mainFrame.detailFrame, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.detailSkill, "BOTTOMLEFT", 0, -6)
    mainFrame.detailLore = CreateText(mainFrame.detailFrame, "GameFontHighlight",
        "", "TOPLEFT", mainFrame.detailEstimate, "BOTTOMLEFT", 0, -12)
    mainFrame.detailLore:SetWidth(495)
    mainFrame.detailLore:SetJustifyH("LEFT")

    for i = 1, 12 do
        local row = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
        row:SetWidth(520)
        row:SetHeight(25)
        row:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -103 - (i - 1) * 26)
        row:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        row:SetBackdropColor(0.02, 0.02, 0.02, 0.75)
        row:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        row.label = CreateText(row, "GameFontHighlightSmall", "", "LEFT", row, "LEFT", 8, 0)
        row.label:SetWidth(500)
        row.label:SetJustifyH("LEFT")
        rowFrames[i] = row
    end

    for i = 1, 24 do
        local iconFrame = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
        iconFrame:SetWidth(80)
        iconFrame:SetHeight(74)
        local column = (i - 1) % 6
        local row = math.floor((i - 1) / 6)
        iconFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20 + column * 85, -102 - row * 78)
        iconFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        iconFrame:SetBackdropColor(0.02, 0.02, 0.02, 0.85)
        iconFrame.icon = iconFrame:CreateTexture(nil, "ARTWORK")
        iconFrame.icon:SetWidth(40)
        iconFrame.icon:SetHeight(40)
        iconFrame.icon:SetPoint("TOP", iconFrame, "TOP", 0, -4)
        iconFrame.label = CreateText(iconFrame, "GameFontHighlightSmall", "",
            "BOTTOM", iconFrame, "BOTTOM", 0, 3)
        iconFrame.label:SetWidth(76)
        iconFrame.label:SetJustifyH("CENTER")
        iconFrame:SetScript("OnClick", function(self)
            if self.fish then
                selectedFish = self.fish
                RefreshRows()
            end
        end)
        iconFrames[i] = iconFrame
    end

    mainFrame:EnableMouseWheel(true)
    mainFrame:SetScript("OnMouseWheel", function(_, delta)
        if currentView == "settings" or selectedFish then
            return
        end
        local maxOffset
        if currentView == "fresh" or currentView == "salt" then
            maxOffset = math.max(0, math.ceil((table.getn(GetFishForHabitat()) - table.getn(iconFrames)) / 6) * 6)
            scrollOffset = math.max(0, math.min(maxOffset, scrollOffset - delta * 6))
        else
            maxOffset = math.max(0, table.getn(GetDisplayRows()) - table.getn(rowFrames))
            scrollOffset = math.max(0, math.min(maxOffset, scrollOffset - delta))
        end
        RefreshRows()
    end)
    mainFrame.RefreshRows = RefreshRows
    IWTB.RefreshRows = RefreshRows
    IWTB.UpdateSettingCheckboxes()
    mainFrame:Hide()
    RefreshRows()
end

function IWTB.OpenWindow()
    IWTB.EnsureDatabase()
    if not mainFrame then
        BuildWindow()
    end
    mainFrame:Show()
    RefreshRows()
end
