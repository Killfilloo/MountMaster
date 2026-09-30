local addonName, MM = ...

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

-- [[ TITLE & CLOSE BUTTON ]] --
local titleText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
titleText:SetPoint("TOP", settingsFrame, "TOP", 0, -15)
titleText:SetText("Mount Master Settings")

local closeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() settingsFrame:Hide() end)

-- [[ SETTINGS OPTIONS WIDGETS ]] --
local checkboxes = {}

local function CreateCheckbox(label, yOffset, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 25, yOffset)
    cb.Text:SetText(label)
    cb.Text:SetFontObject("GameFontHighlight")
    
    cb.RefreshState = function()
        cb:SetChecked(getFunc())
    end
    
    cb:SetScript("OnClick", function(self)
        setFunc(self:GetChecked())
        
        -- Trigger UI refresh across panels affected by filtering/visual changes
        MM.CurrentPage = 1
        if MM.UpdateMountGrid then MM:UpdateMountGrid() end
        if MM.RefreshExpansionPanel then MM:RefreshExpansionPanel() end
        if MM.RefreshCategoryPanel then MM:RefreshCategoryPanel() end
    end)
    
    table.insert(checkboxes, cb)
    return cb
end

-- Create Checkboxes connected to MountMasterSettings
CreateCheckbox("Use 3D Models (where available)", -60, 
    function() return MountMasterSettings.Use3DModels end,
    function(value) MountMasterSettings.Use3DModels = value end
)

CreateCheckbox("Only show usable mounts", -105, 
    function() return MountMasterSettings.OnlyUsable end,
    function(value) MountMasterSettings.OnlyUsable = value end
)

CreateCheckbox("Filter Unobtainable Mounts", -150, 
    function() return MountMasterSettings.filterUnobtainable end,
    function(value) MountMasterSettings.filterUnobtainable = value end
)


-- Overlay & Visual Synchronization
settingsFrame:SetScript("OnShow", function() 
    blurOverlay:Show()
    for _, cb in ipairs(checkboxes) do
        cb:RefreshState()
    end
end)

settingsFrame:SetScript("OnHide", function() 
    blurOverlay:Hide() 
end)

-- [[ SAVED VARIABLES INITIALIZATION ]] --
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        -- 1. Initialize Saved Variables table if first load
        MountMasterSettings = MountMasterSettings or {}

        -- 2. Set defaults if keys are undefined
        if MountMasterSettings.Use3DModels == nil then MountMasterSettings.Use3DModels = true end
        if MountMasterSettings.OnlyUsable == nil then MountMasterSettings.OnlyUsable = false end
        if MountMasterSettings.filterUnobtainable == nil then MountMasterSettings.filterUnobtainable = false end

        -- 3. Expose to MM module table
        MM.Settings = MountMasterSettings

        -- Legacy backward-compatibility aliases
        MM.Use3DModels = MountMasterSettings.Use3DModels
        MM.OnlyUsable = MountMasterSettings.OnlyUsable
        MM.filterUnobtainable = MountMasterSettings.filterUnobtainable

        self:UnregisterEvent("ADDON_LOADED")
    end
end)