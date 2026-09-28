-- [[ MountMaster FilterPanel.lua ]] --
local _, MM = ...
local L = MM.Locales

local MainColor = "|cFFDDAA00"
local Reset = "|r"

local filterPanel = CreateFrame("Frame", "MountMasterFilterPanel", MM.RightContainer, "BackdropTemplate")
filterPanel:SetAllPoints(MM.RightContainer)
filterPanel:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1
})
filterPanel:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
filterPanel:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

-- Title / Header for Panel
filterPanel.Title = filterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filterPanel.Title:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 12, -12)
filterPanel.Title:SetText(MainColor .. "Mount Categories" .. Reset)

-- ScrollFrame container for categories
local scrollFrame = CreateFrame("ScrollFrame", nil, filterPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 8, -35)
scrollFrame:SetPoint("BOTTOMRIGHT", filterPanel, "BOTTOMRIGHT", -28, 8)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(210, 1)
scrollFrame:SetScrollChild(content)

MM.CategoryButtons = {}
MM.SelectedCategories = {} -- Key-value map: id = true/false

-- Fetch categories from locales
local categories = MountMasterLocales and MountMasterLocales.enGB and MountMasterLocales.enGB.Categories or {}

-- Initialize all categories as selected by default
for id, _ in pairs(categories) do
    MM.SelectedCategories[id] = true
end

local allBtn = CreateFrame("Button", nil, content)
allBtn:SetSize(204, 26)
allBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)

allBtn.bg = CreateFrame("Frame", nil, allBtn, "BackdropTemplate")
allBtn.bg:SetAllPoints()
allBtn.bg:SetFrameLevel(allBtn:GetFrameLevel() - 1)
allBtn.bg:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1
})

allBtn.text = allBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
allBtn.text:SetPoint("LEFT", allBtn, "LEFT", 10, 0)
allBtn.text:SetText("All Categories")

local function UpdateCategoryButtonVisuals()
    -- Check if all are selected
    local allSelected = true
    for id, _ in pairs(categories) do
        if not MM.SelectedCategories[id] then
            allSelected = false
            break
        end
    end

    if allSelected then
        allBtn.bg:SetBackdropColor(0.25, 0.2, 0.1, 0.9)
        allBtn.bg:SetBackdropBorderColor(0.7, 0.5, 0, 1)
    else
        allBtn.bg:SetBackdropColor(0.12, 0.12, 0.12, 0.8)
        allBtn.bg:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end

    for _, btn in ipairs(MM.CategoryButtons) do
        if MM.SelectedCategories[btn.categoryID] then
            btn.bg:SetBackdropColor(0.25, 0.2, 0.1, 0.9)
            btn.bg:SetBackdropBorderColor(0.7, 0.5, 0, 1)
        else
            btn.bg:SetBackdropColor(0.12, 0.12, 0.12, 0.8)
            btn.bg:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        end
    end
end

allBtn:SetScript("OnClick", function()
    -- Check current state; if all are selected, deselect all. Otherwise, select all.
    local allSelected = true
    for id, _ in pairs(categories) do
        if not MM.SelectedCategories[id] then
            allSelected = false
            break
        end
    end

    local newState = not allSelected
    for id, _ in pairs(categories) do
        MM.SelectedCategories[id] = newState
    end
    
    UpdateCategoryButtonVisuals()
    MM.CurrentPage = 1
    if MM.UpdateMountGrid then
        MM:UpdateMountGrid()
    end
end)

local function OnCategoryClick(self)
    -- Toggle individual category state
    MM.SelectedCategories[self.categoryID] = not MM.SelectedCategories[self.categoryID]
    
    UpdateCategoryButtonVisuals()
    MM.CurrentPage = 1
    if MM.UpdateMountGrid then
        MM:UpdateMountGrid()
    end
end

local yOffset = -30
local buttonHeight = 26
local spacing = 4

for id, name in pairs(categories) do
    local btn = CreateFrame("Button", nil, content)
    btn:SetSize(204, buttonHeight)
    btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    btn.categoryID = id
    
    btn.bg = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    btn.bg:SetAllPoints()
    btn.bg:SetFrameLevel(btn:GetFrameLevel() - 1)
    btn.bg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    btn.bg:SetBackdropColor(0.25, 0.2, 0.1, 0.9)
    btn.bg:SetBackdropBorderColor(0.7, 0.5, 0, 1)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btn.text:SetPoint("LEFT", btn, "LEFT", 10, 0)
    btn.text:SetText(name)
    
    btn:SetScript("OnClick", OnCategoryClick)
    
    table.insert(MM.CategoryButtons, btn)
    yOffset = yOffset - (buttonHeight + spacing)
end

content:SetHeight(math.abs(yOffset) + 10)
UpdateCategoryButtonVisuals()