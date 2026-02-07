-- [[ [|cff355E3BB|r]adAzs |cff32CD32CORE|r ]]
-- Author:  ThePeregris
-- Version: 1.4 (Global Attack API)
-- Target:  Turtle WoW (1.12 / LUA 5.0)


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
        ["Goblin"]   = "Rocket Barrage",
        ["HighElf"]  = "Mana Tap"        
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
-- [7] AUTO-RUN & INITIALIZATION
-- =========================
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:SetScript("OnEvent", function()
    BadAzs_Vision()
end)

-- =========================
-- [8] GLOBAL AUTO-ATTACK API
-- =========================
BadAzs_IsAttacking = false -- Variável Global de Estado

local attackListener = CreateFrame("Frame")
attackListener:RegisterEvent("PLAYER_ENTER_COMBAT")
attackListener:RegisterEvent("PLAYER_LEAVE_COMBAT")
attackListener:RegisterEvent("PLAYER_REGEN_DISABLED")
attackListener:RegisterEvent("PLAYER_REGEN_ENABLED")

attackListener:SetScript("OnEvent", function()
    -- Sincroniza o estado visual do ataque (espadas cruzadas)
    if event == "PLAYER_ENTER_COMBAT" then
        BadAzs_IsAttacking = true
    elseif event == "PLAYER_LEAVE_COMBAT" then
        BadAzs_IsAttacking = false
    end
end)

function BadAzs_StartAttack()
    -- Só inicia se: Não estiver batendo + Tiver alvo + Alvo vivo
    if not BadAzs_IsAttacking and UnitExists("target") and not UnitIsDead("target") then
        AttackTarget()
        BadAzs_IsAttacking = true -- Força estado local para prevenir spam imediato
    end
end

-- ============================================================
-- [9] GLOBAL HELPERS (SHARED)
-- ============================================================
local BadAzs_SpellCache = {}

function BadAzs_GetSpellID(spellName)
    if BadAzs_SpellCache[spellName] then return BadAzs_SpellCache[spellName] end
    
    local i = 1
    while true do
        local spell, rank = GetSpellName(i, "spell")
        if not spell then break end
        if spell == spellName then 
            BadAzs_SpellCache[spellName] = i 
            return i 
        end
        i = i + 1
    end
    return nil
end

function BadAzs_Ready(spellName)
    if UnitXP_SP3_Addon and UnitXP_SP3_Addon.SpellReady then
        return UnitXP_SP3_Addon.SpellReady(spellName)
    end

    local id = BadAzs_GetSpellID(spellName)
    if not id then return false end
    
    local start, duration = GetSpellCooldown(id, "spell")
    return start == 0
end

function BadAzs_HasBuff(texturePartialName)
    for i=0, 31 do
        local texture = GetPlayerBuffTexture(i)
        if texture and string.find(texture, texturePartialName) then return true end
    end
    return false
end

function BadAzs_TargetHasDebuff(texturePartialName)
    for i=1, 16 do
        local texture = UnitDebuff("target", i)
        if texture and string.find(texture, texturePartialName) then return true end
    end
    return false
end

function BadAzs_GetTargetHP()
    if not UnitExists("target") then return 0 end
    if UnitHealthMax("target") == 0 then return 0 end
    return (UnitHealth("target") / UnitHealthMax("target")) * 100
end

function BadAzs_GetMana()
    if UnitManaMax("player") == 0 then return 0 end
    return (UnitMana("player") / UnitManaMax("player")) * 100
end


-- =========================
-- SLASH COMMANDS
-- =========================
SLASH_BADFOCUS1 = "/badfocus"
SlashCmdList["BADFOCUS"] = BadAzs_SetFocus

SLASH_BADCLEAR1 = "/badclear"
SlashCmdList["BADCLEAR"] = BadAzs_ClearFocus

SLASH_BADVIS1 = "/badvis"
SlashCmdList["BADVIS"] = BadAzs_Vision

BadAzs_Msg("Core v1.5 Loaded. Auto-Attack Global Ativo.")
