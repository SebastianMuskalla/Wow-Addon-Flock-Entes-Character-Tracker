local _, FlockEntesCharacterTracker = ...

-- Dynamic text: Computed out of a value extracted for the current character and then stored in the database.
local TYPE_DYNAMIC = FlockEntesCharacterTracker.CONSTANTS.TYPE_DYNAMIC

-- Input field: Input box that the user can type into, which is then persisted to the database.
local TYPE_INPUT   = FlockEntesCharacterTracker.CONSTANTS.TYPE_INPUT

-- Template for a row of the table
local rowTemplate = {
    type = TYPE_DYNAMIC,
    -- Internal unique key. Used to access the database.
    key = "dummy",
    -- Row title, shown in the first column.
    title = "Dummy",
    -- Function for updating the cell value in the row for the current character.
    -- `stored` is the current value from the database and may be `nil` if no value is stored yet.
    -- If the function is not present, no value will be displayed.
    updateCharacterValue = function(stored) return "character" end,
    -- Function to format the value for showing it in the table.
    -- `value` is the value stored in the database, i.e. the value produced by `updateCharacterValue`.
    -- `value` will never be `nil` as the function is only called in that case.
    -- If the function is not present, the output of `updateCharacterValue` will be converted to a string.
    format = function(value) return value end,
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
}

local name = {
    key = "name",
    title = "Character",
    updateCharacterValue = function(stored)
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

local gold = {
    key = "gold",
    title = "Gold",
    updateCharacterValue = function(stored)
        return GetMoney()
    end,
    format = function(value)
        return floor(value / 1e4) .. "g"
    end,
}

local itemLevel = {
    key = "itemLevel",
    title = "Item Level",
    updateCharacterValue = function(stored)
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
    updateCharacterValue = function(stored)
        return C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    end,
    format = function(value)
        return value.currentSeasonScore
    end,
}

local keystone = {
    key = "keystone",
    title = "Keystone",
    updateCharacterValue = function(stored)
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
    updateCharacterValue = function(stored)
        return time()
    end,
    format = function(value)
        return tostring(date("%Y-%m-%d %H:%M", value))
    end,
}

local voidcore = {
    key = "voidcore",
    title = "Voidcores",
    updateCharacterValue = function(stored)
        return C_CurrencyInfo.GetCurrencyInfo(3418)
    end,
    format = function(value)
        return value.quantity .. " (" .. value.totalEarned .. " / " .. value.maxQuantity .. ")"
    end,
}

local heroCrest = {
    key = "heroCrest",
    title = "Hero Dawncrest",
    updateCharacterValue = function(stored)
        return C_CurrencyInfo.GetCurrencyInfo(3345)
    end,
    format = function(value)
        return value.quantity .. " (" .. value.totalEarned .. " / " .. value.maxQuantity .. ")"
    end,
}

local mythCrest = {
    key = "mythCrest",
    title = "Myth Dawncrest",
    updateCharacterValue = function(stored)
        return C_CurrencyInfo.GetCurrencyInfo(3347)
    end,
    format = function(value)
        return value.quantity .. " (" .. value.totalEarned .. " / " .. value.maxQuantity .. ")"
    end,
}

local ascendantVoidshards = {
    key = "ascendantVoidshards",
    title = "Ascendant",
    updateCharacterValue = function(stored)
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
    updateCharacterValue = function(stored)
        return C_WeeklyRewards.GetActivities()
    end,
    format = function(value)
        local unlocked = 0
        for _, activity in ipairs(value) do
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
    updateCharacterValue = function(stored)
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
    updateCharacterValue = function(stored)
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
    gold,
    itemLevel,
    {},
    mythicPlus,
    keystone,
    {},
    bonusroll,
    voidcore,
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

FlockEntesCharacterTracker.ROWS = ROWS
