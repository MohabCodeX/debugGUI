local screenW, screenH = guiGetScreenSize()
local debugGUIVisible = false
local debugMessages = {}

-- Default settings for the debug panel
local DEFAULT_SETTINGS = {
    autoCopyLastMsg = false,      -- Automatically copy new messages to clipboard
    soundAlertsEnabled = false,   -- Play sound effects for different message types
    maxMessages = 100,            -- Maximum number of messages to store in history
    defaultFilterLevel = 5,       -- Default filter level (5 = show all, 1-4 = specific levels)
    panelStateOpen = false,       -- Remember panel state between game sessions
    requiredAdminAccess = true,   -- Restrict debug panel to admins only
    allowDuplicates = true,       -- Show duplicate messages with [DUP] counter
    showWatchPanel = false,       -- Show variable watch panel on startup
    enableWatchPanel = true       -- Enable/disable the watch panel feature entirely
}

-- Important configurable variables
local maxMessages = DEFAULT_SETTINGS.maxMessages        -- Maximum messages in history
local filterLevel = DEFAULT_SETTINGS.defaultFilterLevel -- Current message filter level
local autoCopyLastMsg = DEFAULT_SETTINGS.autoCopyLastMsg    -- Auto-copy setting
local soundAlertsEnabled = DEFAULT_SETTINGS.soundAlertsEnabled  -- Sound alerts setting
local panelStateOpen = DEFAULT_SETTINGS.panelStateOpen        -- Panel state
local requiredAdminAccess = DEFAULT_SETTINGS.requiredAdminAccess  -- Admin restriction
local allowDuplicates = DEFAULT_SETTINGS.allowDuplicates      -- Duplicate handling
local showWatchPanel = DEFAULT_SETTINGS.showWatchPanel        -- Watch panel visibility
local enableWatchPanel = DEFAULT_SETTINGS.enableWatchPanel    -- Watch panel feature toggle

local isAdmin = false
local isCheckingAdmin = false

function checkAdminStatus()
    if not isCheckingAdmin then
        isCheckingAdmin = true
        triggerServerEvent("checkAdminStatus", localPlayer)
    end
    return isAdmin
end

-- Add continuous admin check
addEventHandler("onClientRender", root, function()
    if requiredAdminAccess and debugGUIVisible then
        checkAdminStatus()
    end
end)

addEvent("setAdminStatus", true)
addEventHandler("setAdminStatus", localPlayer, function(status)
    isAdmin = status
    isCheckingAdmin = false

    if debugWindow and guiGetVisible(debugWindow) and requiredAdminAccess and not isAdmin then
        guiSetVisible(debugWindow, false)
        showCursor(false)
        debugGUIVisible = false

        outputChatBox("Debug panel closed: You don't have admin privileges.", 255, 100, 100)
    end
end)

-- Debug message levels and their properties
local DEBUG_LEVELS = {
    ["all"] = { color = "#FFFFFF", level = 5 },    -- Show all messages
    ["info"] = { color = "#FFFFFF", level = 1 },   -- General information messages
    ["warn"] = { color = "#FFA500", level = 2 },   -- Warning messages (orange)
    ["error"] = { color = "#FF0000", level = 3 },  -- Error messages (red)
    ["debug"] = { color = "#00FF00", level = 4 }   -- Debug messages (green)
}

-- Sound effects for different message types
local soundIDs = {
    info = 5,    -- Information message sound
    warn = 4,    -- Warning message sound
    error = 7,   -- Error message sound
    debug = 33   -- Debug message sound
}

-- Panel dimensions (can be adjusted for different screen sizes)
local panelWidth = screenW * 0.4  -- 40% of screen width
local panelHeight = screenH * 0.6 -- 60% of screen height
local panelX = (screenW - panelWidth) / 2  -- Center horizontally
local panelY = (screenH - panelHeight) / 2 -- Center vertically
local scrollOffset = 0

local debugWindow = nil
local debugGrid = nil
local clearBtn = nil
local filterCombo = nil
local copyLastBtn = nil
local copyAllBtn = nil
local autoCopyCheckbox = nil
local soundAlertsCheckbox = nil
local sendMsgBtn = nil
local sendMsgWindow = nil
local msgInputField = nil
local msgTypeRadioGroup = {}

local searchInput = nil

local statsPanel = nil
local statsUpdateTimer = nil

local settingsPanel = nil
local settingsBtn = nil

local exportLogBtn = nil
local exportLogWindow = nil
local exportFileNameInput = nil

local frameCount = 0
local lastFrameTime = getTickCount()
local currentFPS = 0

local watchPanel = nil
local watchList = {}
local watchInputField = nil
local watchListGrid = nil
local watchListGridRows = {}

local infoPanel = nil

function calculateFPS()
    frameCount = frameCount + 1
    local currentTime = getTickCount()
    if currentTime - lastFrameTime >= 1000 then
        currentFPS = frameCount
        frameCount = 0
        lastFrameTime = currentTime
    end
    return currentFPS
end

function createStatsPanel()
    if isElement(statsPanel) then return end

    local statsWidth = 200
    local statsHeight = 100
    local statsX = panelX + panelWidth + 10
    local statsY = panelY

    statsPanel = guiCreateWindow(statsX, statsY, statsWidth, statsHeight, "Performance Stats", false)
    guiWindowSetSizable(statsPanel, false)

    local fpsLabel = guiCreateLabel(10, 25, statsWidth - 20, 20, "FPS: Calculating...", false, statsPanel)
    local memoryLabel = guiCreateLabel(10, 50, statsWidth - 20, 20, "Memory: Calculating...", false, statsPanel)
    guiLabelSetHorizontalAlign(fpsLabel, "left", false)
    guiLabelSetHorizontalAlign(memoryLabel, "left", false)

    statsUpdateTimer = setTimer(function()
        local fps = calculateFPS()
        local memory = math.floor(collectgarbage("count") / 1024) .. " MB"
        guiSetText(fpsLabel, "FPS: " .. tostring(fps))
        guiSetText(memoryLabel, "Memory: " .. tostring(memory))
    end, 1000, 0)

    guiSetVisible(statsPanel, false)
