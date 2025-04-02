local DEFAULT_SETTINGS = {
    autoCopyLastMsg = false,
    soundAlertsEnabled = false,
    maxMessages = 100,
    defaultFilterLevel = 5,
    panelStateOpen = false,
    requiredAdminAccess = true,
    allowDuplicates = true,
    showWatchPanel = false
}

if isElement(root) then
    function loadPlayerSettings(player)
        if not isElement(player) then return false end

        local success, savedSettings = pcall(function()
            local account = getPlayerAccount(player)
            if not account or isGuestAccount(account) then
                return {}
            end

            local settings = {}
            local settingNames = {
                "autoCopyLastMsg", "soundAlertsEnabled", "maxMessages",
                "defaultFilterLevel", "panelStateOpen", "requiredAdminAccess",
                "allowDuplicates", "showWatchPanel"
            }

            for _, setting in ipairs(settingNames) do
                local value = getAccountData(account, "debugGUI." .. setting)
                if value ~= nil then
                    settings[setting] = value
                end
            end

            return settings
        end)

        if not success or type(savedSettings) ~= "table" then
            savedSettings = {}
        end

        setTimer(function()
            pcall(function()
                if isElement(player) then
                    triggerClientEvent(player, "debugGUI:receiveSettings", player, savedSettings)
                end
            end)
        end, 50, 1)

        return savedSettings
    end

    function savePlayerSettings(player, settings)
        if not isElement(player) then
            return false
        end

        local account = getPlayerAccount(player)
        if not account or isGuestAccount(account) then
            return false
        end

        for setting, value in pairs(settings) do
            setAccountData(account, "debugGUI." .. setting, value)
        end

        return true
    end

    addEvent("debugGUI:saveSettings", true)
    addEventHandler("debugGUI:saveSettings", root, function(settings)
        savePlayerSettings(client, settings)
    end)

    addEvent("debugGUI:requestSettings", true)
    addEventHandler("debugGUI:requestSettings", root, function()
        loadPlayerSettings(client)
    end)

    addEventHandler("onPlayerLogin", root, function()
        loadPlayerSettings(source)
    end)

    addEventHandler("onResourceStart", resourceRoot, function()
        for _, player in ipairs(getElementsByType("player")) do
            local account = getPlayerAccount(player)
            if account and not isGuestAccount(account) then
                loadPlayerSettings(player)
            end
        end
    end)
end
