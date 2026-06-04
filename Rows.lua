local _, FlockEntesCharacterTracker = ...

-- Dynamic text: Computed out of an update function and then stored in the database.
local TYPE_DYNAMIC = FlockEntesCharacterTracker.CONSTANTS.TYPE_DYNAMIC

-- Input field: Input box that the user can type into, which is then persisted to the database.
local TYPE_INPUT   = FlockEntesCharacterTracker.CONSTANTS.TYPE_INPUT

-- Templates for a row of the table

local templateDynamicRow = {
    -- Default type (does not need to be specified)
    type = TYPE_DYNAMIC,
    -- Internal unique key. Used to access the database.
    key = "dummy",
    -- Row title, shown in the first column.
    title = "Dummy",
    -- Function for updating the cell value in the row.
    -- `stored` is the current value from the database and may be `nil` if no value is stored yet.
    -- If the function is not present, no value will be displayed.
    updateValue = function(stored) return "character" end,
    -- Function to format the value for showing it in the table.
    -- `value` is the value stored in the database, i.e. the value produced by `updateValue`.
    -- `value` will never be `nil` as the function is only called in that case.
    -- If the function is not present, the output of `updateValue` will be converted to a string.
    format = function(value) return value end,
}

local templateGlobalDynamicRow = {
    -- Default type (does not need to be specified)
    type = TYPE_DYNAMIC,
    -- Internal unique key. Used to access the global database.
    key = "dummyGlobal",
    -- Row title, shown as a prefix in the full-width global row.
    title = "Global",
    -- Function for updating the cell value in the row.
    -- `stored` is the current value from the database and may be `nil` if no value is stored yet.
    -- If the function is not present, no value will be displayed.
    updateValue = function(stored) return "global" end,
    -- Function to format the value for showing it in the table.
    -- If the function is not present, the output of `updateValue` will be converted to a string.
    format = function(value) return value end,
}

local templateInputRow = {
    type = TYPE_INPUT,
    -- Internal unique key. Used to access the database.
    key = "dummyInput",
    -- Row title, shown in the first column.
    title = "Input",
    -- Optional for showing multiple lines (defaults to 1)
    lines = 1,
}

local templateGlobalInputRow = {
    type = TYPE_INPUT,
    -- Internal unique key. Used to access the global database.
    key = "dummyGlobalInput",
    -- Global input rows are rendered as full-width inputs at the bottom of the table.
    title = "Global Input",
    -- Optional for showing multiple lines (defaults to 1)
    lines = 1,
}

local bonusroll = {
    type = TYPE_INPUT,
    key = "bonusroll",
    title = "Bonusroll",
}

local todo = {
    type = TYPE_INPUT,
    key = "todo",
    title = "To Do",
    lines = 3,
}

local name = {
    key = "name",
    title = "Character",
    updateValue = function(stored)
        local name = UnitName("player")
        local _, classFile = UnitClass("player")

        return {
            name = name,
            classFile = classFile,
        }
    end,
    format = function(value)
        local color = RAID_CLASS_COLORS[value.classFile]

        if not color then
            return value.name
        end

        return "|c" .. color.colorStr .. value.name .. "|r"
    end,
}

local function formatThousands(value)
    local formatted = tostring(value)

    while true do
        local replacements
        formatted, replacements = formatted:gsub("^(-?%d+)(%d%d%d)", "%1 %2")
        if replacements == 0 then
            return formatted
        end
    end
end

local gold = {
    key = "gold",
    title = "Gold",
    updateValue = function(stored)
        return GetMoney()
    end,
    format = function(value)
        return formatThousands(floor(value / 1e4)) .. "g"
    end,
}

local timePlayed = {
    key = "timePlayed",
    title = "Played",
    updateValue = function(stored)
        local timePlayed = FlockEntesCharacterTracker.timePlayed

        if not timePlayed or not timePlayed.totalTime or not timePlayed.levelTime then
            return stored
        end

        return {
            totalHours = floor(timePlayed.totalTime / 3600),
            levelHours = floor(timePlayed.levelTime / 3600),
        }
    end,
    format = function(value)
        return formatThousands(value.totalHours or 0) .. "h / " .. formatThousands(value.levelHours or 0) .. "h"
    end,
}

local itemLevel = {
    key = "itemLevel",
    title = "Item Level",
    updateValue = function(stored)
        local _, equippedItemLevel = GetAverageItemLevel()
        return equippedItemLevel
    end,
    format = function(value)
        return string.format("%.2f", value)
    end,
}