end

addEventHandler("onClientRender", root, function()
    calculateFPS()
end)

function toggleStatsPanel(state)
    if not isElement(statsPanel) then
        createStatsPanel()
    end

    guiSetVisible(statsPanel, state)
end

function destroyStatsPanel()
    if isElement(statsPanel) then
        destroyElement(statsPanel)
        statsPanel = nil
    end

    if isTimer(statsUpdateTimer) then
        killTimer(statsUpdateTimer)
        statsUpdateTimer = nil
    end
end

addEventHandler("onClientResourceStop", resourceRoot, function()
    destroyStatsPanel()
end)

function createInfoPanel()
    if isElement(infoPanel) then return end

    local infoWidth = 400
    local infoHeight = 300
    local infoX = (screenW - infoWidth) / 2
    local infoY = (screenH - infoHeight) / 2

    infoPanel = guiCreateWindow(infoX, infoY, infoWidth, infoHeight, "Variable/Expression Usage Examples", false)
    guiWindowSetSizable(infoPanel, false)

    local examples = {
        "localPlayer.health - Get the player's health",
        "localPlayer.armor - Get the player's armor",
        "localPlayer.money - Get the player's money",
        "getPlayerFromName(\"PlayerName\").health - Get health of a specific player",
        "getElementPosition(localPlayer) - Get the player's position",
        "getElementData(localPlayer, \"customData\") - Get custom data of the player",
        "math.random(1, 100) - Generate a random number between 1 and 100",
        "getTickCount() - Get the current tick count",
        "isPedInVehicle(localPlayer) - Check if the player is in a vehicle",
        "getVehicleName(getPedOccupiedVehicle(localPlayer)) - Get the name of the player's vehicle"
    }

    local exampleList = guiCreateMemo(10, 30, infoWidth - 20, infoHeight - 70, table.concat(examples, "\n"), false,
        infoPanel)
    guiMemoSetReadOnly(exampleList, true)

    local closeBtn = guiCreateButton(10, infoHeight - 30, infoWidth - 20, 25, "Close", false, infoPanel)

    addEventHandler("onClientGUIClick", closeBtn, function()
        if isElement(infoPanel) then
            destroyElement(infoPanel)
            infoPanel = nil
        end
    end, false)
end

function createWatchPanel()
    if isElement(watchPanel) then return end

    local watchWidth = 300
    local watchHeight = 300
    local watchX = panelX + panelWidth + 10
    local watchY = panelY + 110

    watchPanel = guiCreateWindow(watchX, watchY, watchWidth, watchHeight, "Watch Variables", false)
    guiWindowSetSizable(watchPanel, false)

    guiCreateLabel(10, 25, watchWidth - 20, 20, "Enter variable/expression:", false, watchPanel)
    watchInputField = guiCreateEdit(10, 50, watchWidth - 20, 25, "", false, watchPanel)
    guiBringToFront(watchInputField)
    guiSetInputMode("no_binds_when_editing")

    local addBtn = guiCreateButton(10, 85, 80, 25, "Add", false, watchPanel)
    local deleteBtn = guiCreateButton(100, 85, 80, 25, "Delete", false, watchPanel)
    local infoBtn = guiCreateButton(190, 85, 80, 25, "Info", false, watchPanel)

    watchListGrid = guiCreateGridList(10, 120, watchWidth - 20, watchHeight - 150, false, watchPanel)
    guiGridListAddColumn(watchListGrid, "Variable", 0.5)
    guiGridListAddColumn(watchListGrid, "Value", 0.5)

    local function addVariable()
        local expression = guiGetText(watchInputField)
        if expression and expression ~= "" then
            local isValid, result = pcall(loadstring("return " .. expression))
            if isValid then
                table.insert(watchList, { expression = expression, value = result })
                addDebugMessage("Added watch variable: " .. expression, "debug")
                addWatchVariableToGrid(expression, result, true)
                guiSetText(watchInputField, "")
            else
                outputChatBox("Invalid expression: " .. expression, 255, 100, 100)
            end
        end
    end

    addEventHandler("onClientGUIClick", addBtn, addVariable, false)

    addEventHandler("onClientGUIClick", deleteBtn, function()
        local selectedRow = guiGridListGetSelectedItem(watchListGrid)
        if selectedRow ~= -1 then
            local removedVar = guiGridListGetItemText(watchListGrid, selectedRow, 1)
            for i, watch in ipairs(watchList) do
                if watch.expression == removedVar then
                    table.remove(watchList, i)
                    break
                end
            end
            watchListGridRows[removedVar] = nil
            guiGridListRemoveRow(watchListGrid, selectedRow)
            addDebugMessage("Removed watch variable: " .. removedVar, "debug")
        end
    end, false)

    addEventHandler("onClientGUIClick", infoBtn, function()
        createInfoPanel()
    end, false)

    addEventHandler("onClientGUIFocus", watchInputField, function()
        guiSetInputMode("no_binds_when_editing")
    end, false)

    addEventHandler("onClientGUIBlur", watchInputField, function()
        guiSetInputMode("allow_binds")
    end, false)

    addEventHandler("onClientGUIClick", addBtn, addVariable, false)
    addEventHandler("onClientGUIAccepted", watchInputField, addVariable)

    addEventHandler("onClientRender", root, updateWatchList)
    guiSetVisible(watchPanel, false)
