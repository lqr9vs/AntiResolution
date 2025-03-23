--[[
    Configuration for the 4:3 Anti-Resolution Script
    Created by lqr9vs
    
    This file contains all the configurable settings for the script.
    Modify these values according to your needs.
]]

Config = {
    -- General settings
    checkInterval = 1000, -- Check interval in ms (1 second)
    warningDuration = 10000, -- Warning message display duration in ms (10 seconds)
    aspectRatioThreshold = 1.3, -- Threshold to detect a 4:3 ratio (which is approximately 1.33)
    warningMessage = "~r~WARNING~w~: 4:3 resolution is not allowed on this server.\nPlease change your resolution to continue playing.",
    scaleformDuration = 500, -- Scaleform display duration in ms
    debugMode = false, -- Enable debug mode (displays messages in the chat)
    
    -- Detection options
    detectStretchedMode = true, -- Enable detection of stretched 4:3 modes
    forceDetection = false, -- Force detection of 4:3 mode even if the resolution does not match
    detectResolutionChanges = true, -- Detect resolution changes in real-time
    
    -- Advanced detection options
    advancedDetection = true, -- Enable advanced detection
    checkFOV = true, -- Check FOV to detect 4:3 mode
    fovThreshold = 45, -- FOV threshold (lower values may indicate 4:3 mode)
    detectVisualStretch = true, -- Visually detect if the image is stretched
    
    -- Validation settings
    requiredIndicatorsCount = 2, -- Number of positive indicators required to confirm 4:3 mode
    strictMode = true, -- Strict mode: black screen as soon as an indicator is detected
    
    -- List of common 4:3 resolutions (exact)
    resolutions4by3 = {
        {width = 640, height = 480},
        {width = 800, height = 600},
        {width = 1024, height = 768},
        {width = 1152, height = 864},
        {width = 1280, height = 960},
        {width = 1400, height = 1050},
        {width = 1440, height = 1080},
        {width = 1600, height = 1200},
        {width = 1920, height = 1440},
        {width = 960, height = 720},
        {width = 1280, height = 1024},
    },
    
    -- List of common 16:9 resolutions (to avoid false positives)
    resolutions16by9 = {
        {width = 1280, height = 720},
        {width = 1366, height = 768},
        {width = 1600, height = 900},
        {width = 1920, height = 1080},
        {width = 2560, height = 1440},
        {width = 3840, height = 2160},
    }
}