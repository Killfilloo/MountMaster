local addonName, MM = ...

local MainColor = "|cFFDDAA00"
local Reset = "|r"

-- Main Container Frame
local filterPanel = CreateFrame("Frame", "MountMasterFilterPanel", MM.RightContainer, "BackdropTemplate")
filterPanel:SetAllPoints(MM.RightContainer)
filterPanel:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1
})
filterPanel:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
filterPanel:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

-- Title Header
filterPanel.Title = filterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filterPanel.Title:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 12, -12)
filterPanel.Title:SetText(MainColor .. "Mount Categories" .. Reset)

-- Scroll Frame Setup
local scrollFrame = CreateFrame("ScrollFrame", "MM_CategoryScrollFrame", filterPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 8, -35)
scrollFrame:SetPoint("BOTTOMRIGHT", filterPanel, "BOTTOMRIGHT", -28, 8)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(204, 1)
scrollFrame:SetScrollChild(content)

MM.CategoryButtons = {}
MM.SelectedCategories = MM.SelectedCategories or {}

-- Helper to check if all currently visible categories are selected
local function AreAllCategoriesSelected(visibleCategoryIDs)
    if #visibleCategoryIDs == 0 then return false end
    for _, catID in ipairs(visibleCategoryIDs) do
        if not MM.SelectedCategories[catID] then
            return false
        end
    end
    return true
end

-- Refresh and build category buttons based on active expansion mounts
function MM:RefreshCategoryPanel()
    local L_Loc = MM.Locales or {}
    local categories = L_Loc.Categories or {}

    -- FIX 1: Fetch active expansion from state
    local activeExp = MM.SelectedExpansion or -2

    -- 1. Wipe existing buttons from content
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    MM.CategoryButtons = {}

    -- 2. Scan MM.FullMountList to tally categories within active expansion
    local categoryCounts = {} -- [catID] = { total = x, owned = y }
    if MM.FullMountList then
        for _, m in ipairs(MM.FullMountList) do
            local matchExp = (activeExp == -2) or 
                            (activeExp == -1 and (m.expansion == -1 or not m.expansion)) or 
                            (m.expansion == activeExp)

            if matchExp then
                -- Run centralized filter check
                if not MM:IsMountFiltered(m) then
                    local catID = m.category or 0
                    if not categoryCounts[catID] then
                        categoryCounts[catID] = { total = 0, owned = 0 }
                    end
                    categoryCounts[catID].total = categoryCounts[catID].total + 1
                    if m.isCollected then
                        categoryCounts[catID].owned = categoryCounts[catID].owned + 1
                    end
                end
            end
        end
    end

    -- 3. Gather present categories and sort them alphabetically
    local presentCategoryIDs = {}
    for catID, data in pairs(categoryCounts) do
        if data.total > 0 then
            table.insert(presentCategoryIDs, catID)
        end
    end

    table.sort(presentCategoryIDs, function(a, b)
        local nameA = categories[a] or ("Category " .. a)
        local nameB = categories[b] or ("Category " .. b)
        return nameA < nameB
    end)

    -- Ensure default selection state for newly discovered categories
    for _, catID in ipairs(presentCategoryIDs) do
        if MM.SelectedCategories[catID] == nil then
            MM.SelectedCategories[catID] = true
        end
    end

    -- 4. Dynamic Button Creation Helper
    local lastButton = nil
    local totalButtons = 0

    local function CreateCategoryButton(name, catID, owned, total, isAllBtn)
        local btn = CreateFrame("Button", nil, content, "BackdropTemplate")
        btn:SetSize(204, 28)

        if not lastButton then
            btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        else
            btn:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -4)
        end
        lastButton = btn
        totalButtons = totalButtons + 1

        btn.categoryID = catID
        btn.isAllBtn = isAllBtn

        -- Background setup
        btn.bg = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        btn.bg:SetAllPoints()
        btn.bg:SetFrameLevel(btn:GetFrameLevel() - 1)
        btn.bg:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })

        -- Category Label
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btn.text:SetPoint("LEFT", btn, "LEFT", 8, 0)
        btn.text:SetPoint("RIGHT", btn, "RIGHT", -55, 0)
        btn.text:SetJustifyH("LEFT")
        btn.text:SetText(name)

        -- Progress Counter String (e.g. 12 / 45)
        btn.count = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.count:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        btn.count:SetText(owned .. " / " .. total)
        btn.count:SetTextColor(0.5, 0.5, 0.5)

        -- Visual State Function
        btn.UpdateVisual = function()
            local isSelected = false
            if isAllBtn then
                isSelected = AreAllCategoriesSelected(presentCategoryIDs)
            else
                isSelected = MM.SelectedCategories[catID]
            end

            if isSelected then
                btn.bg:SetBackdropColor(0.25, 0.2, 0.1, 0.9)
                btn.bg:SetBackdropBorderColor(0.7, 0.5, 0, 1)
                btn.text:SetTextColor(1, 0.9, 0.5)
            else
                btn.bg:SetBackdropColor(0.12, 0.12, 0.12, 0.8)
                btn.bg:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                btn.text:SetTextColor(0.7, 0.7, 0.7)
            end
        end

        -- Click Handler
        btn:SetScript("OnClick", function()
            if isAllBtn then
                local allSelected = AreAllCategoriesSelected(presentCategoryIDs)
                local newState = not allSelected
                for _, id in ipairs(presentCategoryIDs) do
                    MM.SelectedCategories[id] = newState
                end
            else
                MM.SelectedCategories[catID] = not MM.SelectedCategories[catID]
            end

            -- Refresh visual status of all active buttons
            for _, b in ipairs(MM.CategoryButtons) do
                if b.UpdateVisual then b:UpdateVisual() end
            end

            MM.CurrentPage = 1
            if MM.UpdateMountGrid then
                MM:UpdateMountGrid()
            end
        end)

        btn:UpdateVisual()
        table.insert(MM.CategoryButtons, btn)
        return btn
    end

    -- 5. Calculate "All Categories" Totals & Create Top Button
    local grandTotal = 0
    local grandOwned = 0
    for _, catID in ipairs(presentCategoryIDs) do
        grandTotal = grandTotal + categoryCounts[catID].total
        grandOwned = grandOwned + categoryCounts[catID].owned
    end

    CreateCategoryButton("All Categories", -1, grandOwned, grandTotal, true)

    -- 6. Build Individual Category Buttons
    for _, catID in ipairs(presentCategoryIDs) do
        local catName = categories[catID] or ("Category " .. catID)
        local owned = categoryCounts[catID].owned
        local total = categoryCounts[catID].total
        
        CreateCategoryButton(catName, catID, owned, total, false)
    end

    -- 7. Update Canvas Dimensions
    local totalHeight = (totalButtons * 28) + ((totalButtons - 1) * 4)
    content:SetHeight(math.max(1, totalHeight))
end

-- FIX 2: Defer initial generation to PLAYER_LOGIN so DB is loaded
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self)
    MM:RefreshCategoryPanel()
    self:UnregisterEvent("PLAYER_LOGIN")
end)