end

function addWatchVariableToGrid(expression, value, highlight)
    if watchListGridRows[expression] then return end

    local row = guiGridListAddRow(watchListGrid)
    guiGridListSetItemText(watchListGrid, row, 1, expression, false, false)
    guiGridListSetItemText(watchListGrid, row, 2, tostring(value), false, false)
    watchListGridRows[expression] = row

    if highlight then
        guiGridListSetItemColor(watchListGrid, row, 1, 0, 255, 0, 255)
        guiGridListSetItemColor(watchListGrid, row, 2, 0, 255, 0, 255)
        setTimer(function()
            if isElement(watchListGrid) then
                guiGridListSetItemColor(watchListGrid, row, 1, 255, 255, 255, 255)
                guiGridListSetItemColor(watchListGrid, row, 2, 255, 255, 255, 255)
            end
        end, 2000, 1)
    end
end

function updateWatchList()
    if not isElement(watchListGrid) then return end

    for _, watch in ipairs(watchList) do
        local isValid, result = pcall(loadstring("return " .. watch.expression))
        if isValid then
            if watch.value ~= result then
                addDebugMessage("Watch variable changed: " .. watch.expression .. " = " .. tostring(result), "info")
                watch.value = result
                local row = watchListGridRows[watch.expression]
                if row then
                    guiGridListSetItemText(watchListGrid, row, 2, tostring(result), false, false)
                end
            end
        else
            outputChatBox("Error evaluating: " .. watch.expression, 255, 100, 100)
        end
    end
end

function toggleWatchPanel(state)
    if not enableWatchPanel then
        state = false
    end

    if not isElement(watchPanel) then
        createWatchPanel()
    end

    guiSetVisible(watchPanel, state)
end

function destroyWatchPanel()
    if isElement(watchPanel) then
        destroyElement(watchPanel)
        watchPanel = nil
    end
end

addEventHandler("onClientResourceStop", resourceRoot, function()
    destroyWatchPanel()
end)

function canAccessDebug()
    if not requiredAdminAccess then
        return true
    end

    if not isCheckingAdmin then
        setTimer(checkAdminStatus, 50, 1)
    end

    return isAdmin
end

function toggleDebugGUI(forceState)
    if requiredAdminAccess then
        if not isAdmin then
            if debugGUIVisible and debugWindow then
                debugGUIVisible = false
                guiSetVisible(debugWindow, false)
                showCursor(false)
                toggleStatsPanel(false) -- Ensure stats panel is closed
                toggleWatchPanel(false)
                if isElement(settingsPanel) then
                    guiSetVisible(settingsPanel, false)
                end
                outputChatBox("Debug panel closed: You don't have admin privileges.", 255, 100, 100)
            else
                outputChatBox("You don't have permission to use the debug console.", 255, 0, 0)
            end
            return false
        end
    end

    if forceState ~= nil then
        debugGUIVisible = forceState
    else
        debugGUIVisible = not debugGUIVisible
    end

    if debugWindow then
        guiSetVisible(debugWindow, debugGUIVisible)
        showCursor(debugGUIVisible)
        saveSettings()
    end

    if debugGUIVisible then
        toggleStatsPanel(true)
        toggleWatchPanel(showWatchPanel)
    else
        toggleStatsPanel(false)
        toggleWatchPanel(false)
        if isElement(settingsPanel) then
            guiSetVisible(settingsPanel, false)
        end
    end

    return debugGUIVisible
end

function updateDebugSetting(setting, value)
    if setting == "autoCopyLastMsg" then
        autoCopyLastMsg = value
        saveSettings()
        return true
    elseif setting == "soundAlertsEnabled" then
        soundAlertsEnabled = value
        saveSettings()
        return true
    elseif setting == "maxMessages" then
        maxMessages = value
        saveSettings()
        return true
    elseif setting == "defaultFilterLevel" then
        filterLevel = value
        saveSettings()
        return true
    elseif setting == "panelStateOpen" then
        panelStateOpen = value
        saveSettings()
        return true
    elseif setting == "requiredAdminAccess" then
        requiredAdminAccess = value
        saveSettings()
        return true
    elseif setting == "allowDuplicates" then
        allowDuplicates = value
        saveSettings()
        return true
    elseif setting == "showWatchPanel" then
        showWatchPanel = value
        if debugGUIVisible then
            toggleWatchPanel(value)
        end
        saveSettings()
        return true
    elseif setting == "enableWatchPanel" then
        enableWatchPanel = value
        saveSettings()
        return true
    end
    return false
end

function saveSettings()
    local settings = {
        autoCopyLastMsg = autoCopyLastMsg,
        soundAlertsEnabled = soundAlertsEnabled,
        maxMessages = maxMessages,
        defaultFilterLevel = filterLevel,
        panelStateOpen = debugGUIVisible,
        requiredAdminAccess = requiredAdminAccess,
        allowDuplicates = allowDuplicates,
        showWatchPanel = showWatchPanel,
        enableWatchPanel = enableWatchPanel
    }

    triggerServerEvent("debugGUI:saveSettings", localPlayer, settings)
end

