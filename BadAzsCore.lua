-- [[ [|cff355E3BB|r]adAzs |cff32CD32CORE|r ]]
-- Author:  ThePeregris
-- Version: 2.3 (Generic Core)
-- Target:  Turtle WoW (1.12 / LUA 5.0)

BadAzs_Debug = true
BadAzs_FocusName = nil
BadAzs_LastDodge = 0

-- Scanner Global (Usado pelos módulos de classe)
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
BadAzs_CoreFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
BadAzs_CoreFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
BadAzs_CoreFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
BadAzs_CoreFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
BadAzs_CoreFrame:RegisterEvent("SPELLCAST_STOP")

if not SP_ST_Data then SP_ST_Data = { main_start = 0 } end
BadAzs_IsAttacking = false

BadAzs_CoreFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        BadAzs_Msg("v2.3 (Generic Core) Carregado.")
        BadAzs_Vision() 
        
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

    if event == "PLAYER_ENTER_COMBAT" then BadAzs_IsAttacking = true
    elseif event == "PLAYER_LEAVE_COMBAT" then BadAzs_IsAttacking = false 
    end

    if event == "CHAT_MSG_COMBAT_SELF_HITS" then
        SP_ST_Data.main_start = GetTime()
    elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        SP_ST_Data.main_start = GetTime()
        if arg1 and string.find(arg1, "dodges") then
            BadAzs_LastDodge = GetTime()
        end
    elseif event == "SPELLCAST_STOP" then
        if arg1 and arg1 == "Slam" then SP_ST_Data.main_start = GetTime() end
    end
end)

-- =========================
-- [2] CAST SYSTEM (SAFE)
-- =========================

-- FUNÇÃO PRINCIPAL: Apenas ataca o alvo atual.
-- Não verifica filas (Queues). Isso é responsabilidade do módulo da classe.
function BadAzs_Cast(spellName)
    if spellName == "Attack" then
        if not BadAzs_IsAttacking and UnitExists("target") and not UnitIsDead("target") then
            AttackTarget()
            BadAzs_IsAttacking = true
        end
        return
    end

    CastSpellByName(spellName)
end

-- =========================
-- [3] MANUAL MOUSEOVER (/bamo)
-- =========================
function BadAzs_ManualMouseover(spellName, doAssist)
    local switched = false
    
    if UnitExists("mouseover") and UnitIsVisible("mouseover") then
        TargetUnit("mouseover")
        switched = true
    end

    CastSpellByName(spellName)

    if switched then
        if doAssist then
            AssistUnit("target")
        else
            TargetLastTarget()
        end
    end
end

SLASH_BAMO1 = "/bamo"
SlashCmdList["BAMO"] = function(msg)
    if not msg or msg == "" then return end

    local spell = msg
    local assist = false

    if string.find(msg, " assist$") then
        spell = string.gsub(msg, " assist$", "")
        assist = true
    end

    BadAzs_ManualMouseover(spell, assist)
end

-- =========================
-- [4] HELPERS
-- =========================

function BadAzs_SetFocus()
    if UnitExists("mouseover") and UnitIsVisible("mouseover") then
        BadAzs_FocusName = UnitName("mouseover")
        BadAzs_Msg("|cff00ff00Focus Set (mouseover):|r " .. BadAzs_FocusName)
        return
    end

    if UnitExists("target") then
        BadAzs_FocusName = UnitName("target")
        BadAzs_Msg("|cff00ff00Focus Set (target):|r " .. BadAzs_FocusName)
        return
    end

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

function BadAzs_Vision()
    pcall(function()
        SetCVar("cameraDistanceMax", 50)
        SetCVar("cameraDistanceMaxFactor", 2)
        SetCVar("nameplateDistance", 41)
    end)
    SetView(4); SetView(4)
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

SLASH_BAFOCUS1 = "/bafocus"; SlashCmdList["BAFOCUS"] = BadAzs_SetFocus
SLASH_BACLEAR1 = "/baclear"; SlashCmdList["BACLEAR"] = BadAzs_ClearFocus
SLASH_BAVIS1 = "/bavis"; SlashCmdList["BAVIS"] = BadAzs_Vision
SLASH_BAASSIST1 = "/baassist"; SlashCmdList["BAASSIST"] = BadAzs_AssistFocus


