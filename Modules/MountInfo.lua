MountMasterInfo = {}

function MountMasterInfo:Create(parent)

    local frame = CreateFrame("Frame",nil,parent)

    frame:SetSize(330,550)

    ------------------------------------------------
    -- Border
    ------------------------------------------------

    frame.Border = CreateFrame(
        "Frame",
        nil,
        frame,
        "BackdropTemplate"
    )

    frame.Border:SetAllPoints()

    frame.Border:SetBackdrop({

        edgeFile="Interface\\Buttons\\WHITE8X8",
        edgeSize=1

    })

    ------------------------------------------------
    -- Background
    ------------------------------------------------

    frame.Background = frame:CreateTexture(nil,"BACKGROUND")

    frame.Background:SetAllPoints()

    frame.Background:SetColorTexture(.05,.05,.05,.95)

    ------------------------------------------------
    -- Title
    ------------------------------------------------

    frame.Title = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )

    frame.Title:SetPoint("TOP",0,-15)

    frame.Title:SetText("No Mount Selected")

    ------------------------------------------------
    -- Model
    ------------------------------------------------

    frame.Model = CreateFrame(
        "PlayerModel",
        nil,
        frame
    )

    frame.Model:SetSize(290,290)

    frame.Model:SetPoint("TOP",0,-45)

    ------------------------------------------------
    -- Description
    ------------------------------------------------

    frame.Description = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )

    frame.Description:SetWidth(280)

    frame.Description:SetPoint(
        "TOP",
        frame.Model,
        "BOTTOM",
        0,
        -15
    )

    frame.Description:SetJustifyH("CENTER")

    frame.Description:SetJustifyV("TOP")

    frame.Description:SetWordWrap(true)

    ------------------------------------------------
    -- Difficulty
    ------------------------------------------------

    frame.Difficulty = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )

    frame.Difficulty:SetPoint(
        "TOP",
        frame.Description,
        "BOTTOM",
        0,
        -10
    )

    ------------------------------------------------
    -- Source
    ------------------------------------------------

    frame.Source = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )

    frame.Source:SetWidth(280)

    frame.Source:SetPoint(
        "TOP",
        frame.Difficulty,
        "BOTTOM",
        0,
        -10
    )

    frame.Source:SetWordWrap(true)

    ------------------------------------------------
    -- Button
    ------------------------------------------------

    frame.ActionButton = CreateFrame(
        "Button",
        nil,
        frame,
        "UIPanelButtonTemplate"
    )

    frame.ActionButton:SetSize(150,28)

    frame.ActionButton:SetPoint(
        "BOTTOM",
        0,
        20
    )

    return frame

end