function applySettings(settings)
    if type(settings) ~= "table" then
        return
    end

    if settings.autoCopyLastMsg ~= nil then
        autoCopyLastMsg = settings.autoCopyLastMsg
        if autoCopyCheckbox then
            guiCheckBoxSetSelected(autoCopyCheckbox, autoCopyLastMsg)
        end
    end

    if settings.soundAlertsEnabled ~= nil then
        soundAlertsEnabled = settings.soundAlertsEnabled
        if soundAlertsCheckbox then
            guiCheckBoxSetSelected(soundAlertsCheckbox, soundAlertsEnabled)
        end
    end

    if settings.maxMessages ~= nil and tonumber(settings.maxMessages) then
        maxMessages = tonumber(settings.maxMessages)
    end

    if settings.defaultFilterLevel ~= nil and tonumber(settings.defaultFilterLevel) then
        filterLevel = tonumber(settings.defaultFilterLevel)
        if filterCombo then
            local itemText = "all"
            for level, data in pairs(DEBUG_LEVELS) do
                if data.level == filterLevel then
                    itemText = level
                    break
                end
            end

            for i = 0, guiComboBoxGetItemCount(filterCombo) - 1 do
                if guiComboBoxGetItemText(filterCombo, i) == itemText then
                    guiComboBoxSetSelected(filterCombo, i)
                    break
                end
            end
        end
    end

    if settings.panelStateOpen ~= nil then
        panelStateOpen = settings.panelStateOpen
        if debugWindow then
            toggleDebugGUI(panelStateOpen)
        end
    end

    if settings.requiredAdminAccess ~= nil then
        requiredAdminAccess = settings.requiredAdminAccess
        refreshKeyBindings()
    end

    if settings.allowDuplicates ~= nil then
        allowDuplicates = settings.allowDuplicates
        if isElement(settingsPanel) then
            local allowDuplicatesCheckbox = guiGetElementByText(settingsPanel, "Allow [DUP]")
            if allowDuplicatesCheckbox then
                guiCheckBoxSetSelected(allowDuplicatesCheckbox, allowDuplicates)
            end
        end
    end

    if settings.showWatchPanel ~= nil then
        showWatchPanel = settings.showWatchPanel
        if isElement(settingsPanel) then
            local showWatchPanelCheckbox = guiGetElementByText(settingsPanel, "Show Watch Panel")
            if showWatchPanelCheckbox then
                guiCheckBoxSetSelected(showWatchPanelCheckbox, showWatchPanel)
            end
        end

        if debugGUIVisible then
            toggleWatchPanel(showWatchPanel)
        end
    end

    if settings.enableWatchPanel ~= nil then
        enableWatchPanel = settings.enableWatchPanel
        if not enableWatchPanel then
            showWatchPanel = false
            toggleWatchPanel(false)
        end
        if isElement(settingsPanel) then
            local showWatchPanelCheckbox = guiGetElementByText(settingsPanel, "Show Watch Panel")
            if showWatchPanelCheckbox then
                guiSetEnabled(showWatchPanelCheckbox, enableWatchPanel)
                guiSetAlpha(showWatchPanelCheckbox, enableWatchPanel and 1.0 or 0.5)
            end
        end
    end
end

addEvent("debugGUI:receiveSettings", true)
addEventHandler("debugGUI:receiveSettings", localPlayer, function(settings)
    pcall(function()
        applySettings(settings)
    end)
end)

addEvent("debugGUI:playerLogin", true)
addEventHandler("debugGUI:playerLogin", localPlayer, function()
    isCheckingAdmin = true
    triggerServerEvent("checkAdminStatus", localPlayer)

    setTimer(function()
        if not isAdmin then
            triggerServerEvent("checkAdminStatus", localPlayer)
        end

        triggerServerEvent("debugGUI:requestSettings", localPlayer)
    end, 1000, 1)
end)

local copyLabel = nil
local copyTimer = nil

function showCopiedMessage(messageType)
    local messageText = "Copied!"

    if messageType == "copyLast" then
        messageText = "Last message copied!"
    elseif messageType == "copyAll" then
        messageText = "All messages copied!"
    elseif messageType == "copySelected" then
        messageText = "Selected messages copied!"
    elseif messageType == "noMessage" then
        messageText = "No message to copy!"
    elseif messageType == "autoCopy" then
        messageText = "Auto-copied last message!"
    end

    if isElement(copyLabel) and copyTimer then
        killTimer(copyTimer)
    else
        if debugWindow then
            copyLabel = guiCreateLabel(panelWidth - 170, panelHeight - 28, 160, 20, messageText, false, debugWindow)
            guiSetFont(copyLabel, "clear-normal-bold")
            guiLabelSetColor(copyLabel, 100, 255, 100)
            guiLabelSetHorizontalAlign(copyLabel, "right")
            guiLabelSetVerticalAlign(copyLabel, "center")
        end
    end

    copyTimer = setTimer(function()
        if isElement(copyLabel) then
            destroyElement(copyLabel)
            copyLabel = nil
        end
    end, 1500, 1)
end

