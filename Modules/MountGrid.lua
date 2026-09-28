local addonName, _ = ... 
local MM = _G[addonName]

-- [[ 1. VARIABLES ]] --
MM.CurrentPage = 1
MM.SelectedCategory = 0

local pageSize = 16 
local columns = 4
local btnSize = 125
local padding = 12

-- Settings boolean: true for 3D models (where available), false for static icons only
MM.Use3DModels = true
MM.OnlyUsable = false -- Toggle this via your settings later
MM.filterUnobtainable = false -- Default to true to filter out unobtainable mounts
MM.HideUnobtainable = false -- Toggle this via settings later

-- [[ 2. GRID CONFIGURATION ]] --
local gridPanel = CreateFrame("Frame", "MountMasterGridPanel", MM.ContentContainer)
gridPanel:SetPoint("TOP", MM.ContentContainer, "TOP", 0, -15)
-- Set fixed size to match 4x4 grid + padding
gridPanel:SetSize((btnSize * columns) + (padding * (columns - 1)), (btnSize * 4) + (padding * 3))

-- Enable mouse wheel scrolling on the grid panel
gridPanel:EnableMouseWheel(true)
gridPanel:SetScript("OnMouseWheel", function(self, delta)
    local maxPages = math.max(1, math.ceil(#MM.FilteredList / pageSize))
    if delta < 0 then
        -- Scroll Down -> Next Page
        if MM.CurrentPage < maxPages then
            MM.CurrentPage = MM.CurrentPage + 1
            MM:UpdateMountGrid()
        end
    else
        -- Scroll Up -> Previous Page
        if MM.CurrentPage > 1 then
            MM.CurrentPage = MM.CurrentPage - 1
            MM:UpdateMountGrid()
        end
    end
end)

-- [[ 3. NAVIGATION CONTAINER ]] --
local navContainer = CreateFrame("Frame", nil, MM.MainFrame, "BackdropTemplate")
navContainer:SetHeight(35)

local line = navContainer:CreateTexture(nil, "OVERLAY")
line:SetPoint("TOPLEFT", 0, 0)
line:SetPoint("TOPRIGHT", 0, 0)
line:SetHeight(1)
line:SetColorTexture(0.3, 0.3, 0.3, 1)

-- [[ 4. NAVIGATION BUTTONS ]] --
local function CreateNavButton(text)
    local btn = CreateFrame("Button", nil, navContainer, "BackdropTemplate")
    btn:SetSize(30, 30)
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8", 
        edgeSize = 1
    })
    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btn.Text:SetPoint("CENTER")
    btn.Text:SetText(text)
    
    btn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.7, 0.5, 0, 1) end)
    btn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) end)
    return btn
end

local prevBtn = CreateNavButton("<")
prevBtn:SetPoint("LEFT", navContainer, "LEFT", 0, 0)
prevBtn:SetScript("OnClick", function() MM.CurrentPage = MM.CurrentPage - 1; MM:UpdateMountGrid() end)

local pageText = navContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pageText:SetPoint("CENTER", navContainer, "CENTER", 0, 0)
pageText:SetWidth(150)

local nextBtn = CreateNavButton(">")
nextBtn:SetPoint("RIGHT", navContainer, "RIGHT", 0, 0)
nextBtn:SetScript("OnClick", function() MM.CurrentPage = MM.CurrentPage + 1; MM:UpdateMountGrid() end)

-- [[ 5. BUTTON POOL ]] --
local buttons = {}
for i = 1, pageSize do
    local btn = CreateFrame("Button", nil, gridPanel, "BackdropTemplate")
    btn:SetSize(btnSize, btnSize)
    
    local col = (i - 1) % columns
    local row = math.floor((i - 1) / columns)
    btn:SetPoint("TOPLEFT", (col * (btnSize + padding)), -(row * (btnSize + padding)))
    
    btn:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    btn.mmModel = CreateFrame("DressUpModel", nil, btn)
    btn.mmModel:SetPoint("TOPLEFT", 2, -2)
    btn.mmModel:SetPoint("BOTTOMRIGHT", -2, 35)

    btn.mmIcon = btn:CreateTexture(nil, "ARTWORK")
    btn.mmIcon:SetAllPoints(btn.mmModel)
    btn.mmIcon:SetTexCoord(0.08, 0.93, 0.08, 0.93)
    btn.mmIcon:Hide()

    btn.mmLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.mmLabel:SetPoint("TOP", btn.mmModel, "BOTTOM", 0, -2)
    btn.mmLabel:SetSize(btnSize - 10, 30)
    
    buttons[i] = btn
