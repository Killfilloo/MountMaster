local addonName, MM = ... 
_G[addonName] = MM -- This makes MM globally accessible

-- Load the locale (fallback to enGB)
MM.Locales = MountMasterLocales and MountMasterLocales.enGB or {}

--MM.OnlyUsable = true -- Toggle this via your settings later?

local MainColor = "|cFFDDAA00"
local Reset = "|r"

MM.SelectedExpansion = -1 
local MyMountData = MountMasterDB -- Ensure this is globally defined or passed in
MM.FullMountList = {} -- All mounts from API
MM.FilteredList = {}  -- Mounts to display based on expansion selection

function GetMountStatus(mountID)
    local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
    return isCollected -- Returns true if player owns it
end

function MM:BuildFullList()
    -- Build a fast lookup table by mountID from the sequential database
    local DBByMountID = {}
    if MountMasterDB then
        for _, entry in ipairs(MountMasterDB) do
            if type(entry) == "table" and entry.mountID then
                DBByMountID[entry.mountID] = entry
            end
        end
    end

    local mountIDs = C_MountJournal.GetMountIDs()
    wipe(MM.FullMountList)
    
    local playerFaction = UnitFactionGroup("player") -- "Alliance" or "Horde"

    for _, id in ipairs(mountIDs) do
        local name, _, _, _, _, _, _, isFactionSpecific, faction, _, isCollected = C_MountJournal.GetMountInfoByID(id)
        
        -- Look up directly using Blizzard's runtime ID matched against entry.mountID
        local dbEntry = DBByMountID[id]

        local expansionID = -2 
        if dbEntry and dbEntry.expansion ~= nil then
            expansionID = dbEntry.expansion
        end
        
        local categoryID = dbEntry and dbEntry.category or 0
        local dbFaction = dbEntry and dbEntry.faction or nil -- 1 = Alliance, 2 = Horde
        local dbUnobtainable = dbEntry and dbEntry.unobtainable or 0

        local isRestricted = false

        -- Check explicit database faction tag first (1 = Alliance, 2 = Horde)
        if dbFaction then
            if (dbFaction == 1 and playerFaction ~= "Alliance") or (dbFaction == 2 and playerFaction ~= "Horde") then
                isRestricted = true
            end
        elseif isFactionSpecific then
            -- Fallback to Blizzard's API flag if DB tag isn't added yet
            if (faction == 0 and playerFaction == "Alliance") or (faction == 1 and playerFaction == "Horde") then
                -- Note: Blizzard faction 0 is usually Horde or Alliance depending on context, 
                -- but let's check basic usability API as fallback:
            end
        end

        -- Double-check general usability (class restrictions, etc.)
        local isUsable, errorText = C_MountJournal.GetMountUsabilityByID(id, false)
        if not isUsable and errorText then
            if string.find(errorText, "class") or 
               string.find(errorText, "right") or 
               string.find(errorText, "Requires") then
                isRestricted = true
            end
        end
        
        -- If OnlyUsable setting is active, we can flag restriction status clearly
        table.insert(MM.FullMountList, {
            id = id,
            name = name,
            isCollected = isCollected,
            expansion = expansionID,
            isRestricted = isRestricted,
            category = categoryID,
            faction = dbFaction,
            unobtainable = dbUnobtainable,
        })
    end
end
MM:BuildFullList()

-- [[ MAIN FRAME SETUP ]] --
MM.MainFrame = CreateFrame("Frame", "MountMasterFrame", UIParent, "BackdropTemplate")
tinsert(UISpecialFrames, "MountMasterFrame")
MM.MainFrame:SetSize(1236, 655)
MM.MainFrame:SetPoint("CENTER")
MM.MainFrame:SetMovable(true)
MM.MainFrame:EnableMouse(true)
MM.MainFrame:RegisterForDrag("LeftButton")
MM.MainFrame:SetScript("OnDragStart", MM.MainFrame.StartMoving)
MM.MainFrame:SetScript("OnDragStop", MM.MainFrame.StopMovingOrSizing)

