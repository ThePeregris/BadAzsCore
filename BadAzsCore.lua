-- [[ [|cff355E3B|r]adAzs |cff355E3BCore|r ]]
-- Author:  ThePeregris
-- Version: 2.1
-- Target:  Turtle WoW (1.12 / LUA 5.0)

local CoreVersion = "|cff355E3BBadAzsCore v2.1|r"
BadAzs_IsAttacking = false

-- Scanner de Tooltip
BadAzs_TooltipScanner = CreateFrame("GameTooltip", "BadAzs_TooltipScanner", nil, "GameTooltipTemplate")
BadAzs_TooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Helpers de Status
function BadAzs_GetMana() return (UnitMana("player") / UnitManaMax("player")) * 100 end
function BadAzs_GetTargetHP() return (UnitHealth("target") / UnitHealthMax("target")) * 100 end

function BadAzs_Ready(spell)
    local _, duration = GetSpellCooldown(spell, "spell")
    return (duration == 0)
end

function BadAzs_HasBuff(textureKeyword)
    for i=1, 32 do
        local t = UnitBuff("player", i)
        if t and string.find(t, textureKeyword) then return true end
    end
    return false
end

function BadAzs_TargetHasDebuff(textureKeyword)
    for i=1, 16 do
        local t = UnitDebuff("target", i)
        if t and string.find(t, textureKeyword) then return true end
    end
    return false
end

-- Proteção de "Next Melee"
function BadAzs_IsQueued(spellName)
    for i = 1, 120 do
        if HasAction(i) then
            BadAzs_TooltipScanner:ClearLines()
            BadAzs_TooltipScanner:SetAction(i)
            local text = BadAzs_TooltipScannerTextLeft1:GetText()
            if text == spellName then
                return IsCurrentAction(i) == 1
            end
        end
    end
    return false
end

-- Cast Básico
function BadAzs_Cast(spellName)
    if spellName == "Attack" then
        if not BadAzs_IsAttacking and UnitExists("target") and not UnitIsDead("target") then
            AttackTarget()
            BadAzs_IsAttacking = true
        end
        return
    end

    if (spellName == "Heroic Strike" or spellName == "Cleave" or spellName == "Raptor Strike" or spellName == "Holy Strike") then
        if BadAzs_IsQueued(spellName) then return end
    end

    CastSpellByName(spellName)
end

-- Inicialização e Filtro
local coreFrame = CreateFrame("Frame")
coreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
coreFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        local block = {"fail", "not ready", "enough rage", "enough mana", "range", "No target", "facing", "You are dead"}
        for i = 1, 7 do
            local f = _G["ChatFrame"..i]
            if f and not f.BadHooked then
                local original = f.AddMessage
                f.AddMessage = function(self, msg, r, g, b, id)
                    if msg and type(msg) == "string" then
                        for _, p in pairs(block) do if string.find(msg, p) then return end end
                    end
                    original(self, msg, r, g, b, id)
                end
                f.BadHooked = true
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage(CoreVersion .. " Initialized.")
    end
end)
