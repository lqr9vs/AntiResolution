--[[
    4:3 Anti-Resolution Script
    Created by lqr9vs
    
    This script detects if a player is using a 4:3 resolution and prevents them from playing in this format
    by displaying a warning message and rendering the screen black until the player
    changes their resolution.
]]

local config = Config

local isWarningActive = false
local warningStartTime = 0
local blackScreenActive = false
local manualOverride = nil 
local lastScreenWidth, lastScreenHeight = 0, 0 
local lastCheckTime = 0 

local function IsAspectRatio4by3()
    if manualOverride ~= nil then
        return manualOverride, 0 
    end
    
    local screenWidth, screenHeight = GetActiveScreenResolution()
    
    if screenWidth == 0 or screenHeight == 0 then
        screenWidth, screenHeight = GetScreenResolution()
    end
    
    if screenWidth == 0 or screenHeight == 0 then
        screenWidth, screenHeight = GetScreenActiveResolution()
    end
    
    local resolutionChanged = false
    if config.detectResolutionChanges and (lastScreenWidth ~= screenWidth or lastScreenHeight ~= screenHeight) then
        resolutionChanged = true
        lastScreenWidth, lastScreenHeight = screenWidth, screenHeight
        
        if config.debugMode then
            TriggerEvent('chat:addMessage', {
                color = {255, 165, 0},
                multiline = true,
                args = {"SYSTEM", "Resolution change detected: " .. screenWidth .. "x" .. screenHeight}
            })
        end
    end
    
    local aspectRatio = 0
    if screenWidth > 0 and screenHeight > 0 then
        aspectRatio = screenWidth / screenHeight
    else
        return false, 0 
    end
    
    local is16by9Resolution = false
    for _, res in ipairs(config.resolutions16by9) do
        if math.abs(screenWidth - res.width) < 10 and math.abs(screenHeight - res.height) < 10 then
            is16by9Resolution = true
            break
        end
    end
    
    local is4by3AdvancedDetection = false
    local indicatorsCount = 0 
    
    if config.advancedDetection then
        if config.checkFOV then
            local currentFOV = GetGameplayCamFov()
            if currentFOV < config.fovThreshold then
                indicatorsCount = indicatorsCount + 1
                if config.debugMode then
                    TriggerEvent('chat:addMessage', {
                        color = {255, 0, 255}, 
                        multiline = true,
                        args = {"DETECTION", "Low FOV detected (" .. currentFOV .. " < " .. config.fovThreshold .. "), potentially indicating 4:3 mode"}
                    })
                end
            end
        end
        
        if screenWidth == 1920 and screenHeight == 1080 then
            local safezone = GetSafeZoneSize()
            if safezone < 0.9 then 
                indicatorsCount = indicatorsCount + 1
                if config.debugMode then
                    TriggerEvent('chat:addMessage', {
                        color = {255, 0, 255}, 
                        multiline = true,
                        args = {"DETECTION", "Modified safezone detected (" .. safezone .. "), potentially indicating stretched 4:3 mode"}
                    })
                end
            end
        end
        
        local hudWidth = GetAspectRatio(true)
        if hudWidth < 1.6 then 
            indicatorsCount = indicatorsCount + 1
            if config.debugMode then
                TriggerEvent('chat:addMessage', {
                    color = {255, 0, 255}, 
                    multiline = true,
                    args = {"DETECTION", "Low HUD aspect ratio detected (" .. hudWidth .. " < 1.6), potentially indicating 4:3 mode"}
                })
            end
        end
        
        if GetProfileSetting(221) ~= 0 then 
            indicatorsCount = indicatorsCount + 1
            if config.debugMode then
                TriggerEvent('chat:addMessage', {
                    color = {255, 0, 255}, 
                    multiline = true,
                    args = {"DETECTION", "Modified graphics setting detected, potentially indicating 4:3 mode"}
                })
            end
        end
        
        if indicatorsCount >= config.requiredIndicatorsCount then
            is4by3AdvancedDetection = true
            if config.debugMode then
                TriggerEvent('chat:addMessage', {
                    color = {255, 165, 0}, -- Orange
                    multiline = true,
                    args = {"DETECTION", indicatorsCount .. " positive indicators detected (minimum required: " .. config.requiredIndicatorsCount .. ")"}
                })
            end
        end
    end
    
    if is16by9Resolution and is4by3AdvancedDetection then
        if config.debugMode then
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0}, 
                multiline = true,
                args = {"DETECTION", "Standard 16:9 resolution but advanced detection indicates 4:3"}
            })
        end
        return true, indicatorsCount
    end
    
    if is16by9Resolution and not is4by3AdvancedDetection then
        if config.debugMode and (GetGameTimer() - lastCheckTime > 5000 or resolutionChanged) then
            lastCheckTime = GetGameTimer()
            TriggerEvent('chat:addMessage', {
                color = {0, 255, 0},
                multiline = true,
                args = {"DEBUG", "Resolution: " .. screenWidth .. "x" .. screenHeight .. " | Ratio: " .. aspectRatio .. " | Detected as standard 16:9 resolution"}
            })
        end
        return false, indicatorsCount
    end
    
    local is4by3Resolution = false
    
    for _, res in ipairs(config.resolutions4by3) do
        if math.abs(screenWidth - res.width) < 10 and math.abs(screenHeight - res.height) < 10 then
            is4by3Resolution = true
            break
        end
    end
    
    local isRatio4by3 = aspectRatio < config.aspectRatioThreshold
    
    if not is4by3Resolution and config.detectStretchedMode then
        for _, res in ipairs(config.resolutions4by3) do
            if math.abs(screenHeight - res.height) < 10 then
                local expectedWidth = res.height * (4/3)
                if math.abs(screenWidth - expectedWidth) > 100 and not is16by9Resolution then
                    is4by3Resolution = true
                    break
                end
            end
        end
    end
    
    if not is4by3Resolution and config.detectStretchedMode then
        if is16by9Resolution and is4by3AdvancedDetection then
            is4by3Resolution = true
            if config.debugMode then
                TriggerEvent('chat:addMessage', {
                    color = {255, 0, 0}, -- Red
                    multiline = true,
                    args = {"DETECTION", "Stretched 4:3 mode detected on a 16:9 resolution"}
                })
            end
        end
    end
    
    if config.forceDetection then
        is4by3Resolution = true
    end
    
    if config.debugMode and (GetGameTimer() - lastCheckTime > 5000 or resolutionChanged) then
        lastCheckTime = GetGameTimer()
        local detectionMethod = "Aspect ratio"
        
        if isRatio4by3 then
            detectionMethod = "4:3 aspect ratio detected (" .. aspectRatio .. " < " .. config.aspectRatioThreshold .. ")"
        elseif is4by3Resolution and config.detectStretchedMode then
            detectionMethod = "Stretched 4:3 resolution detected"
        elseif is4by3Resolution and not config.detectStretchedMode then
            detectionMethod = "Exact 4:3 resolution detected"
        elseif is4by3AdvancedDetection then
            detectionMethod = "Advanced detection (FOV, HUD, etc.)"
        elseif config.forceDetection then
            detectionMethod = "Forced detection"
        elseif manualOverride ~= nil then
            detectionMethod = "Manual override"
        end
        
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            multiline = true,
            args = {"DEBUG", "Resolution: " .. screenWidth .. "x" .. screenHeight .. " | Ratio: " .. aspectRatio .. " | Threshold: " .. config.aspectRatioThreshold .. " | Method: " .. detectionMethod}
        })
    end
    
    return isRatio4by3 or is4by3Resolution or is4by3AdvancedDetection, indicatorsCount
