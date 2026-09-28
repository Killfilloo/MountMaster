local addonName, _ = ... 
local MM = _G[addonName] 
local L = MM.Locales

MM.SelectedExpansion = -2 

-- [[ LEFT PANEL LAYOUT ]] --
local separator = MM.LeftContainer:CreateTexture(nil, "OVERLAY")
separator:SetSize(1, 0)
separator:SetPoint("TOPRIGHT", 0, 0)
separator:SetPoint("BOTTOMRIGHT", 0, 0)
separator:SetTexture("Interface\\Buttons\\WHITE8X8")
separator:SetVertexColor(0.15, 0.15, 0.15, 1)

local stickyContainer = CreateFrame("Frame", nil, MM.LeftContainer)
stickyContainer:SetPoint("TOPLEFT", 5, -5)
stickyContainer:SetPoint("TOPRIGHT", -5, -5)
stickyContainer:SetHeight(48)

local function UpdateScrollIndicators()
    local cur = MM.ExpansionScrollFrame:GetVerticalScroll()
    local max = MM.ExpansionScrollFrame:GetVerticalScrollRange()
    
    if max <= 0 then
        if MM.ExpansionScrollBottom then MM.ExpansionScrollBottom:Hide() end
        if MM.ExpansionScrollTop then MM.ExpansionScrollTop:Hide() end
        return
    end

    local safeCur = math.max(0, math.min(cur, max))
    
    -- Adjusted thresholds to handle smaller scroll ranges gracefully
    local showTop = (safeCur > 5)
    local showBottom = (safeCur < (max - 5))
    
    if MM.ExpansionScrollBottom then
        MM.ExpansionScrollBottom:SetShown(showBottom)
    end
    if MM.ExpansionScrollTop then
        MM.ExpansionScrollTop:SetShown(showTop)
    end
end

-- [[ EXPANSION LIST SCROLL INDICATORS ]] --
local function CreateScrollIndicator(isBottom)
    local parent = MM.LeftContainer
    -- Fix the name generation so it doesn't concatenate a boolean directly to a string poorly
    local frame = CreateFrame("Frame", "MM_Indicator_" .. (isBottom and "Bottom" or "Top"), parent)
    
    frame:SetSize(324, 30)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1000)
    
if isBottom then
        frame:SetPoint("BOTTOMLEFT", MM.ExpansionScrollFrame, "BOTTOMLEFT", 0, -2)
    else
        -- Anchor to the top of the ScrollFrame instead of the parent container
        frame:SetPoint("TOPLEFT", MM.ExpansionScrollFrame, "TOPLEFT", 0, 2)
    end

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

    if isBottom then
        -- Bottom indicator: Fades from yellow/orange (0.7, 0.4, 0, 0.9) down to transparent
        tex:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.7), CreateColor(0, 0, 0, 0))
        tex:SetTexCoord(0, 1, 1, 0)
    else
        -- Top indicator: Fades from yellow/orange down to transparent
        tex:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0.7))
    end
    
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", 0, isBottom and 5 or -5)
    text:SetText(isBottom and "SCROLL DOWN" or "SCROLL UP")
    text:SetTextColor(1, 1, 1)
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 1)

    frame:Hide()
    return frame
end

-- 2. Define the scroll frame
MM.ExpansionScrollFrame = CreateFrame("ScrollFrame", "MM_ExpansionScrollFrame", MM.LeftContainer, "BackdropTemplate")
MM.ExpansionScrollFrame:SetPoint("TOPLEFT", stickyContainer, "BOTTOMLEFT", 0, -5)
MM.ExpansionScrollFrame:SetPoint("BOTTOMRIGHT", -5, 5)
MM.ExpansionScrollFrame:SetClipsChildren(true)
MM.ExpansionScrollFrame:EnableMouseWheel(true)

local scrollChild = CreateFrame("Frame", nil, MM.ExpansionScrollFrame)
scrollChild:SetSize(324, 1)
MM.ExpansionScrollFrame:SetScrollChild(scrollChild)
MM.ScrollChild = scrollChild

-- Set the Script on the SAME ScrollFrame
MM.ExpansionScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local curScroll = self:GetVerticalScroll()
    local newScroll = curScroll - (delta * 50)
    local maxScroll = self:GetVerticalScrollRange()
    
    -- Clamp it immediately so it never goes below 0 or above maxScroll
    local finalScroll = math.max(0, math.min(newScroll, maxScroll))
    self:SetVerticalScroll(finalScroll)

    UpdateScrollIndicators()
end)

-- Store them in the MM table so they are accessible anywhere
MM.ExpansionScrollBottom = CreateScrollIndicator(true)   -- true means bottom
MM.ExpansionScrollTop = CreateScrollIndicator(false)  -- false means top

