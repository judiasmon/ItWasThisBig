IWTB = IWTB or {}
local IWTB = IWTB
local minimapButton

function IWTB.ToggleWindow()
    if IWTB.MainFrame and IWTB.MainFrame:IsShown() then
        IWTB.MainFrame:Hide()
    elseif IWTB.OpenWindow then
        IWTB.OpenWindow()
    end
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
            IWTB.ToggleWindow()
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
                ItWasThisBigDB.settings.minimapAngle = math.deg(math.atan2(y, x))
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