function createSendMsgWindow()
    if isElement(sendMsgWindow) then return end

    local miniWindowX = panelX + (panelWidth - 400) / 2
    local miniWindowY = panelY + (panelHeight - 200) / 2

    sendMsgWindow = guiCreateWindow(miniWindowX, miniWindowY, 400, 200, "Send Debug Message", false)
    guiWindowSetSizable(sendMsgWindow, false)

    guiCreateLabel(10, 30, 380, 20, "Message:", false, sendMsgWindow)
    msgInputField = guiCreateEdit(10, 50, 380, 30, "", false, sendMsgWindow)

    guiCreateLabel(10, 90, 380, 20, "Message Type:", false, sendMsgWindow)
    msgTypeRadioGroup.info = guiCreateRadioButton(10, 110, 80, 20, "Info", false, sendMsgWindow)
    msgTypeRadioGroup.warn = guiCreateRadioButton(100, 110, 80, 20, "Warn", false, sendMsgWindow)
    msgTypeRadioGroup.error = guiCreateRadioButton(190, 110, 80, 20, "Error", false, sendMsgWindow)
    msgTypeRadioGroup.debug = guiCreateRadioButton(280, 110, 80, 20, "Debug", false, sendMsgWindow)
    guiRadioButtonSetSelected(msgTypeRadioGroup.info, true)

    local sendBtn = guiCreateButton(10, 150, 180, 30, "Send", false, sendMsgWindow)
    local cancelBtn = guiCreateButton(210, 150, 180, 30, "Cancel", false, sendMsgWindow)

    addEventHandler("onClientGUIClick", sendBtn, function()
        local message = guiGetText(msgInputField)
        local msgType = "info"
        if guiRadioButtonGetSelected(msgTypeRadioGroup.warn) then
            msgType = "warn"
        elseif guiRadioButtonGetSelected(msgTypeRadioGroup.error) then
            msgType = "error"
        elseif guiRadioButtonGetSelected(msgTypeRadioGroup.debug) then
            msgType = "debug"
        end

        if message and message ~= "" then
            addDebugMessage(message, msgType)
        end

        destroyElement(sendMsgWindow)
        sendMsgWindow = nil
        guiSetInputMode("allow_binds")
    end, false)

    addEventHandler("onClientGUIClick", cancelBtn, function()
        destroyElement(sendMsgWindow)
        sendMsgWindow = nil
        guiSetInputMode("allow_binds")
    end, false)


    addEventHandler("onClientGUIFocus", msgInputField, function()
        guiSetInputMode("no_binds_when_editing")
    end, false)

    addEventHandler("onClientGUIBlur", msgInputField, function()
        guiSetInputMode("allow_binds")
    end, false)


    guiBringToFront(msgInputField)
end

addEventHandler("onClientResourceStop", resourceRoot, function()

    guiSetInputMode("allow_binds")
end)

