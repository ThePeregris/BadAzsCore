-- =====================================
-- BADAZS CORE (Vanilla 1.12 / Lua 5.0)
-- Version: 1.3 (Universal Racial & Vision)
-- =====================================

BadAzs_Debug = true
BadAzs_FocusName = nil
BadAzs_MouseoverUnit = nil

local function BadAzs_Msg(msg)
    if BadAzs_Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff355E3B[BadAzs]|r " .. msg)
    end
end

-- =========================
-- [1] MOUSEOVER TRACKER
-- =========================
do
    local origSetUnit = GameTooltip.SetUnit
    local origHide = GameTooltip.Hide
    function GameTooltip:SetUnit(unit)
        BadAzs_MouseoverUnit = unit
        return origSetUnit(self, unit)
    end
    function GameTooltip:Hide()
        BadAzs_MouseoverUnit = nil
        return origHide(self)
    end
end

-- =========================
-- [2] FOCUS SYSTEM
-- =========================
function BadAzs_SetFocus()
    if BadAzs_MouseoverUnit and UnitExists(BadAzs_MouseoverUnit) then
        BadAzs_FocusName = UnitName(BadAzs_MouseoverUnit)
    elseif UnitExists("target") then
        BadAzs_FocusName = UnitName("target")
    else
        BadAzs_FocusName = nil
        BadAzs_Msg("|cffff0000Focus Cleared|r")
        return
    end
    BadAzs_Msg("|cff00ff00Focus Set:|r " .. BadAzs_FocusName)
end

function BadAzs_ClearFocus()
    BadAzs_FocusName = nil
    BadAzs_Msg("|cffff0000Focus Cleared|r")
end

-- =========================
-- [3] VISION MODULE (CVar)
-- =========================
local function SafeSetCVar(cvar, value)
    pcall(function() SetCVar(cvar, value) end)
end

function BadAzs_Vision()
    SafeSetCVar("cameraDistanceMax", 50) 
    SafeSetCVar("cameraDistanceMaxFactor", 2) 
    SafeSetCVar("nameplateDistance", 41)
    SetView(4) 
    SetView(4) 
    BadAzs_Msg("|cff00ccffVision Applied:|r Cam 50 / Nameplates 41.")
end

-- =========================
-- [4] UNIVERSAL RACIAL
-- =========================
function BadAzs_UseRacial()
    local racials = {
        ["Human"]    = "Perception",
        ["Orc"]      = "Blood Fury",
        ["Troll"]    = "Berserking",
        ["Undead"]   = "Will of the Forsaken",
        ["Dwarf"]    = "Stoneform",
        ["Gnome"]    = "Escape Artist",
        ["NightElf"] = "Shadowmeld",
        ["Tauren"]   = "War Stomp",
        -- TurtleWoW Custom Races
        ["Goblin"]   = "Rocket Barrage", -- Ou "Rocket Jump" dependendo da spec/patch
        ["HighElf"]  = "Mana Tap"        -- Ou "Arcane Torrent"
    }

    local _, raceEn = UnitRace("player")
    local spellToCast = racials[raceEn]

    if not spellToCast then return end

    local i = 1
    while true do
        local name = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then break end
        if name == spellToCast then
            CastSpell(i, BOOKTYPE_SPELL)
            return true
        end
        i = i + 1
    end
end

-- =========================
-- [5] ITEMRACK WRAPPER
-- =========================
function BadAzs_EquipSet(setName)
    if ItemRack_EquipSet then
        ItemRack_EquipSet(setName)
        return true
    elseif ItemRack and ItemRack.EquipSet then
        ItemRack.EquipSet(setName)
        return true
    end
    return false
end

-- =========================
-- [6] SLASH COMMANDS
-- =========================
SLASH_BADFOCUS1 = "/badfocus"
SlashCmdList["BADFOCUS"] = BadAzs_SetFocus

SLASH_BADCLEAR1 = "/badclear"
SlashCmdList["BADCLEAR"] = BadAzs_ClearFocus

SLASH_BADVIS1 = "/badvis"
SlashCmdList["BADVIS"] = BadAzs_Vision

-- =========================
-- [7] AUTO-RUN & INITIALIZATION
-- =========================
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:SetScript("OnEvent", function()
    -- Aplica visão automaticamente ao logar
    BadAzs_Vision()
end)

BadAzs_Msg("Core v1.3 Loaded. Raciais atualizadas.")