-- [[ [|cff355E3BB|r]adAzs |cff32CD32CORE|r ]]
-- Author:  ThePeregris
-- Version: 2.1 (Dodge Detection)
-- Target:  Turtle WoW (1.12 / LUA 5.0)

BadAzs_Debug = true
BadAzs_FocusName = nil
BadAzs_LastDodge = 0 -- Armazena o tempo do último Dodge

-- Tabela para armazenar onde estão as magias de "Next Melee"
BadAzs_SlotCache = { 
    ["Heroic Strike"] = nil, 
    ["Cleave"] = nil, 
    ["Raptor Strike"] = nil 
}

-- Criação do Tooltip Scanner Global
CreateFrame("GameTooltip", "BadAzs_TooltipScanner", nil, "GameTooltipTemplate")
BadAzs_TooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function BadAzs_Msg(msg)
    if BadAzs_Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff355E3B[BadAzs]|r " .. msg)
    end
end

-- =========================
-- [1] EVENT HANDLER & INIT
-- =========================
local BadAzs_CoreFrame = CreateFrame("Frame")
BadAzs_CoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
BadAzs_CoreFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
BadAzs_CoreFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
BadAzs_CoreFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
-- Eventos do Swing Timer e Detecção de Dodge
BadAzs_CoreFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
BadAzs_CoreFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
BadAzs_CoreFrame:RegisterEvent("SPELLCAST_STOP")

-- Swing Timer Data
if not SP_ST_Data then SP_ST_Data = { main_start = 0 } end
BadAzs_IsAttacking = false

BadAzs_CoreFrame:SetScript("OnEvent", function()
    -- [[ INICIALIZAÇÃO ]]
    if event == "PLAYER_ENTERING_WORLD" then
        BadAzs_Msg("v2.1 (Core + Dodge) Carregado.")
        BadAzs_Vision() 

        -- Filtro de Spam de Chat
        local block = {
            "fail", "not ready", "enough rage", "enough mana", "Another action", "range", 
            "No target", "recovered", "Ability", "Must be in", "nothing to attack", 
            "facing", "Unknown unit", "Inventory is full", "Cannot equip", 
            "Item is not ready", "Target needs to be", "You are dead", "spell is not learned"
        }
        for i = 1, 7 do
            local frame = getglobal("ChatFrame"..i)
            if frame and not frame.BHooked then
                local original = frame.AddMessage
                frame.AddMessage = function(self, msg, r, g, b, id)
                    if msg and type(msg) == "string" then
                        for _, p in pairs(block) do if string.find(msg, p) then return end end
                    end
                    original(self, msg, r, g, b, id)
                end
                frame.BHooked = true
            end
        end
    end

    -- [[ CACHE DE SLOTS ]]
    if event == "PLAYER_ENTERING_WORLD" or event == "ACTIONBAR_SLOT_CHANGED" then
        for k in pairs(BadAzs_SlotCache) do BadAzs_SlotCache[k] = nil end
        for i = 1, 120 do
            if HasAction(i) then
                local texture = GetActionTexture(i)
                if texture then
                    if string.find(texture, "Ability_Rogue_Ambush") or      
                       string.find(texture, "Ability_Warrior_Cleave") or    
                       string.find(texture, "Ability_MeleeDamage") then     
                        
                        BadAzs_TooltipScanner:SetAction(i)
                        local name = BadAzs_TooltipScannerTextLeft1:GetText()
                        if name and BadAzs_SlotCache[name] ~= nil then 
                            BadAzs_SlotCache[name] = i
                        end
                    end
                end
            end
        end
    end

    -- [[ AUTO ATTACK STATUS ]]
    if event == "PLAYER_ENTER_COMBAT" then BadAzs_IsAttacking = true
    elseif event == "PLAYER_LEAVE_COMBAT" then BadAzs_IsAttacking = false 
    end

    -- [[ SWING TIMER & DODGE DETECTION ]]
    if event == "CHAT_MSG_COMBAT_SELF_HITS" then
        SP_ST_Data.main_start = GetTime()
        
    elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        SP_ST_Data.main_start = GetTime()
        
        -- Detecção de Dodge para Overpower
        if arg1 and string.find(arg1, "dodges") then
            BadAzs_LastDodge = GetTime()
        end
        
    elseif event == "SPELLCAST_STOP" then
        if arg1 and arg1 == "Slam" then SP_ST_Data.main_start = GetTime() end
    end
end)

-- =========================
-- [2] SMART CAST SYSTEM
-- =========================
function BadAzs_IsQueued(spellName)
    local slot = BadAzs_SlotCache[spellName]
    if slot and IsCurrentAction(slot) then return true end
    return false
end

