-- [[ [|cff355E3BB|r]adAzs |cff32CD32CORE|r ]]
-- Author:  ThePeregris
-- Version: 1.6 (Focus Assist & Follow Update)
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
    -- No 1.12 estável, focamos no Target atual ou no UnitFrame
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
    SetView(4)
    SetView(4)
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
    BadAzs_IsAttacking = (event == "PLAYER_ENTER_COMBAT")
end)

function BadAzs_StartAttack()
    if not BadAzs_IsAttacking and UnitExists("target") and not UnitIsDead("target") then
        AttackTarget()
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
-- [7] SLASH COMMANDS
-- =========================
SLASH_BADFOCUS1 = "/badfocus"
SlashCmdList["BADFOCUS"] = BadAzs_SetFocus

SLASH_BADCLEAR1 = "/badclear"
SlashCmdList["BADCLEAR"] = BadAzs_ClearFocus

SLASH_BADVIS1 = "/badvis"
SlashCmdList["BADVIS"] = BadAzs_Vision

-- Novos comandos solicitados
SLASH_FOCUSASSIST1 = "/focusassist"
SlashCmdList["FOCUSASSIST"] = BadAzs_AssistFocus

SLASH_FOCUSFOLLOW1 = "/focusfollow"
SlashCmdList["FOCUSFOLLOW"] = BadAzs_FollowFocus

-- =========================
-- [8] INITIALIZATION
-- =========================
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:SetScript("OnEvent", function()
    BadAzs_Vision()
    BadAzs_Msg("v1.6 Loaded. Use /focusassist and /focusfollow")
end)