end

local function ShowWarningMessage()
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(config.warningMessage)
    EndTextCommandDisplayHelp(0, false, true, config.scaleformDuration)
    
    SetTextFont(4)
    SetTextScale(0.8, 0.8)
    SetTextColour(255, 0, 0, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("4:3 RESOLUTION NOT ALLOWED")
    EndTextCommandDisplayText(0.5, 0.2)
    
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("Please change your resolution to continue playing")
    EndTextCommandDisplayText(0.5, 0.3)
end

local function DrawBlackScreen()
    DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255)
end

local function CheckResolutionAndUpdateState()
    local is4by3, indicatorsCount = IsAspectRatio4by3()
    
    local shouldActivateBlackScreen = is4by3
    
    if config.strictMode and indicatorsCount > 0 and not is4by3 then
        shouldActivateBlackScreen = true
        if config.debugMode then
            TriggerEvent('chat:addMessage', {
                color = {255, 165, 0}, 
                multiline = true,
                args = {"STRICT MODE", "Black screen activated because " .. indicatorsCount .. " indicator(s) detected (even if below the required threshold)"}
            })
        end
    end
    
    if shouldActivateBlackScreen then
        if not isWarningActive then
            isWarningActive = true
            warningStartTime = GetGameTimer()
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {"SYSTEM", "4:3 resolution is not allowed on this server. Please change your resolution."}
            })
        end
        
        ShowWarningMessage()
        
        blackScreenActive = true
    else
        if isWarningActive then
            TriggerEvent('chat:addMessage', {
                color = {0, 255, 0},
                multiline = true,
                args = {"SYSTEM", "Correct resolution detected. You can now play."}
            })
        end
        
        isWarningActive = false
        blackScreenActive = false
    end
    
    return is4by3