end

-- Lock navContainer width to grid width
navContainer:SetPoint("TOPLEFT", buttons[13], "BOTTOMLEFT", 0, -10)
navContainer:SetPoint("TOPRIGHT", buttons[16], "BOTTOMRIGHT", 0, -10)

-- [[ 6. UPDATE FUNCTION ]] --
function MM:UpdateMountGrid()
    wipe(MM.FilteredList)
    
    for _, data in ipairs(MM.FullMountList) do
        local matchesExpansion = (MM.SelectedExpansion == -2 or data.expansion == MM.SelectedExpansion)
        local matchesCategory = (MM.SelectedCategories[data.category] == true)
        local keepMount = true
        
        -- Faction / Class restriction check
        if MM.OnlyUsable and data.isRestricted then
            keepMount = false
        end
        
        -- Unobtainable check based on the new tag and setting
        if MM.HideUnobtainable and data.unobtainable == 1 then
            keepMount = false
        end
        
        -- Search Query match
        if MM.SearchQuery and MM.SearchQuery ~= "" then
            local mountNameLower = data.name and data.name:lower() or ""
            if not string.find(mountNameLower, MM.SearchQuery, 1, true) then
                keepMount = false
            end
        end
        
        if matchesExpansion and matchesCategory and keepMount then
            table.insert(MM.FilteredList, data)
        end
    end

    local maxPages = math.max(1, math.ceil(#MM.FilteredList / pageSize))
    if MM.CurrentPage > maxPages then MM.CurrentPage = maxPages end
    if MM.CurrentPage < 1 then MM.CurrentPage = 1 end

    pageText:SetText("Page " .. MM.CurrentPage .. " / " .. maxPages)
    prevBtn:SetEnabled(MM.CurrentPage > 1)
    prevBtn:SetAlpha(MM.CurrentPage > 1 and 1 or 0.3)
    nextBtn:SetEnabled(MM.CurrentPage < maxPages)
    nextBtn:SetAlpha(MM.CurrentPage < maxPages and 1 or 0.3)

    local startIndex = (MM.CurrentPage - 1) * pageSize + 1
    for i = 1, pageSize do
        local btn = buttons[i]
        local data = MM.FilteredList[startIndex + i - 1]
        if data then
            btn.mmLabel:SetText(data.name)
            btn:SetScript("OnClick", function() C_MountJournal.SummonByID(data.id) end)
            
            -- Only tint red if it's the wrong faction; uncollected mounts will look normal (desaturated icon only)
            if data.isRestricted then
                btn:SetBackdropColor(0.25, 0.08, 0.08, 1)
                btn:SetBackdropBorderColor(0.5, 0.1, 0.1, 1)
            elseif data.category == 15 then
                btn:SetBackdropColor(0.18, 0.08, 0.28, 1)
                btn:SetBackdropBorderColor(0.4, 0.15, 0.6, 1)
            else
                btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
                btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
            end
            
            local displayID = MM.Use3DModels and C_MountJournal.GetMountInfoExtraByID(data.id) or nil
            if displayID and displayID > 0 then
                btn.mmIcon:Hide()
                btn.mmModel:SetDisplayInfo(displayID)
                btn.mmModel:SetAlpha(data.isCollected and 1 or 0.3)
                btn.mmModel:Show()
            else
                local _, _, icon = C_MountJournal.GetMountInfoByID(data.id)
                btn.mmModel:Hide()
                btn.mmIcon:SetTexture(icon)
                btn.mmIcon:SetDesaturation(data.isCollected and 0 or 1)
                btn.mmIcon:SetAlpha(data.isCollected and 1 or 0.3)
                btn.mmIcon:Show()
            end

            btn:Show()
        else
            btn:Hide()
        end
    end
end

MM.SelectedExpansion = -2
MM:UpdateMountGrid()