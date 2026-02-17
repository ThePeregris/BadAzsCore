-- [[ [|cff355E3BB|r]adAzs |cff32CD32CORE|r ]]
-- Author:  ThePeregris
-- Version: 2.3 (Target Lock & Smart Utility)
-- Target:  Turtle WoW (1.12 / LUA 5.0)

local CoreVersion = "|cff355E3BBadAzsCore v2.3|r"
BadAzs_IsAttacking = false

-- ============================================================
-- [ 1. SCANNER DE TOOLTIP ]
-- ============================================================
-- Criado globalmente para ser usado por todos os módulos (Warrior, Paladin, Hunter)
BadAzs_TooltipScanner = CreateFrame("GameTooltip", "BadAzs_TooltipScanner", nil, "GameTooltipTemplate")
BadAzs_TooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

-- ============================================================
-- [ 2. HELPERS DE STATUS ]
-- ============================================================

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

-- ============================================================
-- [ 3. PROTEÇÃO DE "NEXT MELEE" (HS/CLEAVE/RAPTOR/HOLY) ]
-- ============================================================
-- Esta função verifica se a habilidade já está "na fila" (brilhando no botão)
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

-- ============================================================
-- [ 4. SISTEMA DE CAST INTELIGENTE ]
-- ============================================================

-- BadAzs_Cast: USADO PARA ROTAÇÃO. 
-- Foca 100% no alvo selecionado para não "engasgar" se o mouse se mover.
function BadAzs_Cast(spellName)
    if spellName == "Attack" then
        if not BadAzs_IsAttacking and UnitExists("target") and not UnitIsDead("target") then
            AttackTarget()
            BadAzs_IsAttacking = true
        end
        return
    end

    -- Proteção contra cancelamento de "On Next Swing"
    if (spellName == "Heroic Strike" or spellName == "Cleave" or 
        spellName == "Raptor Strike" or spellName == "Holy Strike") then
        if BadAzs_IsQueued(spellName) then return end
    end

    CastSpellByName(spellName)
end

-- BadAzs_Util: USADO PARA UTILITÁRIOS (Intervene, Cleanse, Buffs).
-- Prioriza o MOUSEOVER: troca alvo, casta e volta para o Boss instantaneamente.
function BadAzs_Util(spellName)
    local switched = false
    if UnitExists("mouseover") and UnitIsVisible("mouseover") then
        TargetUnit("mouseover")
        switched = true
    end

    CastSpellByName(spellName)

    if switched then TargetLastTarget() end
end

-- ============================================================
-- [ 5. INICIALIZAÇÃO E FILTRO DE CHAT ]
-- ============================================================
local coreFrame = CreateFrame("Frame")
coreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
coreFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        -- Filtro de Spam (Mensagens Vermelhas e Erros de Mana/Fúria)
        local block = {
            "fail", "not ready", "enough rage", "enough mana", "Another action", 
            "range", "No target", "recovered", "facing", "Inventory is full", 
            "Item is not ready", "Target needs to be", "You are dead"
        }
        
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
        DEFAULT_CHAT_FRAME:AddMessage(CoreVersion .. " Initialized. Target Lock: |cff00ff00ACTIVE|r")
    end
end)