-- [[ REFRESH FUNCTION ]] --
function MM:RefreshExpansionPanel()
    for _, child in ipairs({MM.ScrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, child in ipairs({stickyContainer:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = 0

    local function CreateExpButton(name, id, parent, yPos, texturePath)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(320, 48)
        if parent == stickyContainer then
            btn:SetPoint("TOPLEFT", 0, 0)
        else
            btn:SetPoint("TOPLEFT", 0, yPos)
        end

        local isActive = (MM.SelectedExpansion == id)
        
        btn:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        btn:SetBackdropColor(0, 0, 0, 0)
        btn:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
        
        -- 1. Banner Art
        btn.Banner = btn:CreateTexture(nil, "BACKGROUND")
        btn.Banner:SetPoint("TOPLEFT", 1, -1)
        btn.Banner:SetPoint("BOTTOMRIGHT", -1, 1)
        btn.Banner:SetTexture(texturePath or "Interface\\EncounterJournal\\UI-EJ-BOSS-Default")
        -- Ensure the texture scales correctly
        btn.Banner:SetTexCoord(0, 1, 0, 1)

        btn.Border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        btn.Border:SetPoint("TOPLEFT", 2, -2)
        btn.Border:SetPoint("BOTTOMRIGHT", -2, 2)
        btn.Border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8", 
            edgeSize = 2 -- This creates your 2px border width
        })
        btn.Border:SetBackdropBorderColor(1, 1, 1, 0.15) -- White, low alpha border

        -- 2. Dual Fade (Left & Right)
        local fadeAlpha = 0.95
        
        btn.FadeL = btn:CreateTexture(nil, "OVERLAY")
        btn.FadeL:SetSize(50, 48)
        btn.FadeL:SetPoint("LEFT", btn, "LEFT", 0, 0)
        btn.FadeL:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        btn.FadeL:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, fadeAlpha), CreateColor(0, 0, 0, 0))
        
        btn.FadeR = btn:CreateTexture(nil, "OVERLAY")
        btn.FadeR:SetSize(50, 48)
        btn.FadeR:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
        btn.FadeR:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        btn.FadeR:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, fadeAlpha))

        -- 3. Stats Calculation
        local owned = 0
        local total = 0
        for _, m in ipairs(MM.FullMountList) do
            if id == -1 or m.expansion == id then
                -- Only count mounts the player can use/access
                if not m.isRestricted and not (MM.filterUnobtainable and m.category == 15) then
                    total = total + 1
                    if m.isCollected then owned = owned + 1 end
                end
            end
        end

        -- Inside your expansion button creation:
        btn.Dimmer = btn:CreateTexture(nil, "OVERLAY")
        btn.Dimmer:SetPoint("TOPLEFT", 1, -1)
        btn.Dimmer:SetPoint("BOTTOMRIGHT", -1, 1)
        btn.Dimmer:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        btn.Dimmer:SetVertexColor(0, 0, 0, 0.5) -- Darkens banner for non-selected

        -- Update logic
        if isActive then
            btn.Dimmer:Hide() -- Selected is full brightness
            btn:SetBackdropBorderColor(0.7, 0.5, 0, 1)
            btn.Banner:SetAlpha(1.0)
        else
            btn.Dimmer:Show() -- Inactive is darkened
            btn:SetBackdropBorderColor(0, 0, 0, 0.3)
            btn.Banner:SetAlpha(1.0) -- Keep banner alpha at 1.0; let Dimmer do the work
        end

        -- 5. Typography
        btn.Name = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btn.Name:SetPoint("LEFT", 10, 5)
        btn.Name:SetText(name)
        if isActive then btn.Name:SetTextColor(1, 0.9, 0.5) end

        btn.SubText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.SubText:SetPoint("LEFT", 10, -8)
        btn.SubText:SetText(owned .. " / " .. total)
        btn.SubText:SetTextColor(0.5, 0.5, 0.5)

        btn:SetScript("OnClick", function()
            MM.SelectedExpansion = id
            MM.CurrentPage = 1
            MM:RefreshExpansionPanel()
            if MM.UpdateMountGrid then MM:UpdateMountGrid() end
        end)
        
        return btn
    end

    local function GetTextureForID(id)
        if id == -1 then return "Interface\\Addons\\MountMaster\\Media\\ALL_Banner.png" end
        if id == 0 then return "Interface\\Addons\\MountMaster\\Media\\Classic_Banner.png" end
        if id == 1 then return "Interface\\Addons\\MountMaster\\Media\\TBC_Banner.png" end
        if id == 2 then return "Interface\\Addons\\MountMaster\\Media\\WOTLK_Banner.png" end
        if id == 3 then return "Interface\\Addons\\MountMaster\\Media\\CATA_Banner.png" end
        if id == 4 then return "Interface\\Addons\\MountMaster\\Media\\MOP_Banner.png" end
        if id == 5 then return "Interface\\Addons\\MountMaster\\Media\\WOD_Banner.png" end
        if id == 6 then return "Interface\\Addons\\MountMaster\\Media\\Legion_Banner.png" end
        if id == 7 then return "Interface\\Addons\\MountMaster\\Media\\BFA_Banner.png" end
        if id == 8 then return "Interface\\Addons\\MountMaster\\Media\\SL2_Banner.png" end
        if id == 9 then return "Interface\\Addons\\MountMaster\\Media\\DF_Banner.png" end
        if id == 10 then return "Interface\\Addons\\MountMaster\\Media\\TWW_Banner.png" end
        if id == 11 then return "Interface\\Addons\\MountMaster\\Media\\Midnight_Banner.png" end
        return nil
    end

    CreateExpButton("ALL EXPANSIONS", -1, stickyContainer, 0, GetTextureForID(-1))

    local yOffset = 0
    local maxExp = 0
    for k in pairs(L.Expansions) do if type(k) == "number" and k > maxExp then maxExp = k end end

    for i = maxExp, 0, -1 do
        if L.Expansions[i] then
            CreateExpButton(string.upper(L.Expansions[i]), i, scrollChild, yOffset, GetTextureForID(i))
            yOffset = yOffset - 50
        end
    end

    local totalHeight = math.abs(yOffset)

    --scrollChild:SetHeight(math.abs(yOffset))
    scrollChild:SetSize(324, totalHeight)
    MM.ExpansionScrollFrame:UpdateScrollChildRect()

    UpdateScrollIndicators()
end

MM:RefreshExpansionPanel()