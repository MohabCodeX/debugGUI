local commandsEnabled = true

function commandDebugInfo(thePlayer, command, ...)
    if not commandsEnabled then return end

    local message = table.concat({ ... }, " ")
    if #message == 0 then
        message = "This is a test info message"
    end

    outputDebugString("INFO: " .. message)
    return true
end

addCommandHandler("dinf", commandDebugInfo)

function commandDebugWarning(thePlayer, command, ...)
    if not commandsEnabled then return end

    local message = table.concat({ ... }, " ")
    if #message == 0 then
        message = "This is a test warning message"
    end

    outputDebugString("WARNING: " .. message, 2)

    outputChatBox("Debug warning message sent: " .. message, thePlayer, 255, 165, 0)

    return true
end

addCommandHandler("dwar", commandDebugWarning)

function commandDebugError(thePlayer, command, ...)
    if not commandsEnabled then return end

    local message = table.concat({ ... }, " ")
    if #message == 0 then
        message = "This is a test error message"
    end

    outputDebugString("ERROR: " .. message, 1)

    outputChatBox("Debug error message sent: " .. message, thePlayer, 255, 100, 100)

    return true
end

addCommandHandler("derr", commandDebugError)

function commandDebugDebug(thePlayer, command, ...)
    if not commandsEnabled then return end

    local message = table.concat({ ... }, " ")
    if #message == 0 then
        message = "This is a test debug message"
    end

    outputDebugString("DEBUG: " .. message, 3)

    outputChatBox("Debug debug message sent: " .. message, thePlayer, 0, 255, 0)

    return true
end

addCommandHandler("ddbg", commandDebugDebug)

function toggleAdminRequirement(thePlayer, command)
    local account = getPlayerAccount(thePlayer)
    if not account or isGuestAccount(account) then return end

    local accountName = getAccountName(account)
    if not isObjectInACLGroup("user." .. accountName, aclGetGroup("Admin")) then
        outputChatBox("Only admins can toggle the admin access requirement", thePlayer, 255, 0, 0)
        return false
    end

    local requiredAdminAccess = true
    local settings = {}

    local value = getAccountData(account, "debugGUI.requiredAdminAccess")
    if value ~= nil then
        requiredAdminAccess = value
    end

    requiredAdminAccess = not requiredAdminAccess

    settings.requiredAdminAccess = requiredAdminAccess

    setAccountData(account, "debugGUI.requiredAdminAccess", requiredAdminAccess)

    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, "debugGUI:receiveSettings", player, settings)
    end

    outputChatBox(
        "Debug console now " .. (settings.requiredAdminAccess and "requires" or "doesn't require") .. " admin access.",
        thePlayer, 0, 255, 0)
    outputDebugString("Debug console access requirement changed by " .. getPlayerName(thePlayer) ..
        " - Admin access now " .. (settings.requiredAdminAccess and "required" or "not required"))

    return true
end

addCommandHandler("dtoggleadmin", toggleAdminRequirement)

function commandDebugHelp(thePlayer, command)
    if not commandsEnabled then return end

    outputChatBox("=== Debug Commands ===", thePlayer, 255, 255, 100)
    outputChatBox("/dinf [message] - Generate info message", thePlayer, 255, 255, 255)
    outputChatBox("/dwar [message] - Generate warning message", thePlayer, 255, 165, 0)
    outputChatBox("/derr [message] - Generate error message", thePlayer, 255, 0, 0)
    outputChatBox("/ddbg [message] - Generate debug message", thePlayer, 0, 255, 0)

    local account = getPlayerAccount(thePlayer)
    if account and not isGuestAccount(account) then
        local accountName = getAccountName(account)
        if isObjectInACLGroup("user." .. accountName, aclGetGroup("Admin")) then
            outputChatBox("/dtoggle - Toggle debug commands on/off", thePlayer, 255, 200, 0)
            outputChatBox("/dtoggleadmin - Toggle whether admin access is required", thePlayer, 255, 200, 0)
        end
    end

    return true
end

addCommandHandler("dhelp", commandDebugHelp)

function toggleDebugCommands(thePlayer, command)
    local account = getPlayerAccount(thePlayer)
    if not account or isGuestAccount(account) then return end

    local accountName = getAccountName(account)
    if not isObjectInACLGroup("user." .. accountName, aclGetGroup("Admin")) then
        outputChatBox("Only admins can toggle debug commands", thePlayer, 255, 0, 0)
        return false
    end

    commandsEnabled = not commandsEnabled
    outputChatBox("Debug commands " .. (commandsEnabled and "enabled" or "disabled"), thePlayer, 0, 255, 0)

    outputDebugString("Debug commands have been " .. (commandsEnabled and "enabled" or "disabled") ..
        " by " .. getPlayerName(thePlayer), 3)
    return true
end

addCommandHandler("dtoggle", toggleDebugCommands)

addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        local account = getPlayerAccount(player)
        if account and not isGuestAccount(account) then
            local accountName = getAccountName(account)
            if isObjectInACLGroup("user." .. accountName, aclGetGroup("Admin")) then
                outputChatBox("Debug commands loaded - use /dhelp to see available commands", player, 0, 255, 0)
            end
        end
    end
end)
