local addonName, MM = ...
local L = MM.Locales or {} 

MM.SelectedExpansion = -2 

-- [[ LEFT PANEL LAYOUT ]] --
local separator = MM.LeftContainer:CreateTexture(nil, "OVERLAY")
separator:SetSize(1, 0)
separator:SetPoint("TOPRIGHT", 0, 0)
separator:SetPoint("BOTTOMRIGHT", 0, 0)
separator:SetTexture("Interface\\Buttons\\WHITE8X8")
separator:SetVertexColor(0.15, 0.15, 0.15, 1)

-- Sticky Container Top (All Expansions -2)
local stickyContainer = CreateFrame("Frame", nil, MM.LeftContainer)
stickyContainer:SetPoint("TOPLEFT", 5, -5)
stickyContainer:SetPoint("TOPRIGHT", -5, -5)
stickyContainer:SetHeight(48)

-- Sticky Container Bottom (Global -1)
local bottomContainer = CreateFrame("Frame", nil, MM.LeftContainer)
bottomContainer:SetPoint("BOTTOMLEFT", 5, 5)
bottomContainer:SetPoint("BOTTOMRIGHT", -5, 5)
bottomContainer:SetHeight(48)

local function UpdateScrollIndicators()
    local cur = MM.ExpansionScrollFrame:GetVerticalScroll()
    local max = MM.ExpansionScrollFrame:GetVerticalScrollRange()
    
    if max <= 0 then
        if MM.ExpansionScrollBottom then MM.ExpansionScrollBottom:Hide() end
        if MM.ExpansionScrollTop then MM.ExpansionScrollTop:Hide() end
        return
    end

    local safeCur = math.max(0, math.min(cur, max))
    
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
    local frame = CreateFrame("Frame", "MM_Indicator_" .. (isBottom and "Bottom" or "Top"), parent)
    
    frame:SetSize(324, 30)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1000)
    
    if isBottom then
        frame:SetPoint("BOTTOMLEFT", MM.ExpansionScrollFrame, "BOTTOMLEFT", 0, -2)
    else
        frame:SetPoint("TOPLEFT", MM.ExpansionScrollFrame, "TOPLEFT", 0, 2)
    end

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

    if isBottom then
        tex:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.7), CreateColor(0, 0, 0, 0))
        tex:SetTexCoord(0, 1, 1, 0)
    else
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

MM.ExpansionScrollFrame = CreateFrame("ScrollFrame", "MM_ExpansionScrollFrame", MM.LeftContainer, "BackdropTemplate")
MM.ExpansionScrollFrame:SetPoint("TOPLEFT", stickyContainer, "BOTTOMLEFT", 0, -5)
MM.ExpansionScrollFrame:SetPoint("BOTTOMRIGHT", bottomContainer, "TOPRIGHT", 0, 5)
MM.ExpansionScrollFrame:SetClipsChildren(true)
MM.ExpansionScrollFrame:EnableMouseWheel(true)

local scrollChild = CreateFrame("Frame", nil, MM.ExpansionScrollFrame)
scrollChild:SetSize(324, 1)
MM.ExpansionScrollFrame:SetScrollChild(scrollChild)
MM.ScrollChild = scrollChild

MM.ExpansionScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local curScroll = self:GetVerticalScroll()
    local newScroll = curScroll - (delta * 50)
    local maxScroll = self:GetVerticalScrollRange()
    
    local finalScroll = math.max(0, math.min(newScroll, maxScroll))
    self:SetVerticalScroll(finalScroll)

    UpdateScrollIndicators()
end)

MM.ExpansionScrollBottom = CreateScrollIndicator(true)
MM.ExpansionScrollTop = CreateScrollIndicator(false)