end

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"SYSTEM", "4:3 anti-resolution script loaded. Checking your resolution..."}
    })
    
    lastScreenWidth, lastScreenHeight = GetActiveScreenResolution()
    
    CheckResolutionAndUpdateState()
    
    while true do
        CheckResolutionAndUpdateState()
        
        Citizen.Wait(config.checkInterval)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if blackScreenActive then
            DrawBlackScreen()
            ShowWarningMessage()
        end
    end
end)

RegisterCommand("testresolution", function()
    local is4by3, indicatorsCount = IsAspectRatio4by3()
    local screenWidth, screenHeight = GetActiveScreenResolution()
    local aspectRatio = screenWidth / screenHeight
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"TEST", "Resolution: " .. screenWidth .. "x" .. screenHeight .. " | Ratio: " .. aspectRatio .. " | Is 4:3: " .. tostring(is4by3) .. " | Indicators: " .. indicatorsCount}
    })
end, false)

RegisterCommand("checkresolution", function()
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"SYSTEM", "Forced resolution check..."}
    })
    
    lastScreenWidth, lastScreenHeight = 0, 0
    
    local is4by3 = CheckResolutionAndUpdateState()
    
    TriggerEvent('chat:addMessage', {
        color = is4by3 and {255, 0, 0} or {0, 255, 0},
        multiline = true,
        args = {"SYSTEM", is4by3 and "4:3 resolution detected!" or "Correct resolution detected."}
    })
end, false)

RegisterCommand("force4by3", function()
    Config.forceDetection = not Config.forceDetection
    config.forceDetection = Config.forceDetection
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"SYSTEM", "Forced 4:3 mode detection: " .. tostring(config.forceDetection)}
    })
    
    CheckResolutionAndUpdateState()
end, false)

RegisterCommand("detectstretched", function()
    Config.detectStretchedMode = not Config.detectStretchedMode
    config.detectStretchedMode = Config.detectStretchedMode
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"SYSTEM", "Stretched mode detection: " .. tostring(config.detectStretchedMode)}
    })
    
    CheckResolutionAndUpdateState()
end, false)

RegisterCommand("set4by3", function(source, args)
    if args[1] == "true" or args[1] == "1" then
        manualOverride = true
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            multiline = true,
            args = {"SYSTEM", "Manual 4:3 mode set to: ENABLED"}
        })
    elseif args[1] == "false" or args[1] == "0" then
        manualOverride = false
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            multiline = true,
            args = {"SYSTEM", "Manual 4:3 mode set to: DISABLED"}
        })
    elseif args[1] == "auto" or args[1] == "reset" then
        manualOverride = nil
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            multiline = true,
            args = {"SYSTEM", "Manual 4:3 mode reset to: AUTOMATIC"}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"SYSTEM", "Usage: /set4by3 [true/false/auto]"}
        })
    end
    
    CheckResolutionAndUpdateState()
end, false)

RegisterCommand("advanceddetection", function()
    Config.advancedDetection = not Config.advancedDetection
    config.advancedDetection = Config.advancedDetection
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"SYSTEM", "Advanced detection: " .. tostring(config.advancedDetection)}
    })
    
    CheckResolutionAndUpdateState()