MM.MainFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
MM.MainFrame:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
MM.MainFrame:SetBackdropBorderColor(0.12, 0.12, 0.12, 1)

-- Left Panel (Expansions)
MM.LeftContainer = CreateFrame("Frame", nil, MM.MainFrame,"BackdropTemplate")
MM.LeftContainer:SetPoint("TOPLEFT", 10, -60)
MM.LeftContainer:SetPoint("BOTTOMLEFT", 10, 10)
MM.LeftContainer:SetWidth(330)
MM.LeftContainer:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
MM.LeftContainer:SetBackdropColor(0.5, 0.06, 0.06, 0.98)

-- Right Panel (Optional: for details/filters)
MM.RightContainer = CreateFrame("Frame", nil, MM.MainFrame,"BackdropTemplate")
MM.RightContainer:SetPoint("TOPRIGHT", -10, -60)
MM.RightContainer:SetPoint("BOTTOMRIGHT", -10, 10)
MM.RightContainer:SetWidth(330)
MM.RightContainer:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
MM.RightContainer:SetBackdropColor(0.06, 0.5, 0.06, 0.98)

-- Content Panel (Mount Grid)
MM.ContentContainer = CreateFrame("Frame", nil, MM.MainFrame,"BackdropTemplate")
MM.ContentContainer:ClearAllPoints()
MM.ContentContainer:SetPoint("TOPLEFT", MM.LeftContainer, "TOPRIGHT", 10, 0)
MM.ContentContainer:SetPoint("BOTTOMRIGHT", MM.RightContainer, "BOTTOMLEFT", -10, 0)
MM.ContentContainer:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
MM.ContentContainer:SetBackdropColor(0.06, 0.06, 0.5, 0.98)

--- [[ HEADER ]] --
local header = CreateFrame("Frame", nil, MM.MainFrame)
header:SetSize(1236, 60)
header:SetPoint("TOPLEFT")

header.Icon = header:CreateTexture(nil, "ARTWORK")
header.Icon:SetSize(40, 40)
header.Icon:SetPoint("TOPLEFT", 15, -10)
header.Icon:SetTexture("Interface\\Icons\\MountJournalPortrait") 
header.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

header.Title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header.Title:SetPoint("TOPLEFT", header.Icon, "TOPRIGHT", 10, -5)
header.Title:SetText(MainColor .. "Mount " .. Reset .. "Master")

MM.HeaderCounter = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MM.HeaderCounter:SetPoint("TOPLEFT", header.Title, "BOTTOMLEFT", 0, -4)
MM.HeaderCounter:SetTextColor(0.5, 0.5, 0.5)

-- [[ CLOSE BUTTON (Custom Font Size Style) ]] --
header.Close = CreateFrame("Button", nil, header)
header.Close:SetSize(24, 24)
header.Close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, -12)

header.Close.Text = header.Close:CreateFontString(nil, "OVERLAY")
header.Close.Text:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE") -- Adjust the 20 to make it larger or smaller as needed
header.Close.Text:SetPoint("CENTER", 0, 1)
header.Close.Text:SetText("×")
header.Close.Text:SetTextColor(0.6, 0.6, 0.6, 1)

header.Close:SetScript("OnEnter", function(self)
    self.Text:SetTextColor(1, 0.8, 0.2, 1)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Close", 1, 1, 1)
    GameTooltip:Show()
end)

header.Close:SetScript("OnLeave", function(self)
    self.Text:SetTextColor(0.6, 0.6, 0.6, 1)
    GameTooltip:Hide()
end)

header.Close:SetScript("OnClick", function()
    MM.MainFrame:Hide()
end)