local mythicPlus = {
    key = "mythicPlus",
    title = "M+ Score",
    updateValue = function(stored)
        return C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    end,
    format = function(value)
        return value.currentSeasonScore
    end,
}

local resilientKeystoneAchievements = {
    [12] = 61233,
    [13] = 61235,
    [14] = 61236,
    [15] = 61237,
    [16] = 61239,
    [17] = 61240,
    [18] = 61241,
    [19] = 61242,
    [20] = 61243,
    [21] = 61244,
    [22] = 61245,
    [23] = 61246,
    [24] = 61247,
    [25] = 61248,
    [26] = 61249,
    [27] = 61250,
    [28] = 61251,
    [29] = 61252,
    [30] = 61253,
}

local resilientKeystone = {
    key = "resilientKeystone",
    title = "Resi",
    updateValue = function(stored)
        for level = 30, 12, -1 do
            local _, _, _, _, _, _, _, _, _, _, _, _, wasEarnedByMe =
                GetAchievementInfo(resilientKeystoneAchievements[level])

            if wasEarnedByMe then
                return level
            end
        end

        return 0
    end,
    format = function(value)
        return value > 0 and "+"..value or "-"
    end,
}

local keystone = {
    key = "keystone",
    title = "Keystone",
    updateValue = function(stored)
        return {
            keystoneMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID(),
            keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
        }
    end,
    format = function(value)
        local keystoneMapID = value.keystoneMapID or 0
        local dungeons = {
            [556] = "PIT",   -- Pit of Saron
            [161] = "SKY",   -- Skyreach
            [239] = "SEAT",  -- Seat of the Triumvirate
            [402] = "AA",    -- Algethar Academy
            [557] = "WS",    -- Windrunner Spire
            [558] = "MT",    -- Magister's Terrace
            [559] = "XENAS", -- Nexus-Point Xenas
            [560] = "MC",    -- Maisara Caverns
        };
        local keystoneMap = dungeons[keystoneMapID] or keystoneMapID
        local keystoneLevel = value and value.keystoneLevel or "?"
        return keystoneMap .. "+" .. keystoneLevel
    end,
}

local lastUpdated = {
    key = "lastUpdated",
    title = "Last updated",
    updateValue = function(stored)
        return time()
    end,
    format = function(value)
        return tostring(date("%Y-%m-%d %H:%M", value))
    end,
}

local voidcore = {
    key = "voidcore",
    title = "Voidcores",
    updateValue = function(stored)
        return C_CurrencyInfo.GetCurrencyInfo(3418)
    end,
    format = function(value)
        local text = value.quantity .. " (" .. value.totalEarned .. " / " .. value.maxQuantity .. ")"

        if value.quantity > 0 then
            return "|cff0099ff" .. text .. "|r"
        end

        return text
    end,
}

local token = {
    key = "thalassianTokenOfMerit",
    title = "Tokens",
    updateValue = function(stored)
        return C_Item.GetItemCount(258556, true)
    end,
    format = function(value)
        if value and value > 0 then
            return "|cff0099ff" .. value .. "|r"
        else
            return 0
        end
    end,
}


local heroCrest = {
    key = "heroCrest",
    title = "Hero Dawncrest",
    updateValue = function(stored)
        return C_CurrencyInfo.GetCurrencyInfo(3345)
    end,
    format = function(value)
        if value.maxQuantity and value.maxQuantity > 0 then
            return value.quantity .. " (" .. value.totalEarned .. " / " .. value.maxQuantity .. ")"
        else
            return value.quantity
        end
    end,
}

local mythCrest = {
    key = "mythCrest",
    title = "Myth Dawncrest",
    updateValue = function(stored)
        return C_CurrencyInfo.GetCurrencyInfo(3347)
    end,
    format = function(value)
        if value.maxQuantity and value.maxQuantity > 0 then
            return value.quantity .. " (" .. value.totalEarned .. " / " .. value.maxQuantity .. ")"
        else
            return value.quantity
        end
    end,
}

local ascendantVoidshards = {
    key = "ascendantVoidshards",
    title = "Ascendant",
    updateValue = function(stored)
        return {
            core = C_Item.GetItemCount(268552, true),
            shard = C_Item.GetItemCount(268650, true)
        }
    end,
    format = function(value)
        local core = value.core and value.core > 0 and value.core .. "c"
        local shard = value.shard and value.shard > 0 and value.shard .. "s"
        return (core and shard and core .. " " .. shard) or core or shard or "-"
    end,
}