function BadAzs_Cast(spellName, unit)
    if spellName == "Attack" then
        if not BadAzs_IsAttacking and UnitExists("target") and not UnitIsDead("target") then
            AttackTarget()
            BadAzs_IsAttacking = true
        end
        return
    end

    if (spellName == "Heroic Strike" or spellName == "Cleave" or spellName == "Raptor Strike") then
        if BadAzs_IsQueued(spellName) then return end
    end

    local switched = false
    if not unit and UnitExists("mouseover") and UnitIsVisible("mouseover") then
        TargetUnit("mouseover")
        switched = true
    end

    CastSpellByName(spellName)
    if switched then TargetLastTarget() end
end

-- =========================
-- [3] FOCUS SYSTEM
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

function BadAzs_AssistFocus()
    if BadAzs_FocusName then
        AssistByName(BadAzs_FocusName)
        BadAzs_Msg("Assisting: |cff00ff00" .. BadAzs_FocusName)
    else
        BadAzs_Msg("|cffff0000No Focus!|r")
    end
end

function BadAzs_FollowFocus()
    if BadAzs_FocusName then
        FollowByName(BadAzs_FocusName)
        BadAzs_Msg("Following: |cff00ff00" .. BadAzs_FocusName)
    else
        BadAzs_Msg("|cffff0000No Focus!|r")
    end
end

-- =========================
-- [4] UTILITIES & HELPERS
-- =========================
function BadAzs_Vision()
    pcall(function()
        SetCVar("cameraDistanceMax", 50)
        SetCVar("cameraDistanceMaxFactor", 2)
        SetCVar("nameplateDistance", 41)
    end)
    SetView(4); SetView(4)
end

function BadAzs_UseRacial()
    local racials = {
        ["Human"]    = "Perception", ["Orc"]      = "Blood Fury",
        ["Troll"]    = "Berserking", ["Undead"]   = "Will of the Forsaken",
        ["Dwarf"]    = "Stoneform",  ["Gnome"]    = "Escape Artist",
        ["NightElf"] = "Shadowmeld", ["Tauren"]   = "War Stomp",
        ["Goblin"]   = "Rocket Barrage", ["HighElf"] = "Mana Tap"
    }
    local _, raceEn = UnitRace("player")
    local spell = racials[raceEn]
    if spell then CastSpellByName(spell) end
end

function BadAzs_EquipSet(setName)
    if ItemRack_EquipSet then ItemRack_EquipSet(setName)
    elseif ItemRack and ItemRack.EquipSet then ItemRack.EquipSet(setName) end
end

function BadAzs_GetTargetHP()
    if not UnitExists("target") then return 0 end
    local h, hmax = UnitHealth("target"), UnitHealthMax("target")
    if not hmax or hmax == 0 then return 0 end
    return (h / hmax) * 100
end

function BadAzs_GetMana()
    local cur, max = UnitMana("player"), UnitManaMax("player")
    if max == 0 then return 0 end
    return (cur / max) * 100
end

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

function BadAzs_Ready(spellName)
    local id = BadAzs_FindSpellId(spellName)
    if not id then return false end
    local start, duration = GetSpellCooldown(id, BOOKTYPE_SPELL)
    local isUsable, notEnoughMana = true, false
    if IsUsableSpell then isUsable, notEnoughMana = IsUsableSpell(id, BOOKTYPE_SPELL) end
    if isUsable and not notEnoughMana and start == 0 then return true end
    return false
end

function BadAzs_TargetHasDebuff(textureName)
    local i = 1
    while UnitDebuff("target", i) do
        local texture = UnitDebuff("target", i)
        if string.find(texture, textureName) then return true end
        i = i + 1
    end
    return false
end

function BadAzs_HasBuff(buffName)
    local i = 1
    while UnitBuff("player", i) do
        local texture = UnitBuff("player", i)
        if string.find(texture, buffName) then return true end
        i = i + 1
    end
    return false
end

-- =========================
-- [5] SLASH COMMANDS
-- =========================
SLASH_BAFOCUS1 = "/bafocus"; SlashCmdList["BAFOCUS"] = BadAzs_SetFocus
SLASH_BACLEAR1 = "/baclear"; SlashCmdList["BACLEAR"] = BadAzs_ClearFocus
SLASH_BAVIS1 = "/bavis"; SlashCmdList["BAVIS"] = BadAzs_Vision
SLASH_BAASSIST1 = "/baassist"; SlashCmdList["BAASSIST"] = BadAzs_AssistFocus
SLASH_BAFOLLOW1 = "/bafollow"; SlashCmdList["BAFOLLOW"] = BadAzs_FollowFocus

SLASH_BACMD1 = "/ba"
SlashCmdList["BACMD"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff355E3B[BadAzs]|r Core Commands:")
    DEFAULT_CHAT_FRAME:AddMessage("/bafocus, /baclear, /baassist, /bavis")
end
