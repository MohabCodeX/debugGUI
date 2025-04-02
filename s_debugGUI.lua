local DEBUG_LEVELS = {
    ["info"] = { color = "#FFFFFF", level = 1 },
    ["warn"] = { color = "#FFA500", level = 2 },
    ["error"] = { color = "#FF0000", level = 3 },
    ["debug"] = { color = "#00FF00", level = 4 }
}

local _inServerDebugMessage = false
local _inServerSaveOperation = false

addEventHandler("onResourceStart", resourceRoot, function()
    addEventHandler("onDebugMessage", root, function(message, level, file, line, r, g, b)
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

        triggerClientEvent("onServerDebugMessage", root, formattedMessage, debugLevel)
    end)
end)

local originalOutputDebugString = outputDebugString
_G.outputDebugString = function(text, level, r, g, b)
    if _inServerDebugMessage then
        return originalOutputDebugString(text, level, r, g, b)
    end

    _inServerDebugMessage = true
    originalOutputDebugString(text, level, r, g, b)

    local debugLevel = "info"
    if level == 1 then
        debugLevel = "error"
    elseif level == 2 then
        debugLevel = "warn"
    elseif level == 3 then
        debugLevel = "debug"
    end

    triggerClientEvent("onServerDebugMessage", root, tostring(text), debugLevel)
    _inServerDebugMessage = false
end

function exportDebugOutput(message, level, target)
    level = level or "info"
    if not DEBUG_LEVELS[level] then level = "info" end

    if target then
        triggerClientEvent(target, "onServerDebugMessage", target, message, level)
    else
        triggerClientEvent("onServerDebugMessage", root, message, level)
    end

    return true
end

addEvent("checkAdminStatus", true)
addEventHandler("checkAdminStatus", root, function()
    local player = client
    local account = getPlayerAccount(player)
    local isAdmin = false

    if account and not isGuestAccount(account) then
        local accountName = getAccountName(account)
        if isObjectInACLGroup("user." .. accountName, aclGetGroup("Admin")) then
            isAdmin = true
        end
    end

    triggerClientEvent(player, "setAdminStatus", player, isAdmin)
end)

local savedMessagesFile = "savedMessages.xml"
local savedMessages = {}

function saveMessagesToXML(messages)
    if not messages or type(messages) ~= "table" then
        messages = {}
    end

    if fileExists(savedMessagesFile) then
        fileDelete(savedMessagesFile)
    end

    local xmlFile = xmlCreateFile(savedMessagesFile, "debugMessages")
    if not xmlFile then
        outputDebugString("Failed to create debug messages XML file", 1)
        return false
    end

    local filteredMessages = {}
    for _, msg in ipairs(messages) do
        if not string.find(tostring(msg.message), "Debug commands loaded") then
            table.insert(filteredMessages, msg)
        end
    end

    for _, msg in ipairs(filteredMessages) do
        local node = xmlCreateChild(xmlFile, "message")
        xmlNodeSetAttribute(node, "time", msg.time or "")
        xmlNodeSetAttribute(node, "level", msg.level or "info")
        xmlNodeSetAttribute(node, "message", tostring(msg.message) or "")
        xmlNodeSetAttribute(node, "displayMessage", tostring(msg.displayMessage) or tostring(msg.message) or "")
        xmlNodeSetAttribute(node, "color", msg.color or "#FFFFFF")
        xmlNodeSetAttribute(node, "duplicates", tonumber(msg.duplicates) or 1)
    end

    xmlSaveFile(xmlFile)
    xmlUnloadFile(xmlFile)

    return true
end

function loadMessagesFromXML()
    local messages = {}

    if not fileExists(savedMessagesFile) then
        local xmlFile = xmlCreateFile(savedMessagesFile, "debugMessages")
        if xmlFile then
            xmlSaveFile(xmlFile)
            xmlUnloadFile(xmlFile)
            outputDebugString("Created empty debug messages XML file", 3)
        else
            outputDebugString("Failed to create debug messages XML file", 2)
        end
        return messages
    end

    local xmlFile = xmlLoadFile(savedMessagesFile)
    if not xmlFile then
        outputDebugString("Failed to load debug messages XML file", 2)
        return messages
    end

    local children = xmlNodeGetChildren(xmlFile)
    if children then
        for _, node in ipairs(children) do
            if xmlNodeGetName(node) == "message" then
                local msg = {
                    time = xmlNodeGetAttribute(node, "time") or "",
                    level = xmlNodeGetAttribute(node, "level") or "info",
                    message = xmlNodeGetAttribute(node, "message") or "",
                    displayMessage = xmlNodeGetAttribute(node, "displayMessage") or "",
                    color = xmlNodeGetAttribute(node, "color") or "#FFFFFF",
                    duplicates = tonumber(xmlNodeGetAttribute(node, "duplicates")) or 1
                }

                if not string.find(tostring(msg.message), "Debug commands loaded") then
                    table.insert(messages, msg)
                end
            end
        end
    end

    xmlUnloadFile(xmlFile)
    return messages
end

addEventHandler("onResourceStart", resourceRoot, function()
    savedMessages = loadMessagesFromXML()

    setTimer(function()
        local players = getElementsByType("player")
        for _, player in ipairs(players) do
            if isElement(player) then
                local messagesWithPriority = {
                    messages = savedMessages,
                    priority = true
                }
                triggerClientEvent(player, "debugGUI:receiveSavedMessages", player, messagesWithPriority)
            end
        end
    end, 500, 1)

    addEventHandler("onPlayerJoin", root, function()
        setTimer(function()
            if isElement(source) then
                triggerClientEvent(source, "debugGUI:receiveSavedMessages", source, savedMessages)
            end
        end, 2000, 1)
    end)
end)

addEvent("debugGUI:requestSavedMessages", true)
addEventHandler("debugGUI:requestSavedMessages", root, function()
    local messages = #savedMessages > 0 and savedMessages or loadMessagesFromXML()

    if isElement(client) and #messages > 0 then
        triggerClientEvent(client, "debugGUI:receiveSavedMessages", client, messages)
    end
end)

addEvent("debugGUI:saveMessages", true)
addEventHandler("debugGUI:saveMessages", root, function(messages, immediate)
    if type(messages) ~= "table" or #messages == 0 then
        return
    end

    if _inServerSaveOperation and not immediate then
        setTimer(function()
            if isElement(client) then
                triggerEvent("debugGUI:saveMessages", client, messages, true)
            end
        end, 1000, 1)
        return
    end

    _inServerSaveOperation = true

    savedMessages = messages

    local success = saveMessagesToXML(messages)

    setTimer(function() _inServerSaveOperation = false end, 500, 1)
end)

addEvent("debugGUI:requestSettings", true)
addEventHandler("debugGUI:requestSettings", root, function()
    setTimer(function()
        pcall(function()
            if isElement(client) then
                loadPlayerSettings(client)
            end
        end)
    end, 50, 1)
end)

addEvent("debugGUI:clearSavedMessages", true)
addEventHandler("debugGUI:clearSavedMessages", root, function()
    savedMessages = {}

    saveMessagesToXML({})
end)

function getDebugLevels()
    return DEBUG_LEVELS
end

addEventHandler("onPlayerLogout", root, function(thePreviousAccount)
    triggerClientEvent(source, "debugGUI:playerLogout", source)
end)

addEventHandler("onPlayerLogin", root, function(theAccount, previousAccount)
    triggerClientEvent(source, "debugGUI:playerLogin", source)
end)