-- [[ REFRESH FUNCTION ]] --
function MM:RefreshExpansionPanel()
    local L_Loc = MM.Locales or L or {}
    local expansions = L_Loc.Expansions or {}

    -- Clear previous frames
    for _, child in ipairs({MM.ScrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, child in ipairs({stickyContainer:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, child in ipairs({bottomContainer:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Separate tracking so scrollChild buttons never anchor to sticky/bottom containers
    local lastScrollButton = nil
    local scrollButtonCount = 0

    local function CreateExpButton(name, id, parent, texturePath)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(320, 48)

        if parent == stickyContainer or parent == bottomContainer then
            -- Position inside sticky frames (Top or Bottom)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        else
            -- Position inside scrollChild
            if not lastScrollButton then
                btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
            else
                btn:SetPoint("TOPLEFT", lastScrollButton, "BOTTOMLEFT", 0, -2)
            end
            lastScrollButton = btn
            scrollButtonCount = scrollButtonCount + 1
        end

        local isActive = (MM.SelectedExpansion == id)
        
        btn:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        btn:SetBackdropColor(0, 0, 0, 0)
        btn:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
        
        btn.Banner = btn:CreateTexture(nil, "BACKGROUND")
        btn.Banner:SetPoint("TOPLEFT", 1, -1)
        btn.Banner:SetPoint("BOTTOMRIGHT", -1, 1)
        btn.Banner:SetTexture(texturePath or "Interface\\EncounterJournal\\UI-EJ-BOSS-Default")
        btn.Banner:SetTexCoord(0, 1, 0, 1)

        btn.Border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        btn.Border:SetPoint("TOPLEFT", 2, -2)
        btn.Border:SetPoint("BOTTOMRIGHT", -2, 2)
        btn.Border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8", 
            edgeSize = 2
        })
        btn.Border:SetBackdropBorderColor(1, 1, 1, 0.15)

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

        -- Stats Calculation
        local owned = 0
        local total = 0
        if MM.FullMountList then
            for _, m in ipairs(MM.FullMountList) do
                local matchExp = (id == -2) or 
                                (id == -1 and (m.expansion == -1 or not m.expansion)) or 
                                (m.expansion == id)

                if matchExp then
                    -- Run centralized filter check
                    if not MM:IsMountFiltered(m) then
                        total = total + 1
                        if m.isCollected then 
                            owned = owned + 1 
                        end
                    end
                end
            end
        end

        btn.Dimmer = btn:CreateTexture(nil, "OVERLAY")
        btn.Dimmer:SetPoint("TOPLEFT", 1, -1)
        btn.Dimmer:SetPoint("BOTTOMRIGHT", -1, 1)
        btn.Dimmer:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        btn.Dimmer:SetVertexColor(0, 0, 0, 0.5)

        if isActive then
            btn.Dimmer:Hide()
            btn:SetBackdropBorderColor(0.7, 0.5, 0, 1)
            btn.Banner:SetAlpha(1.0)
        else
            btn.Dimmer:Show()
            btn:SetBackdropBorderColor(0, 0, 0, 0.3)
            btn.Banner:SetAlpha(1.0)
        end

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
            
            if MM.RefreshCategoryPanel then 
                MM:RefreshCategoryPanel() 
            end
            if MM.UpdateMountGrid then 
                MM:UpdateMountGrid() 
            end
        end)
                
        return btn
    end

    local function GetTextureForID(id)
        if id == -2 then return "Interface\\Addons\\MountMaster\\Media\\ALL_Banner.png" end
        if id == -1 then return "Interface\\Addons\\MountMaster\\Media\\Global_Banner.png" end
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

    -- 1. Sticky Top Button (ALL EXPANSIONS)
    local allTitle = L_Loc.AllExpansions and string.upper(L_Loc.AllExpansions) or "ALL EXPANSIONS"
    CreateExpButton(allTitle, -2, stickyContainer, GetTextureForID(-2))

    -- 2. Scrolling Chronological Expansions (Midnight down to Classic: 11..0)
    local maxExp = 0
    for k in pairs(expansions) do
        if type(k) == "number" and k > maxExp then
            maxExp = k
        end
    end

    for i = maxExp, 0, -1 do
        if expansions[i] then
            CreateExpButton(
                string.upper(expansions[i]),
                i,
                scrollChild,
                GetTextureForID(i)
            )
        end
    end

    -- 3. Sticky Bottom Button (GLOBAL)
    local globalTitle = expansions[-1] and string.upper(expansions[-1]) or "GLOBAL"
    CreateExpButton(globalTitle, -1, bottomContainer, GetTextureForID(-1))

    -- 4. Calculate Scroll Canvas Height (50px per scrollable button)
    local totalHeight = scrollButtonCount * 50
    scrollChild:SetHeight(totalHeight)
    MM.ExpansionScrollFrame:UpdateScrollChildRect()

    UpdateScrollIndicators()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self)
    MM:RefreshExpansionPanel()
    self:UnregisterEvent("PLAYER_LOGIN")
end)