function createExportLogWindow()
    if isElement(exportLogWindow) then
        destroyElement(exportLogWindow)
        exportLogWindow = nil
        guiSetInputMode("allow_binds")
        return
    end

    local windowWidth, windowHeight = 300, 150
    local windowX = (screenW - windowWidth) / 2
    local windowY = (screenH - windowHeight) / 2

    exportLogWindow = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "Export Log", false)
    guiWindowSetSizable(exportLogWindow, false)

    guiCreateLabel(10, 30, windowWidth - 20, 20, "Enter file name:", false, exportLogWindow)
    exportFileNameInput = guiCreateEdit(10, 60, windowWidth - 20, 30, "log.txt", false, exportLogWindow)


    guiBringToFront(exportFileNameInput)
    guiSetInputMode("no_binds_when_editing")
    setTimer(function()
        if isElement(exportFileNameInput) then
            guiEditSetCaretIndex(exportFileNameInput, #guiGetText(exportFileNameInput))
        end
    end, 50, 1)

    local saveBtn = guiCreateButton(10, 100, 130, 30, "Save", false, exportLogWindow)
    local cancelBtn = guiCreateButton(160, 100, 130, 30, "Cancel", false, exportLogWindow)

    addEventHandler("onClientGUIClick", saveBtn, function()
        local fileName = guiGetText(exportFileNameInput)
        if fileName and fileName ~= "" then
            exportLogToFile(fileName)
        else
            outputChatBox("Please enter a valid file name.", 255, 100, 100)
        end
    end, false)

    addEventHandler("onClientGUIClick", cancelBtn, function()
        destroyElement(exportLogWindow)
        exportLogWindow = nil
        guiSetInputMode("allow_binds")
    end, false)


    addEventHandler("onClientGUIFocus", exportFileNameInput, function()
        guiSetInputMode("no_binds_when_editing")
    end, false)

    addEventHandler("onClientGUIBlur", exportFileNameInput, function()
        guiSetInputMode("allow_binds")
    end, false)

    guiBringToFront(exportLogWindow)
end

function exportLogToFile(fileName)
    local filePath = "logs/" .. fileName
    local file = fileCreate(filePath)
    if not file then
        outputChatBox("Failed to create log file.", 255, 100, 100)
        return
    end

    for _, msg in ipairs(debugMessages) do
        local logLine = string.format("[%s] [%s] %s\n", msg.time, msg.level, msg.message)
        fileWrite(file, logLine)
    end

    fileClose(file)
    outputChatBox("Log exported to " .. filePath, 100, 255, 100)

    if isElement(exportLogWindow) then
        destroyElement(exportLogWindow)
        exportLogWindow = nil
        guiSetInputMode("allow_binds")
    end
end

function createDebugGUI()
    panelHeight = screenH * 0.7
    debugWindow = guiCreateWindow(panelX, panelY, panelWidth, panelHeight, "Debug Console    By MohabCodeX", false)
    guiWindowSetSizable(debugWindow, true)

    filterCombo = guiCreateComboBox(10, 25, 120, 100, "all", false, debugWindow)
    guiComboBoxAddItem(filterCombo, "all")
    for level, data in pairs(DEBUG_LEVELS) do
        if level ~= "all" then
            guiComboBoxAddItem(filterCombo, level)
        end
    end

    addEventHandler("onClientGUIComboBoxAccepted", filterCombo, function()
        local selectedItem = guiComboBoxGetSelected(filterCombo)
        if selectedItem ~= -1 then
            local selectedText = guiComboBoxGetItemText(filterCombo, selectedItem)
            for level, data in pairs(DEBUG_LEVELS) do
                if level == selectedText then
                    filterLevel = data.level
                    break
                end
            end
            updateDebugGridList()
        end
    end, false)

    clearBtn = guiCreateButton(140, 25, 80, 25, "Clear", false, debugWindow)
    copyLastBtn = guiCreateButton(230, 25, 120, 25, "Copy Last Msg", false, debugWindow)
    copyAllBtn = guiCreateButton(360, 25, 120, 25, "Copy All Msgs", false, debugWindow)
    sendMsgBtn = guiCreateButton(490, 25, 120, 25, "Send Msg", false, debugWindow)
    settingsBtn = guiCreateButton(panelWidth - 150, 25, 150, 25, "Settings", false, debugWindow)


    searchInput = guiCreateEdit(10, 60, panelWidth - 20, 25, "", false, debugWindow)

    addEventHandler("onClientGUIChanged", searchInput, function()
        local searchText = guiGetText(searchInput):lower()
        updateDebugGridList(searchText)
    end)

    debugGrid = guiCreateGridList(10, 95, panelWidth - 20, panelHeight - 125, false, debugWindow)
    guiGridListSetSelectionMode(debugGrid, 3)
    guiGridListAddColumn(debugGrid, "Time", 0.15)
    guiGridListAddColumn(debugGrid, "Level", 0.1)
    guiGridListAddColumn(debugGrid, "Message", 0.75)

    local tipLabel = guiCreateLabel(160, panelHeight - 28, panelWidth - 170, 20,
        "Tip: Double-click on any message to copy it", false, debugWindow)
    guiSetFont(tipLabel, "clear-small")
    guiLabelSetColor(tipLabel, 180, 180, 255)
    guiLabelSetVerticalAlign(tipLabel, "center")

    exportLogBtn = guiCreateButton(10, panelHeight - 28, 120, 20, "Export Log", false, debugWindow)

    addEventHandler("onClientGUIClick", exportLogBtn, function()
        createExportLogWindow()
    end, false)

    addEventHandler("onClientGUIClick", clearBtn, function()
        debugMessages = {}
        updateDebugGridList()
        triggerServerEvent("debugGUI:clearSavedMessages", localPlayer)
    end, false)

    addEventHandler("onClientGUIClick", copyLastBtn, function()
        local selectedRows = guiGridListGetSelectedItems(debugGrid)

        if #selectedRows > 1 then

            local selectedText = ""
            for _, row in ipairs(selectedRows) do
                local message = guiGridListGetItemText(debugGrid, row.row, 3)
                selectedText = selectedText .. message .. "\n"
            end
            setClipboard(selectedText)
            showCopiedMessage("copySelected")
        else

            if #debugMessages > 0 then
                local lastMessage = debugMessages[#debugMessages].message
                setClipboard(lastMessage)
                showCopiedMessage("copyLast")
            else
                showCopiedMessage("noMessage")
            end
        end
    end, false)

    addEventHandler("onClientGUIClick", copyAllBtn, function()
        if #debugMessages > 0 then
            local allText = ""
            for i, msg in ipairs(debugMessages) do
                allText = allText .. "[" .. msg.time .. "] [" .. msg.level .. "] " .. msg.message .. "\n"
            end
            setClipboard(allText)
            showCopiedMessage("copyAll")
        else
            showCopiedMessage("noMessage")
        end
    end, false)

    addEventHandler("onClientGUIClick", sendMsgBtn, function()
        createSendMsgWindow()
    end, false)

    addEventHandler("onClientGUIClick", settingsBtn, function()
        toggleSettingsPanel()
    end, false)

    addEventHandler("onClientGUIClick", debugGrid, function()
        local selectedRows = guiGridListGetSelectedItems(debugGrid)

        if #selectedRows > 1 then
            guiSetText(copyLastBtn, "Copy Selected Msgs")
        else
            guiSetText(copyLastBtn, "Copy Last Msg")
        end
    end, false)

    addEventHandler("onClientGUIDoubleClick", debugGrid, function()
        local selectedRow = guiGridListGetSelectedItem(debugGrid)
        if selectedRow ~= -1 then
            local displayMessage = guiGridListGetItemText(debugGrid, selectedRow, 3)
            local message = displayMessage
            local dupPos = string.find(displayMessage, " %[DUP x")
            if dupPos then
                message = string.sub(displayMessage, 1, dupPos - 1)
            end
            if message and message ~= "" then
                setClipboard(message)
                showCopiedMessage()
            end
        end
    end, false)

    guiSetVisible(debugWindow, false)
end

function toggleSettingsPanel()
    if isElement(settingsPanel) then
        local isVisible = guiGetVisible(settingsPanel)
        if not isVisible then

            local settingsWidth = 200
            local settingsHeight = 150
            local settingsX = panelX + panelWidth - settingsWidth - 10
            local settingsY = panelY + 60
            guiSetPosition(settingsPanel, settingsX, settingsY, false)
            guiBringToFront(settingsPanel)
        end
        guiSetVisible(settingsPanel, not isVisible)
        return
    end

    local settingsWidth = 200
    local settingsHeight = 150
    local settingsX = panelX + panelWidth - settingsWidth - 10
    local settingsY = panelY + 60

    settingsPanel = guiCreateWindow(settingsX, settingsY, settingsWidth, settingsHeight, "Settings", false)
    guiWindowSetSizable(settingsPanel, false)

    autoCopyCheckbox = guiCreateCheckBox(10, 25, settingsWidth - 20, 20, "Auto-copy last", autoCopyLastMsg, false,
        settingsPanel)
    soundAlertsCheckbox = guiCreateCheckBox(10, 50, settingsWidth - 20, 20, "Sound Alerts", soundAlertsEnabled, false,
        settingsPanel)
    local allowDuplicatesCheckbox = guiCreateCheckBox(10, 75, settingsWidth - 20, 20, "Allow [DUP]", allowDuplicates,
        false, settingsPanel)
    local showWatchPanelCheckbox = guiCreateCheckBox(10, 100, settingsWidth - 20, 20, "Show Watch Panel", showWatchPanel,
        false, settingsPanel)

    guiSetEnabled(showWatchPanelCheckbox, enableWatchPanel)

    if not enableWatchPanel then
        guiSetAlpha(showWatchPanelCheckbox, 0.5)
        showWatchPanel = false
        toggleWatchPanel(false)
    end

    addEventHandler("onClientGUIClick", autoCopyCheckbox, function()
        autoCopyLastMsg = guiCheckBoxGetSelected(autoCopyCheckbox)
        saveSettings()
    end, false)

    addEventHandler("onClientGUIClick", soundAlertsCheckbox, function()
        soundAlertsEnabled = guiCheckBoxGetSelected(soundAlertsCheckbox)
        saveSettings()
        if soundAlertsEnabled then
            setTimer(function()
                playSoundFrontEnd(soundIDs.info)
            end, 100, 1)
        end
    end, false)

    addEventHandler("onClientGUIClick", allowDuplicatesCheckbox, function()
        allowDuplicates = guiCheckBoxGetSelected(allowDuplicatesCheckbox)
        saveSettings()
    end, false)

    addEventHandler("onClientGUIClick", showWatchPanelCheckbox, function()
        if not enableWatchPanel then return end
        showWatchPanel = guiCheckBoxGetSelected(showWatchPanelCheckbox)
        toggleWatchPanel(showWatchPanel)
        saveSettings()
    end, false)

    guiBringToFront(settingsPanel)
end

local lastSaveTime = 0
local _inSaveOperation = false

function addDebugMessage(message, level)
    level = level or "info"
    if not DEBUG_LEVELS[level] then level = "info" end

    local time = string.format("%02d:%02d:%02d",
        getRealTime().hour,
        getRealTime().minute,
        getRealTime().second)

    local isDuplicate = false
    if allowDuplicates and #debugMessages > 0 then
        local lastMsg = debugMessages[#debugMessages]
        if lastMsg.message == message and lastMsg.level == level then
            if lastMsg.duplicates then
                lastMsg.duplicates = lastMsg.duplicates + 1
                lastMsg.displayMessage = message .. " [DUP x" .. lastMsg.duplicates .. "]"
                isDuplicate = true
            else
                lastMsg.duplicates = 2
                lastMsg.displayMessage = message .. " [DUP x2]"
                isDuplicate = true
            end
            lastMsg.time = time
            if soundAlertsEnabled and not _inDebugMessage then
                setTimer(function()
                    playSound(level)
                end, 50, 1)
            end
            if autoCopyLastMsg then
                setClipboard(lastMsg.displayMessage)
                showCopiedMessage("autoCopy")
            end
            updateDebugGridList()
            return
        end
    end

    if not isDuplicate then
        table.insert(debugMessages, {
            time = time,
            level = level,
            message = message,
            displayMessage = message,
            color = DEBUG_LEVELS[level].color,
            duplicates = 1
        })

        if #debugMessages > maxMessages then
            table.remove(debugMessages, 1)
        end

        if autoCopyLastMsg then
            setClipboard(message)
            showCopiedMessage("autoCopy")
        end

        if soundAlertsEnabled and not _inDebugMessage then
            setTimer(function()
                playSound(level)
            end, 50, 1)
        end
    end

    updateDebugGridList()

    setTimer(function()
        if not _inSaveOperation then
            saveDebugMessages(true)
        end
    end, 100, 1)
end

function updateDebugGridList(searchText)
    if not debugGrid then return end

    guiGridListClear(debugGrid)

    local longestTextLength = 0 -- Track the longest text length

    for _, msg in ipairs(debugMessages) do
        local debugLevel = DEBUG_LEVELS[msg.level].level

        if (filterLevel == 5 or filterLevel == debugLevel) and
            (not searchText or msg.message:lower():find(searchText, 1, true)) then
            local row = guiGridListAddRow(debugGrid)
            guiGridListSetItemText(debugGrid, row, 1, msg.time, false, false)
            guiGridListSetItemText(debugGrid, row, 2, msg.level, false, false)
            guiGridListSetItemText(debugGrid, row, 3, msg.displayMessage, false, false)

            longestTextLength = math.max(longestTextLength, #msg.displayMessage)

            local r, g, b = hexToRGB(msg.color)
            for col = 1, 3 do
                guiGridListSetItemColor(debugGrid, row, col, r * 255, g * 255, b * 255, 255)
            end
        end
    end

    -- Dynamically adjust the third column width based on the longest text
    local charWidth = 8 -- Approximate width of a character in pixels
    local minWidth = 200 -- Minimum width for the message column
    local newWidth = math.max(minWidth, math.min(longestTextLength * charWidth, panelWidth - 50))
    guiGridListSetColumnWidth(debugGrid, 3, newWidth, false)

    setTimer(function()
        guiGridListSetVerticalScrollPosition(debugGrid, 100)
    end, 5, 1)
end

function hexToRGB(hex)
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2)) or 255
    local g = tonumber("0x" .. hex:sub(3, 4)) or 255
    local b = tonumber("0x" .. hex:sub(5, 6)) or 255
    return r / 255, g / 255, b / 255
end

addEvent("onServerDebugMessage", true)
addEventHandler("onServerDebugMessage", root, function(message, level)
    addDebugMessage(tostring(message), level or "info")
end)


local originalOutputDebugString = outputDebugString
local _inDebugMessage = false

_G.outputDebugString = function(text, level, r, g, b)
    if _inDebugMessage then
        return originalOutputDebugString(text, level, r, g, b)
    end

    _inDebugMessage = true
    originalOutputDebugString(text, level, r, g, b)

    local debugLevel = "info"
    if level == 1 then
        debugLevel = "error"
    elseif level == 2 then
        debugLevel = "warn"
    elseif level == 3 then
        debugLevel = "debug"
    end


    addDebugMessage(tostring(text), debugLevel)
    _inDebugMessage = false
end

function playSound(soundType)
    if _inDebugMessage then
        return false
    end

    local soundID = soundIDs[soundType] or soundIDs.info

    pcall(function()
        playSoundFrontEnd(soundID)
    end)

    return true
end

function saveDebugMessages(immediate)
    if #debugMessages == 0 then
        return false
    end

    if _inSaveOperation then
        return false
    end
    _inSaveOperation = true

    if not immediate then
        local currentTime = getTickCount()
        if (currentTime - lastSaveTime) < 5000 then
            _inSaveOperation = false
            return false
        end
        lastSaveTime = currentTime
    end

    local messagesToSave = {}
    for i, msg in ipairs(debugMessages) do
        if not string.find(tostring(msg.message), "Debug commands loaded") then
            table.insert(messagesToSave, {
                time = msg.time,
                level = msg.level,
                message = msg.message,
                displayMessage = msg.displayMessage,
                color = msg.color,
                duplicates = msg.duplicates
            })
        end
    end

    if #messagesToSave > 0 then
        triggerServerEvent("debugGUI:saveMessages", localPlayer, messagesToSave, immediate)
        setTimer(function() _inSaveOperation = false end, 500, 1)
        return true
    end

    _inSaveOperation = false
    return false
end

function loadDebugMessages(savedMessages)
    if type(savedMessages) ~= "table" then
        return false
    end

    debugMessages = {}

    for _, msg in ipairs(savedMessages) do
        table.insert(debugMessages, {
            time = msg.time or os.date("%H:%M:%S"),
            level = msg.level or "info",
            message = msg.message or "",
            displayMessage = msg.displayMessage or msg.message or "",
            color = msg.color or DEBUG_LEVELS[msg.level or "info"].color,
            duplicates = tonumber(msg.duplicates) or 1
        })
    end

    if #debugMessages > 0 then
        updateDebugGridList()
        return true
    end

    return false
end

addEvent("debugGUI:receiveSavedMessages", true)
addEventHandler("debugGUI:receiveSavedMessages", localPlayer, function(messagesData)
    local messages = messagesData
    local isPriority = false

    if type(messagesData) == "table" and messagesData.messages then
        messages = messagesData.messages
        isPriority = messagesData.priority
    end

    if isPriority then
        loadDebugMessages(messages)
    else
        pcall(function()
            loadDebugMessages(messages)
        end)
    end
end)


addEventHandler("onClientResourceStart", resourceRoot, function()
    checkAdminStatus()

    addEvent("debugGUI:playerLogout", true)
    addEventHandler("debugGUI:playerLogout", localPlayer, function()
        isAdmin = false

        if debugWindow and isElement(debugWindow) then
            showCursor(false)
            guiSetVisible(debugWindow, false)
            debugGUIVisible = false

            -- Ensure stats panel is closed
            toggleStatsPanel(false)
            toggleWatchPanel(false)
            if isElement(settingsPanel) then
                guiSetVisible(settingsPanel, false)
            end

            showCursor(false, false)

            outputChatBox("Debug panel closed: You've logged out and no longer have admin privileges.", 255, 100, 100)

            panelStateOpen = false
            saveSettings()

            setTimer(function()
                if isElement(debugWindow) and guiGetVisible(debugWindow) then
                    guiSetVisible(debugWindow, false)
                    showCursor(false)
                    toggleStatsPanel(false) -- Double check stats panel is closed
                    outputChatBox("Debug panel forcibly closed after logout", 255, 100, 100)
                end
            end, 500, 1)
        end
    end)

    createDebugGUI()
    createStatsPanel()
    createWatchPanel()

    addEventHandler("onClientDebugMessage", root, function(message, level, file, line)
        local debugLevel = "info"
        if level == 1 then
            debugLevel = "error"
        elseif level == 2 then
            debugLevel = "warn"
        elseif level == 3 then
            debugLevel = "debug"
        end

        local formattedMessage = message
        if file and line then
            formattedMessage = file .. ":" .. line .. " - " .. message
        end

        addDebugMessage(formattedMessage, debugLevel)
    end)

    triggerServerEvent("debugGUI:requestSettings", localPlayer)
    triggerServerEvent("debugGUI:requestSavedMessages", localPlayer)

    setTimer(function()
        if #debugMessages == 0 then
            triggerServerEvent("debugGUI:requestSavedMessages", localPlayer)
        end
    end, 1000, 1)

    unbindKey("F6", "down", onF6KeyPress)
    bindKey("F6", "down", onF6KeyPress)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    saveDebugMessages()
    if debugGUIVisible then
        showCursor(false)
    end
    unbindKey("F6", "down", onF6KeyPress)
    toggleStatsPanel(false) -- Ensure stats panel is closed
    destroyStatsPanel() -- Clean up stats panel
end)

function clientDebugOutput(message, level)
    level = level or "info"
    if not DEBUG_LEVELS[level] then level = "info" end

    addDebugMessage(message, level)
    return true
end

function onF6KeyPress()
    if requiredAdminAccess and not isAdmin then
        outputChatBox("You don't have permission to use the debug console.", 255, 0, 0)

        triggerServerEvent("checkAdminStatus", localPlayer)

        return false
    end

    return toggleDebugGUI()
end

function refreshKeyBindings()
    unbindKey("F6", "down", onF6KeyPress)
    bindKey("F6", "down", onF6KeyPress)
end

function getDebugLevels()
    return DEBUG_LEVELS
end

function getDebugSounds()
    return soundIDs
end

function getDebugSettings()
    return {
        autoCopyLastMsg = autoCopyLastMsg,
        soundAlertsEnabled = soundAlertsEnabled,
        maxMessages = maxMessages,
        defaultFilterLevel = filterLevel,
        requiredAdminAccess = requiredAdminAccess,
        allowDuplicates = allowDuplicates,
        showWatchPanel = showWatchPanel,
        enableWatchPanel = enableWatchPanel
    }
end