end, false)
print("^2[Anti-Resolution]^7 Script created by ^lqr9vs^7")
print("^2[Anti-Resolution]^7 Script started successfully!")
RegisterCommand("checkfov", function()
    Config.checkFOV = not Config.checkFOV
    config.checkFOV = Config.checkFOV
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"SYSTEM", "FOV check: " .. tostring(config.checkFOV)}
    })
    
    CheckResolutionAndUpdateState()
end, false)


RegisterCommand("detectioninfo", function()
    local screenWidth, screenHeight = GetActiveScreenResolution()
    local aspectRatio = screenWidth / screenHeight
    local currentFOV = GetGameplayCamFov()
    local safezone = GetSafeZoneSize()
    local hudWidth = GetAspectRatio(true)
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"INFO", "=== DETECTION INFORMATION ==="}
    })
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"INFO", "Resolution: " .. screenWidth .. "x" .. screenHeight}
    })
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"INFO", "Aspect ratio: " .. aspectRatio}
    })
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"INFO", "FOV: " .. currentFOV}
    })
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"INFO", "Safezone: " .. safezone}
    })
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"INFO", "HUD aspect ratio: " .. hudWidth}
    })
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"INFO", "Graphics setting 221: " .. GetProfileSetting(221)}
    })
    
    local is4by3 = CheckResolutionAndUpdateState()
    
    TriggerEvent('chat:addMessage', {
        color = is4by3 and {255, 0, 0} or {0, 255, 0},
        multiline = true,
        args = {"INFO", "Detection result: " .. (is4by3 and "4:3 DETECTED" or "NOT 4:3")}
    })
end, false)

RegisterCommand("resetdetection", function()
    manualOverride = nil
    Config.forceDetection = false
    Config.detectStretchedMode = true
    Config.advancedDetection = true
    Config.checkFOV = true
    Config.fovThreshold = 45
    Config.requiredIndicatorsCount = 2
    Config.strictMode = true
    config.forceDetection = false
    config.detectStretchedMode = true
    config.advancedDetection = true
    config.checkFOV = true
    config.fovThreshold = 45
    config.requiredIndicatorsCount = 2
    config.strictMode = true
    
    lastScreenWidth, lastScreenHeight = 0, 0
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"SYSTEM", "Detection settings reset to default values"}
    })
    
    CheckResolutionAndUpdateState()
end, false)

RegisterCommand("setfovthreshold", function(source, args)
    if args[1] and tonumber(args[1]) then
        local newThreshold = tonumber(args[1])
        if newThreshold >= 30 and newThreshold <= 90 then
            Config.fovThreshold = newThreshold
            config.fovThreshold = newThreshold
            TriggerEvent('chat:addMessage', {
                color = {255, 255, 0},
                multiline = true,
                args = {"SYSTEM", "FOV threshold set to: " .. newThreshold}
            })
        else
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {"SYSTEM", "FOV threshold must be between 30 and 90"}
            })
        end
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"SYSTEM", "Usage: /setfovthreshold [value]"}
        })
    end
    
    CheckResolutionAndUpdateState()
end, false)

RegisterCommand("setindicators", function(source, args)
    if args[1] and tonumber(args[1]) then
        local newCount = tonumber(args[1])
        if newCount >= 1 and newCount <= 4 then
            Config.requiredIndicatorsCount = newCount
            config.requiredIndicatorsCount = newCount
            TriggerEvent('chat:addMessage', {
                color = {255, 255, 0},
                multiline = true,
                args = {"SYSTEM", "Required indicators count set to: " .. newCount}
            })
        else
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {"SYSTEM", "Indicators count must be between 1 and 4"}
            })
        end
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"SYSTEM", "Usage: /setindicators [value]"}
        })
    end
    
    CheckResolutionAndUpdateState()
end, false)

RegisterCommand("strictmode", function()
    Config.strictMode = not Config.strictMode
    config.strictMode = Config.strictMode
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"SYSTEM", "Strict mode (black screen on any indicator detected): " .. tostring(config.strictMode)}
    })
    
    CheckResolutionAndUpdateState()
end, false)