-- [[ 2. SETTINGS GEAR BUTTON (Anchored cleanly to the left of Close) ]] --
local gearBtn = CreateFrame("Button", nil, header)
gearBtn:SetSize(24, 24)
gearBtn:SetPoint("RIGHT", header.Close, "LEFT", -6, 0)
gearBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")

gearBtn.icon = gearBtn:CreateTexture(nil, "ARTWORK")
gearBtn.icon:SetAllPoints(gearBtn)

gearBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Settings", 1, 1, 1)
    GameTooltip:Show()
end)
gearBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
gearBtn:SetScript("OnClick", function()
    if MountMasterSettingsModal then
        MountMasterSettingsModal:SetShown(not MountMasterSettingsModal:IsShown())
    end
end)

-- [[ 3. SEARCH BOX (Right-aligned flush with ContentContainer) ]] --
header.Search = CreateFrame("EditBox", nil, header, "SearchBoxTemplate")
header.Search:SetSize(250, 32)
header.Search:SetPoint("TOPRIGHT", header, "TOPRIGHT", -350, -14)
header.Search:SetAutoFocus(false)
header.Search.Instructions:SetText("Search mounts...")
header.Search:SetScript("OnTextChanged", function(self)
    SearchBoxTemplate_OnTextChanged(self)
    
    local text = self:GetText():trim()
    MM.SearchQuery = (text ~= "") and text:lower() or nil
    
    MM.CurrentPage = 1 -- Reset to page 1 on new search
    if MM.UpdateMountGrid then
        MM:UpdateMountGrid()
    end
end)

if header.Search.Left then header.Search.Left:Hide() end
if header.Search.Middle then header.Search.Middle:Hide() end
if header.Search.Right then header.Search.Right:Hide() end
if header.Search.SearchIcon then
    header.Search.SearchIcon:ClearAllPoints()
    header.Search.SearchIcon:SetPoint("LEFT", header.Search, "LEFT", 48, 0)
    header.Search.SearchIcon:SetVertexColor(0.6, 0.6, 0.6, 1)
end

header.Search.bg = CreateFrame("Frame", nil, header.Search, "BackdropTemplate")
header.Search.bg:SetAllPoints()
header.Search.bg:SetFrameLevel(header.Search:GetFrameLevel() - 1)
header.Search.bg:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1
})
header.Search.bg:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
header.Search.bg:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

function MM:UpdateHeaderCount()
    local owned = 0
    local total = 0
    
    if MM.FullMountList then
        for _, m in ipairs(MM.FullMountList) do
            if MM.SelectedExpansion == -1 or m.expansion == MM.SelectedExpansion then
                -- Only count mounts the player can use/access
                if not m.isRestricted and not (MM.filterUnobtainable and m.category == 0) then
                    total = total + 1
                    if m.isCollected then
                        owned = owned + 1
                    end
                end
            end
        end
    end
    
    if MM.HeaderCounter then
        MM.HeaderCounter:SetText(owned .. " / " .. total .. " Collected")
    end
end

MM:UpdateHeaderCount()

if MM.UpdateMountGrid then MM:UpdateMountGrid() end

-- [[ SLASH COMMAND ]] --
SLASH_MOUNTMASTER1 = "/mm"
SlashCmdList["MOUNTMASTER"] = function()
    MM.MainFrame:SetShown(not MM.MainFrame:IsShown())
end

MM.MainFrame:Show()

local mmrlbtn = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
mmrlbtn:SetPoint("TOPLEFT")
mmrlbtn:SetSize(60, 30)
mmrlbtn:SetText("Reload")
mmrlbtn:SetScript("OnClick", ReloadUI)

local mmdsbtn = CreateFrame("Button", nil, mmrlbtn, "UIPanelButtonTemplate")
mmdsbtn:SetPoint("TOP", mmrlbtn, "TOP", 0, -30)
mmdsbtn:SetSize(40, 30)
mmdsbtn:SetText("MM")
mmdsbtn:SetScript("OnClick", function() SlashCmdList["MOUNTMASTER"]("") end)