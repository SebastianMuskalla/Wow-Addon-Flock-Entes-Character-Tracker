local _, FlockEntesCharacterTracker = ...
_G["FlockEntesCharacterTracker"] = FlockEntesCharacterTracker
local mainFrame = CreateFrame("frame", nil, UIParent)

--
-- Imports from other files.
--
local ROWS         = FlockEntesCharacterTracker.ROWS
local TYPE_DYNAMIC = FlockEntesCharacterTracker.CONSTANTS.TYPE_DYNAMIC
local TYPE_INPUT   = FlockEntesCharacterTracker.CONSTANTS.TYPE_INPUT

--
-- Constants`
--

SLASH_FLOCK1       = "/flock"

local ADDON_NAME   = "FlockEntesCharacterTracker"

--
-- Settings
--
local minLevel     = 90
local debugMode    = false
local chatPrefix   = "Flock: "

local offsetX      = 0
local offsetY      = 40

local columnWidth  = 120
local minWidth     = 350

local fontHeight   = 20
local fontPath     = "Interface\\AddOns\\FlockEntesCharacterTracker\\fonts\\SourceSans3-Semibold.ttf"

--
-- State
--

local addonLoaded  = false

--
-- Helpers
--
local function out(msg)
    if (chatPrefix) then
        DEFAULT_CHAT_FRAME:AddMessage(chatPrefix .. msg)
    else
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end
end

local function debug(msg)
    if debugMode then
        out("[DEBUG] " .. msg)
    end
end

local function update()
    if not addonLoaded then
        return
    end

    local guid = UnitGUID("player")

    if not guid then
        return
    end

    if not FlockDB then
        FlockDB = {}
    end

    if not FlockDB.characters then
        FlockDB.characters = {}
    end

    if UnitLevel("player") < minLevel then
        return
    end

    local data = FlockDB.characters[guid] or {}

    for _, section in ipairs(ROWS) do
        local key = section.key
        if key then
            local oldValue = data[key]
            if section.type ~= "input" and section.updateCharacterValue then
                data[key] = section.updateCharacterValue(oldValue)
            end
        end
    end

    FlockDB.characters[guid] = data
end

local function numberOfCharacters()
    local count = 0
    for _, _ in pairs(FlockDB.characters) do
        count = count + 1
    end
    return count
end

local function renderCell(parent, width, height, relative_to, y_offset, label, justify)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(width, height)
    frame:SetText(label)
    frame:SetPoint("TOPLEFT", relative_to, "TOPLEFT", 0, y_offset)
    local font = frame:GetFontString()
    font:SetJustifyH(justify)
    font:SetJustifyV("MIDDLE")
    frame:SetPushedTextOffset(0, 0)
    font:SetWidth(120)
    font:SetHeight(20)

    if fontPath then
        font:SetFont(fontPath, 12, "")
    else
        font:SetFontObject("GameFontHighlightSmall")
    end

    return frame
end

local function renderInputCell(parent, width, height, relative_to, y_offset, getValue, onValueChanged)
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetSize(width * 0.8, height * 0.8)
    editBox:SetPoint("CENTER", relative_to, "TOPLEFT", width / 2, y_offset - height / 2)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(120)
    editBox:SetTextInsets(5, 5, 0, 0)
    editBox:SetText(getValue() or "")

    editBox.background = editBox:CreateTexture(nil, "BACKGROUND")
    editBox.background:SetAllPoints()
    editBox.background:SetColorTexture(0, 0, 0, 0.35)

    local function createBorder()
        local border = editBox:CreateTexture(nil, "BORDER")
        border:SetColorTexture(0.2, 0.2, 0.2, 1)
        return border
    end

    editBox.borderTop = createBorder()
    editBox.borderTop:SetPoint("TOPLEFT")
    editBox.borderTop:SetPoint("TOPRIGHT")
    editBox.borderTop:SetHeight(1)

    editBox.borderBottom = createBorder()
    editBox.borderBottom:SetPoint("BOTTOMLEFT")
    editBox.borderBottom:SetPoint("BOTTOMRIGHT")
    editBox.borderBottom:SetHeight(1)

    editBox.borderLeft = createBorder()
    editBox.borderLeft:SetPoint("TOPLEFT")
    editBox.borderLeft:SetPoint("BOTTOMLEFT")
    editBox.borderLeft:SetWidth(1)

    editBox.borderRight = createBorder()
    editBox.borderRight:SetPoint("TOPRIGHT")
    editBox.borderRight:SetPoint("BOTTOMRIGHT")
    editBox.borderRight:SetWidth(1)

    if fontPath then
        editBox:SetFont(fontPath, 12, "")
    else
        editBox:SetFontObject("GameFontHighlightSmall")
    end

    local function save(self)
        onValueChanged(self:GetText())
    end

    local function setBorderColor(r, g, b)
        editBox.borderTop:SetColorTexture(r, g, b, 1)
        editBox.borderBottom:SetColorTexture(r, g, b, 1)
        editBox.borderLeft:SetColorTexture(r, g, b, 1)
        editBox.borderRight:SetColorTexture(r, g, b, 1)
    end

    editBox:SetScript("OnEnterPressed", function(self)
        save(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(getValue() or "")
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusGained", function()
        setBorderColor(0.9, 0.9, 0.9)
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        save(self)
        setBorderColor(0.55, 0.55, 0.55)
    end)

    return editBox
end

local function renderTable()
    local characters = FlockDB.characters

    mainFrame.characterColumns = mainFrame.characterColumns or {}

    local characterIndex = 0
    for characterGuid, characterData in pairs(characters) do
        characterIndex = characterIndex + 1
        -- create the frame to which all the fontstrings anchor
        local anchor = mainFrame.characterColumns[characterIndex] or CreateFrame("Button", nil, mainFrame)
        if not mainFrame.characterColumns[characterIndex] then
            mainFrame.characterColumns[characterIndex] = anchor
            mainFrame.characterColumns[characterIndex].guid = characterGuid
            anchor:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", columnWidth * characterIndex, -1)
        end
        local height = #ROWS * fontHeight + 30
        anchor:SetSize(columnWidth, height)

        mainFrame.characterColumns[characterIndex].cell = mainFrame.characterColumns[characterIndex].cell or {}
        local cell = mainFrame.characterColumns[characterIndex].cell

        local rowIndex = 0
        for _, section in ipairs(ROWS) do
            local key = section.key
            if key and section.type == TYPE_INPUT then
                local currentCell = cell[rowIndex] or
                    renderInputCell(anchor, columnWidth, fontHeight, anchor, -rowIndex * fontHeight,
                        function()
                            return characterData[key]
                        end,
                        function(value)
                            characterData[key] = value
                        end)

                if not mainFrame.characterColumns[characterIndex].cell[rowIndex] then
                    mainFrame.characterColumns[characterIndex].cell[rowIndex] = currentCell
                end

                -- Update in case this cell was already created
                currentCell:ClearAllPoints()
                currentCell:SetSize(columnWidth * 0.8, fontHeight * 0.8)
                currentCell:SetPoint("CENTER", anchor, "TOPLEFT", columnWidth / 2,
                    -rowIndex * fontHeight - fontHeight / 2)
                currentCell:SetText(characterData[key] or "")
            elseif key and characterData[key] then -- TYPE_DYNAMIC
                local formattedData = nil
                if section.format then
                    formattedData = section.format(characterData[key])
                else
                    formattedData = tostring(characterData[key])
                end
                if formattedData then
                    local currentCell = cell[rowIndex] or
                        renderCell(anchor, columnWidth, fontHeight, anchor, -rowIndex * fontHeight, formattedData,
                            "CENTER")

                    if not mainFrame.characterColumns[characterIndex].cell[rowIndex] then
                        mainFrame.characterColumns[characterIndex].cell[rowIndex] = currentCell
                    end

                    -- Update in case this cell was already created
                    currentCell:SetText(formattedData)
                end
            end
            rowIndex = rowIndex + 1
        end
    end
end

local function renderTopBar()
    if not mainFrame.topPanel then
        mainFrame.topPanel = CreateFrame("Frame", "EnteAltManagerTopPanel", mainFrame)
        mainFrame.topPanelTex = mainFrame.topPanel:CreateTexture(nil, "BACKGROUND")
        mainFrame.topPanelTex:SetAllPoints()
        mainFrame.topPanelTex:SetDrawLayer("ARTWORK", -5)
        mainFrame.topPanelTex:SetColorTexture(0, 0, 0, 0.7)

        mainFrame.topPanelString = mainFrame.topPanel:CreateFontString("OVERLAY")
        mainFrame.topPanelString:SetFont(fontPath, 22)
        mainFrame.topPanelString:SetTextColor(1, 1, 1, 1)
        mainFrame.topPanelString:SetJustifyH("CENTER")
        mainFrame.topPanelString:SetJustifyV("MIDDLE")
        mainFrame.topPanelString:SetWidth(350)
        mainFrame.topPanelString:SetHeight(20)
        mainFrame.topPanelString:SetText("Flock - Ente's Character Tracker")
        mainFrame.topPanelString:ClearAllPoints()
        mainFrame.topPanelString:SetPoint("CENTER", mainFrame.topPanel, "CENTER", 0, 0)
        mainFrame.topPanelString:Show()
    end

    mainFrame.topPanel:ClearAllPoints()
    mainFrame.topPanel:SetSize(mainFrame:GetWidth(), 30)
    mainFrame.topPanel:SetPoint("BOTTOMLEFT", mainFrame, "TOPLEFT", 0, 0)
    mainFrame.topPanel:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", 0, 0)

    mainFrame:SetMovable(true)
    mainFrame.topPanel:EnableMouse(true)
    mainFrame.topPanel:RegisterForDrag("LeftButton")
    mainFrame.topPanel:SetScript("OnDragStart", function(self, button)
        mainFrame:SetMovable(true)
        mainFrame:StartMoving()
    end)
    mainFrame.topPanel:SetScript("OnDragStop", function(self, button)
        mainFrame:StopMovingOrSizing()
        mainFrame:SetMovable(false)
    end)
end


local function renderFirstColumn()
    local firstColumn = mainFrame.firstColumn or CreateFrame("Button", nil, mainFrame)
    if not firstColumn then mainFrame.firstColumn = firstColumn end
    local height = #ROWS * fontHeight + 30
    firstColumn:SetSize(columnWidth, height)
    firstColumn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 4, -1)

    local rowIndex = 0
    for _, section in ipairs(ROWS) do
        local title = section.title
        local formattedTitle = title and title ~= "" and title .. ":" or " "
        renderCell(mainFrame, columnWidth, fontHeight, firstColumn, -rowIndex * fontHeight, formattedTitle, "RIGHT")
        rowIndex = rowIndex + 1
    end
end

local function hide()
    mainFrame:Hide()
end

local function show()
    update()
    renderTable()
    mainFrame:Show()
end

local function renderFrame()
    local width = max((numberOfCharacters() + 1) * columnWidth, minWidth)
    local height = #ROWS * fontHeight + 30
    mainFrame:SetSize(width, height)
    mainFrame.background:SetAllPoints()

    mainFrame.closeButton = CreateFrame("Button", "CloseButton", mainFrame)
    local texture = "Interface\\AddOns\\FlockEntesCharacterTracker\\textures\\Close.tga"
    mainFrame.closeButton:ClearAllPoints()
    mainFrame.closeButton:SetSize(16, 16)
    mainFrame.closeButton:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -8, 6)
    mainFrame.closeButton:SetNormalTexture(texture)
    mainFrame.closeButton:SetPushedTexture(texture)
    mainFrame.closeButton:SetHighlightTexture(texture)
    mainFrame.closeButton:SetScript("OnClick", function() hide() end)

    renderTopBar()
    renderFirstColumn()
end

local function onLogin()
    update()
    renderFrame()
end

local function onLoad()
    addonLoaded = true
end

function SlashCmdList.FLOCK(cmd, editbox)
    update()
    show()

    if debugMode then
        debug("Dumping database content")
        DevTools_Dump(FlockDB)
    end
end

local function main()
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame.background = mainFrame:CreateTexture(nil, "BACKGROUND")
    mainFrame.background:SetAllPoints()
    mainFrame.background:SetDrawLayer("ARTWORK", 1)
    mainFrame.background:SetColorTexture(0, 0, 0, 0.5)
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    mainFrame:RegisterEvent("ADDON_LOADED")
    mainFrame:RegisterEvent("PLAYER_LOGIN")
    mainFrame:RegisterEvent("QUEST_TURNED_IN")
    mainFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    mainFrame:RegisterEvent("CHAT_MSG_CURRENCY")
    mainFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    mainFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    mainFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED_REWARDS")
    mainFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    mainFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddon = ...
            if loadedAddon == ADDON_NAME then
                onLoad()
            end
        elseif event == "PLAYER_LOGIN" then
            onLogin()
        else
            debug("Updating data on event "..event)
            update()
        end
    end)

    mainFrame:EnableKeyboard(true)
    mainFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            mainFrame:SetPropagateKeyboardInput(false)
        else
            mainFrame:SetPropagateKeyboardInput(true)
        end
    end)
    mainFrame:SetScript("OnKeyUp", function(self, key)
        if key == "ESCAPE" then
            hide()
        end
    end)
    hide()
end

main()
