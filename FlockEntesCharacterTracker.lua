local _, FlockEntesCharacterTracker = ...
_G["FlockEntesCharacterTracker"]    = FlockEntesCharacterTracker
local mainFrame                     = CreateFrame("frame", nil, UIParent)

--
-- Imports from other files.
--
local ROWS                          = FlockEntesCharacterTracker.ROWS
local TYPE_DYNAMIC                  = FlockEntesCharacterTracker.CONSTANTS.TYPE_DYNAMIC
local TYPE_INPUT                    = FlockEntesCharacterTracker.CONSTANTS.TYPE_INPUT

--
-- Constants`
--

SLASH_FLOCK1                        = "/flock"

local ADDON_NAME                    = "FlockEntesCharacterTracker"

--
-- Settings
--
local minLevel                      = 90
local debugMode                     = false
local chatPrefix                    = "Flock: "

local offsetX                       = 0
local offsetY                       = 40

local columnWidth                   = 120
local minWidth                      = 350

local fontHeight                    = 20
local fontPath                      = "Interface\\AddOns\\FlockEntesCharacterTracker\\fonts\\SourceSans3-Semibold.ttf"

--
-- State
--

local addonLoaded                   = false
local pendingDelayedUpdate          = 0

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
            if section.type ~= TYPE_INPUT and section.updateCharacterValue then
                data[key] = section.updateCharacterValue(oldValue)
            end
        end
    end

    FlockDB.characters[guid] = data
end

local function scheduleDelayedUpdate(delayInSeconds)
    pendingDelayedUpdate = pendingDelayedUpdate + 1
    local updateToken = pendingDelayedUpdate

    C_Timer.After(delayInSeconds, function()
        if updateToken == pendingDelayedUpdate then
            debug("Delayed update")
            update()
        end
    end)
end

local function numberOfCharacters()
    local count = 0
    for _, _ in pairs(FlockDB.characters) do
        count = count + 1
    end
    return count
end


local function hide()
    mainFrame:Hide()
end

local function renderCell(parent, width, height, relative_to, y_offset, label, justify)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(width, height)
    -- Buttons only create their font string after receiving visible text.
    frame:SetText(label ~= "" and label or " ")
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

local function rowLines(section)
    return (section.type == TYPE_INPUT and section.lines) or 1
end

local function rowHeight(section)
    return fontHeight * rowLines(section)
end

local function frameHeight()
    local height = 30 -- height of the top bar

    for _, section in ipairs(ROWS) do
        height = height + rowHeight(section)
    end

    return height
end


local function renderInputCell(parent, width, height, relative_to, y_offset, section, getValue, onValueChanged)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", relative_to, "TOPLEFT", width * 0.1, y_offset - height * 0.1)
    container:SetPoint("BOTTOMRIGHT", relative_to, "TOPLEFT", width * 0.9, y_offset - height * 0.9)
    container:SetClipsChildren(true)

    local editBox = CreateFrame("EditBox", nil, container)
    editBox.container = container
    editBox:SetAllPoints(container)
    editBox:SetAutoFocus(false)
    editBox:SetMultiLine(rowLines(section) > 1)
    editBox:SetJustifyV(rowLines(section) > 1 and "TOP" or "MIDDLE")
    editBox:SetTextInsets(5, 5, 0, 0)
    editBox:SetText(getValue() or "")

    container.background = container:CreateTexture(nil, "BACKGROUND")
    container.background:SetAllPoints()
    container.background:SetColorTexture(0, 0, 0, 0.35)

    local function createBorder()
        local border = container:CreateTexture(nil, "BORDER")
        border:SetColorTexture(0.2, 0.2, 0.2, 1)
        return border
    end

    container.borderTop = createBorder()
    container.borderTop:SetPoint("TOPLEFT")
    container.borderTop:SetPoint("TOPRIGHT")
    container.borderTop:SetHeight(1)

    container.borderBottom = createBorder()
    container.borderBottom:SetPoint("BOTTOMLEFT")
    container.borderBottom:SetPoint("BOTTOMRIGHT")
    container.borderBottom:SetHeight(1)

    container.borderLeft = createBorder()
    container.borderLeft:SetPoint("TOPLEFT")
    container.borderLeft:SetPoint("BOTTOMLEFT")
    container.borderLeft:SetWidth(1)

    container.borderRight = createBorder()
    container.borderRight:SetPoint("TOPRIGHT")
    container.borderRight:SetPoint("BOTTOMRIGHT")
    container.borderRight:SetWidth(1)

    if fontPath then
        editBox:SetFont(fontPath, 12, "")
    else
        editBox:SetFontObject("GameFontHighlightSmall")
    end

    local function save(self)
        onValueChanged(self:GetText())
    end

    local function setBorderColor(r, g, b)
        container.borderTop:SetColorTexture(r, g, b, 1)
        container.borderBottom:SetColorTexture(r, g, b, 1)
        container.borderLeft:SetColorTexture(r, g, b, 1)
        container.borderRight:SetColorTexture(r, g, b, 1)
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


local function sortedCharacters(characters)
    local sorted = {}

    for guid, data in pairs(characters) do
        table.insert(sorted, {
            guid = guid,
            data = data,
        })
    end

    table.sort(sorted, function(a, b)
        local aItemLevel = a.data.itemLevel
        local bItemLevel = b.data.itemLevel

        if aItemLevel == nil and bItemLevel == nil then
            return a.guid < b.guid
        end

        if aItemLevel == nil then
            return false
        end

        if bItemLevel == nil then
            return true
        end

        if aItemLevel ~= bItemLevel then
            return aItemLevel > bItemLevel
        end

        return a.guid < b.guid
    end)

    return sorted
end

local function renderTable()
    local characters = FlockDB.characters

    mainFrame.characterColumns = mainFrame.characterColumns or {}

    for characterIndex, character in ipairs(sortedCharacters(characters)) do
        local characterGuid = character.guid
        local characterData = character.data
        -- create the frame to which all the fontstrings anchor
        local anchor = mainFrame.characterColumns[characterIndex] or CreateFrame("Button", nil, mainFrame)
        if not mainFrame.characterColumns[characterIndex] then
            mainFrame.characterColumns[characterIndex] = anchor
            anchor:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", columnWidth * characterIndex, -1)
        end
        anchor.guid = characterGuid
        anchor.characterData = characterData
        local height = frameHeight()
        anchor:SetSize(columnWidth, height)

        mainFrame.characterColumns[characterIndex].cell = mainFrame.characterColumns[characterIndex].cell or {}
        local cell = mainFrame.characterColumns[characterIndex].cell

        local rowIndex = 0
        local yOffset = 0
        for _, section in ipairs(ROWS) do
            local key = section.key
            local rowHeight = rowHeight(section)
            if key and section.type == TYPE_INPUT then
                local rowKey = key
                local currentCell = cell[rowIndex] or
                    renderInputCell(anchor, columnWidth, rowHeight, anchor, -yOffset, section,
                        function()
                            return anchor.characterData[rowKey]
                        end,
                        function(value)
                            anchor.characterData[rowKey] = value
                        end)

                if not mainFrame.characterColumns[characterIndex].cell[rowIndex] then
                    mainFrame.characterColumns[characterIndex].cell[rowIndex] = currentCell
                end

                -- Update in case this cell was already created
                currentCell.container:ClearAllPoints()
                currentCell.container:SetPoint("TOPLEFT", anchor, "TOPLEFT", columnWidth * 0.1,
                    -yOffset - rowHeight * 0.1)
                currentCell.container:SetPoint("BOTTOMRIGHT", anchor, "TOPLEFT", columnWidth * 0.9,
                    -yOffset - rowHeight * 0.9)
                currentCell:SetMultiLine(rowLines(section) > 1)
                currentCell:SetJustifyV(rowLines(section) > 1 and "TOP" or "MIDDLE")
                currentCell:SetText(anchor.characterData[rowKey] or "")
            elseif key then -- TYPE_DYNAMIC
                local formattedData = nil
                if characterData[key] then
                    if section.format then
                        formattedData = section.format(characterData[key])
                    else
                        formattedData = tostring(characterData[key])
                    end
                end
                local currentCell = cell[rowIndex] or
                    renderCell(anchor, columnWidth, rowHeight, anchor, -yOffset, formattedData or "",
                        "CENTER")

                if not mainFrame.characterColumns[characterIndex].cell[rowIndex] then
                    mainFrame.characterColumns[characterIndex].cell[rowIndex] = currentCell
                end

                -- Update in case this cell was already created
                currentCell:SetText(formattedData or "")
            end
            rowIndex = rowIndex + 1
            yOffset = yOffset + rowHeight
        end
    end
end

local function show()
    update()
    renderTable()
    mainFrame:Show()
end

local function renderTopBar()
    if not mainFrame.topPanel then
        mainFrame.topPanel = CreateFrame("Frame", "EnteAltManagerTopPanel", mainFrame)
        mainFrame.topPanelTex = mainFrame.topPanel:CreateTexture(nil, "BACKGROUND")
        mainFrame.topPanelTex:SetAllPoints()
        mainFrame.topPanelTex:SetDrawLayer("ARTWORK", -5)
        mainFrame.topPanelTex:SetColorTexture(0, 0, 0, 1)

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

    if not mainFrame.closeButton then
        mainFrame.closeButton = CreateFrame("Button", "CloseButton", mainFrame.topPanel)
        local texture = "Interface\\AddOns\\FlockEntesCharacterTracker\\textures\\Close.tga"
        mainFrame.closeButton:SetSize(16, 16)
        mainFrame.closeButton:SetNormalTexture(texture)
        mainFrame.closeButton:SetPushedTexture(texture)
        mainFrame.closeButton:SetHighlightTexture(texture)
        mainFrame.closeButton:SetScript("OnClick", function() hide() end)
    end

    mainFrame.closeButton:ClearAllPoints()
    mainFrame.closeButton:SetPoint("RIGHT", mainFrame.topPanel, "RIGHT", -8, 0)
    mainFrame.closeButton:SetFrameLevel(mainFrame.topPanel:GetFrameLevel() + 1)

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
    local height = frameHeight()
    firstColumn:SetSize(columnWidth, height)
    firstColumn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 4, -1)

    local yOffset = 0
    for _, section in ipairs(ROWS) do
        local title = section.title
        local rowHeight = rowHeight(section)
        local formattedTitle = title and title ~= "" and title .. ":" or " "
        renderCell(mainFrame, columnWidth, rowHeight, firstColumn, -yOffset, formattedTitle, "RIGHT")
        yOffset = yOffset + rowHeight
    end
end

local function renderFrame()
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame.background = mainFrame:CreateTexture(nil, "BACKGROUND")
    mainFrame.background:SetAllPoints()
    mainFrame.background:SetDrawLayer("ARTWORK", 1)
    mainFrame.background:SetColorTexture(0, 0, 0, 0.75)

    local width = max((numberOfCharacters() + 1) * columnWidth, minWidth)
    local height = frameHeight()
    mainFrame:SetSize(width, height)
    mainFrame.background:SetAllPoints()



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
        elseif event == "PLAYER_ENTERING_WORLD" or
            event == "CHALLENGE_MODE_COMPLETED" or
            event == "CHALLENGE_MODE_COMPLETED_REWARDS" then
            debug("Updating data on event " .. event)
            update()
            scheduleDelayedUpdate(60)
        else
            debug("Updating data on event " .. event)
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