local vault = {
    key = "vaultEntries",
    title = "Vault",
    updateValue = function(stored)
        return {
            activities = C_WeeklyRewards.GetActivities(),
            hasAvailableRewards = C_WeeklyRewards.HasAvailableRewards(),
        }
    end,
    format = function(value)
        if value.hasAvailableRewards then
            return "|cff0099ffOPEN ME|r"
        end

        local activities = value.activities

        local unlocked = 0
        for _, activity in ipairs(activities) do
            if activity.progress and activity.threshold and activity.progress >= activity.threshold then
                unlocked = unlocked + 1
            end
        end

        local color = unlocked >= 3 and "|cff00ff00" or "|cffff0000"
        return color .. unlocked .. "|r"
    end,
}

local mythicPlusRuns = {
    key = "mythicPlusRuns",
    title = "M+10 Runs",
    updateValue = function(stored)
        return C_MythicPlus.GetRunHistory(false, false, true)
    end,
    format = function(value)
        local count = 0
        for _, run in ipairs(value) do
            if run.thisWeek and run.completed and run.level >= 10 then
                count = count + 1
            end
        end

        local color = (count >= 8 and "|cff00ff00") or (count >= 4 and "|cffffff00") or (count >= 1 and "|cffff8800") or
        "|cffff0000"
        return color .. count .. "|r"
    end,
}

local function isAscendantVoidforged(tooltip)
    if not tooltip or not tooltip.lines then
        return false
    end

    for _, line in ipairs(tooltip.lines) do
        if line.leftText and line.leftText:find("Ascendant Voidforged", 1, true) then
            return true
        end
    end

    return false
end

local voidforged = {
    key = "voidforged",
    title = "Voidforged",
    updateValue = function(stored)
        local mainHandSlot = GetInventorySlotInfo("MAINHANDSLOT")
        local secondaryHandSlot = GetInventorySlotInfo("SECONDARYHANDSLOT")
        local trinket0Slot = GetInventorySlotInfo("TRINKET0SLOT")
        local trinket1Slot = GetInventorySlotInfo("TRINKET1SLOT")

        return {
            isWearingOffhand = GetInventoryItemLink("player", secondaryHandSlot) ~= nil,
            tooltips = {
                mainHand = C_TooltipInfo.GetInventoryItem("player", mainHandSlot),
                secondaryHand = GetInventoryItemLink("player", secondaryHandSlot) and
                C_TooltipInfo.GetInventoryItem("player", secondaryHandSlot),
                trinket0 = C_TooltipInfo.GetInventoryItem("player", trinket0Slot),
                trinket1 = C_TooltipInfo.GetInventoryItem("player", trinket1Slot)
            }
        }
    end,
    format = function(value)
        local total = (value.isWearingOffhand and 4) or 3
        local count = 0
        for _, tooltip in pairs(value.tooltips) do
            if isAscendantVoidforged(tooltip) then
                count = count + 1
            end
        end
        return count .. "/" .. total
    end,
}

-- List all rows in the order in which they should be displayed.
-- Use `{}` to add an empty row.
local ROWS = {
    name,
    timePlayed,
    gold,
    itemLevel,
    {},
    mythicPlus,
    resilientKeystone,
    keystone,
    {},
    bonusroll,
    voidcore,
    token,
    {},
    heroCrest,
    mythCrest,
    {},
    voidforged,
    ascendantVoidshards,
    {},
    vault,
    mythicPlusRuns,
    {},
    lastUpdated,
    {},
    todo
}


local globalTodo = {
    type = TYPE_INPUT,
    key = "globaltodo",
    title = "To Do",
    lines = 2,
}

local transmog = {
    type = TYPE_INPUT,
    key = "transmog",
    title = "Transmog",
}

-- List all global rows in the order in which they should be displayed.
-- Global rows are rendered at the bottom of the table and span the full table width.
-- Use `{}` to add an empty row.
local GLOBAL_ROWS = {
    {},
    transmog,
    globalTodo
}

FlockEntesCharacterTracker.ROWS = ROWS
FlockEntesCharacterTracker.GLOBAL_ROWS = GLOBAL_ROWS
