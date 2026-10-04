IWTB = IWTB or {}
local IWTB = IWTB
IWTB.SettingChecks = IWTB.SettingChecks or {}
IWTB.ButtonSerial = IWTB.ButtonSerial or 0
IWTB.RarityColors = IWTB.RarityColors or {
    poor = { 0.62, 0.62, 0.62 },
    common = { 1, 1, 1 },
    uncommon = { 0.12, 1, 0 },
    rare = { 0, 0.44, 0.87 },
    epic = { 0.64, 0.21, 0.93 },
    legendary = { 1, 0.5, 0 }
}
IWTB.UnknownFishIcon = "Interface\\Icons\\INV_Misc_QuestionMark"

function IWTB.CreateSettingCheckbox(parent, label, settingKey, y, onChanged)
    IWTB.ButtonSerial = IWTB.ButtonSerial + 1
    local checkbox = CreateFrame("CheckButton", "ItWasThisBigCheck" .. IWTB.ButtonSerial, parent)
    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, y)
    checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkbox.label = IWTB.CreateText(checkbox, "GameFontHighlight", label,
        "LEFT", checkbox, "RIGHT", 4, 0)
    checkbox.label:SetJustifyH("LEFT")
    checkbox:SetScript("OnClick", function(self)
        ItWasThisBigDB.settings[settingKey] = self:GetChecked() and true or false
        if onChanged then
            onChanged()
        end
    end)
    checkbox.settingKey = settingKey
    table.insert(IWTB.SettingChecks, checkbox)
    return checkbox
end

function IWTB.UpdateSettingCheckboxes()
    for _, checkbox in ipairs(IWTB.SettingChecks) do
        checkbox:SetChecked(ItWasThisBigDB.settings[checkbox.settingKey])
    end
end
