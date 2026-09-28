local addonName, _ = ...
local MM = _G[addonName]

-- [[ SETTINGS POPUP FRAME CREATION ]] --
local settingsFrame = CreateFrame("Frame", "MountMasterSettingsModal", MM.MainFrame, "BackdropTemplate")
settingsFrame:SetSize(380, 260)
settingsFrame:SetPoint("CENTER", MM.MainFrame, "CENTER", 0, 0)
settingsFrame:SetFrameStrata("DIALOG")
settingsFrame:SetFrameLevel(100)
settingsFrame:Hide()

settingsFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1
})
settingsFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
settingsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

settingsFrame:SetPropagateKeyboardInput(true)
settingsFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:SetPropagateKeyboardInput(false)
        settingsFrame:Hide()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

-- [[ FOCUS SHIELD OVERLAY ]] --
local blurOverlay = CreateFrame("Frame", nil, MM.MainFrame, "BackdropTemplate")
blurOverlay:SetAllPoints(MM.MainFrame)
blurOverlay:SetFrameStrata("DIALOG")
blurOverlay:SetFrameLevel(95)
blurOverlay:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground"
})
blurOverlay:SetBackdropColor(0, 0, 0, 0.6)
blurOverlay:EnableMouse(true)
blurOverlay:EnableMouseWheel(true)
blurOverlay:Hide()

settingsFrame:SetScript("OnShow", function() blurOverlay:Show() end)
settingsFrame:SetScript("OnHide", function() blurOverlay:Hide() end)

-- [[ TITLE & CLOSE BUTTON ]] --
local titleText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
titleText:SetPoint("TOP", settingsFrame, "TOP", 0, -15)
titleText:SetText("Mount Master Settings")

local closeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() settingsFrame:Hide() end)

-- [[ SETTINGS OPTIONS WIDGETS ]] --
local function CreateCheckbox(label, yOffset, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 25, yOffset)
    cb.Text:SetText(label)
    cb.Text:SetFontObject("GameFontHighlight")
    
    cb:SetChecked(getFunc())
    
    cb:SetScript("OnClick", function(self)
        setFunc(self:GetChecked())
        if MM.UpdateMountGrid then
            MM:UpdateMountGrid()
        end
    end)
    
    return cb
end

CreateCheckbox("Use 3D Models (where available)", -60, 
    function() return MM.Use3DModels end,
    function(value) MM.Use3DModels = value end
)

CreateCheckbox("Filter Unusable Mounts", -105, 
    function() return MM.OnlyUsable end,
    function(value) MM.OnlyUsable = value end
)

CreateCheckbox("Filter Unobtainable Mounts (Category 15)", -150, 
    function() return MM.filterUnobtainable end,
    function(value) MM.filterUnobtainable = value end
)