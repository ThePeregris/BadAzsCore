-- [[ [|cff355E3BB|r]adAzs |cff32CD32CORE|r ]]
-- Author:  ThePeregris & Gemini
-- Version: 1.8 (Crash Fix)
-- Target:  Turtle WoW (1.12 / LUA 5.0)

BadAzs_Debug = true
BadAzs_FocusName = nil

local function BadAzs_Msg(msg)
    if BadAzs_Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff355E3B[BadAzs]|r " .. msg)
    end
end

-- =========================
-- [1] FOCUS SYSTEM
-- =========================
function BadAzs_SetFocus()
    if UnitExists("target") then
        BadAzs_FocusName = UnitName("target")
        BadAzs_Msg("|cff00ff00Focus Set:|r " .. BadAzs_FocusName)
    else
        BadAzs_FocusName = nil
        BadAzs_Msg("|cffff0000Focus Cleared|r")
    end
end

function BadAzs_ClearFocus()
    BadAzs_FocusName = nil
    BadAzs_Msg("|cffff0000Focus Cleared|r")
end

-- =========================
-- [2] FOCUS UTILITIES
-- =========================
function BadAzs_AssistFocus()
    if BadAzs_FocusName then
        AssistByName(BadAzs_FocusName)
        BadAzs_Msg("Assisting: |cff00ff00" .. BadAzs_FocusName)
    else
        BadAzs_Msg("|cffff0000No Focus to Assist!|r")
    end
end

function BadAzs_FollowFocus()
    if BadAzs_FocusName then
        FollowByName(BadAzs_FocusName)
        BadAzs_Msg("Following: |cff00ff00" .. BadAzs_FocusName)
    else
        BadAzs_Msg("|cffff0000No Focus to Follow!|r")
    end
end

-- =========================
-- [3] VISION MODULE
-- =========================
function BadAzs_Vision()
    pcall(function()
        SetCVar("cameraDistanceMax", 50)
        SetCVar("cameraDistanceMaxFactor", 2)
        SetCVar("nameplateDistance", 41)
    end)
    SetView(4); SetView(4)
    BadAzs_Msg("|cff00ccffVision Applied.|r")
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
    local spell = racials[raceEn]
    if spell then CastSpellByName(spell) end
end

-- =========================
-- [5] AUTO-ATTACK API
-- =========================
BadAzs_IsAttacking = false
local attackListener = CreateFrame("Frame")
attackListener:RegisterEvent("PLAYER_ENTER_COMBAT")
attackListener:RegisterEvent("PLAYER_LEAVE_COMBAT")
attackListener:SetScript("OnEvent", function()
    if event == "PLAYER_ENTER_COMBAT" then
        BadAzs_IsAttacking = true
    elseif event == "PLAYER_LEAVE_COMBAT" then
        BadAzs_IsAttacking = false
    end
end)

function BadAzs_StartAttack()
    if not BadAzs_IsAttacking and UnitExists("target") and not UnitIsDead("target") then
        AttackTarget()
        BadAzs_IsAttacking = true
    end
end

-- =========================
-- [6] ITEMRACK WRAPPER
-- =========================
function BadAzs_EquipSet(setName)
    if ItemRack_EquipSet then ItemRack_EquipSet(setName)
    elseif ItemRack and ItemRack.EquipSet then ItemRack.EquipSet(setName) end
end

-- =========================
-- [7] HELPER FUNCTIONS (API GLOBAL)
-- =========================

-- Retorna HP do Alvo em % (0 a 100)
function BadAzs_GetTargetHP()
    if not UnitExists("target") then return 0 end
    local h = UnitHealth("target")
    local hmax = UnitHealthMax("target")
    if not hmax or hmax == 0 then return 0 end
    return (h / hmax) * 100
end

-- Retorna Mana do Jogador em % (0 a 100)
function BadAzs_GetMana()
    local cur = UnitMana("player")
    local max = UnitManaMax("player")
    if max == 0 then return 0 end
    return (cur / max) * 100
end

-- Encontra o ID de uma magia pelo nome
function BadAzs_FindSpellId(spellName)
    local i = 1
    while true do
        local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then break end
        if name == spellName then return i end
        i = i + 1
    end
    return nil
end

-- Verifica se a magia esta pronta
function BadAzs_Ready(spellName)
    local id = BadAzs_FindSpellId(spellName)
    if not id then return false end

    local start, duration = GetSpellCooldown(id, BOOKTYPE_SPELL)
    
    local isUsable = true
    local notEnoughMana = false

    -- Proteção: Verifica se a função global existe antes de chamar
    if IsUsableSpell then
        isUsable, notEnoughMana = IsUsableSpell(id, BOOKTYPE_SPELL)
    end

    if isUsable and not notEnoughMana and start == 0 then
        return true
    end
    return false
end

-- Verifica debuff no alvo (textura)
function BadAzs_TargetHasDebuff(textureName)
    local i = 1
    while UnitDebuff("target", i) do
        local texture = UnitDebuff("target", i)
        if string.find(texture, textureName) then
            return true
        end
        i = i + 1
    end
    return false
end

-- Verifica buff no jogador (textura)
function BadAzs_HasBuff(buffName)
    local i = 1
    while UnitBuff("player", i) do
        local texture = UnitBuff("player", i)
        if string.find(texture, buffName) then
            return true
        end
        i = i + 1
    end
    return false
end

-- ============================================================
-- [8] NATIVE SWING TIMER (Virtual SP_SwingTimer)
-- ============================================================
if not SP_ST_Data then SP_ST_Data = { main_start = 0 } end

local BadAzs_SwingFrame = CreateFrame("Frame")
BadAzs_SwingFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
BadAzs_SwingFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
BadAzs_SwingFrame:RegisterEvent("SPELLCAST_STOP")

BadAzs_SwingFrame:SetScript("OnEvent", function()
    -- Se acertou ou errou um golpe branco, registra o tempo
    if event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        SP_ST_Data.main_start = GetTime()
    
    -- Se terminou de castar Slam, reseta o tempo
    elseif event == "SPELLCAST_STOP" then
        if arg1 and arg1 == "Slam" then
             SP_ST_Data.main_start = GetTime()
        end
    end
end)

BadAzs_Msg("Swing Timer Nativo Ativado.")

-- =========================
-- [9] SLASH COMMANDS
-- =========================
SLASH_BADFOCUS1 = "/badfocus"
SlashCmdList["BADFOCUS"] = BadAzs_SetFocus

SLASH_BADCLEAR1 = "/badclear"
SlashCmdList["BADCLEAR"] = BadAzs_ClearFocus

SLASH_BADVIS1 = "/badvis"
SlashCmdList["BADVIS"] = BadAzs_Vision

SLASH_FOCUSASSIST1 = "/focusassist"
SlashCmdList["FOCUSASSIST"] = BadAzs_AssistFocus

SLASH_FOCUSFOLLOW1 = "/focusfollow"
SlashCmdList["FOCUSFOLLOW"] = BadAzs_FollowFocus

-- =========================
-- [10] INITIALIZATION
-- =========================
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:SetScript("OnEvent", function()
    BadAzs_Vision()
    BadAzs_Msg("v1.8 (Safe Mode) Loaded.")
    BadAzs_Msg("Use /focusassist and /focusfollow.")

end)
