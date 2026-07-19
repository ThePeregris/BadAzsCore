-- [[ [|cff355E3BB|r]adAzs |cff32CD32CORE|r ]]
-- Author:  ThePeregris
-- Version: 2.5 (Generic Core + Sustain + Panel Router)
-- Target:  Vanilla/Classic WoW (1.12 / LUA 5.0)

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
        BadAzs_Msg("v2.5 (Generic Core) Carregado.")
        BadAzs_Vision()

        if not BadAzsCoreDB then BadAzsCoreDB = {} end
        if BadAzsCoreDB.SustainEnabled == nil then BadAzsCoreDB.SustainEnabled = true end
        if not BadAzsCoreDB.HPThreshold then BadAzsCoreDB.HPThreshold = 75 end
        if not BadAzsCoreDB.ManaThreshold then BadAzsCoreDB.ManaThreshold = 20 end
        if not BadAzsCoreDB.RestHPThreshold then BadAzsCoreDB.RestHPThreshold = 90 end
        if not BadAzsCoreDB.EmergencyHPThreshold then BadAzsCoreDB.EmergencyHPThreshold = 30 end
        if not BadAzsCoreDB.TargetLowHPSkip then BadAzsCoreDB.TargetLowHPSkip = 20 end
        
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
        BadAzs_Msg("Seguindo: |cff00ff00" .. BadAzs_FocusName)
    else
        BadAzs_Msg("|cffff0000Nenhum Focus definido!|r")
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
SLASH_BAASSIST1 = "/baassist"; SlashCmdList["BAASSIST"] = BadAzs_AssistFocus
SLASH_BAFFOLLOW1 = "/baffollow"; SlashCmdList["BAFFOLLOW"] = BadAzs_FollowFocus
SLASH_BAVIS1 = "/bavis"; SlashCmdList["BAVIS"] = BadAzs_Vision

-- =========================
-- [5] SUSTAIN (Pocoes / Stones / Bandagens) - baseado no BannionNurse
-- Universal: qualquer classe se beneficia disso, entao mora no Core.
-- =========================
local BadAzs_SustainItems = {
    HealPotions = {
        "Major Healing Potion", "Superior Healing Potion", "Greater Healing Potion",
        "Healing Potion", "Lesser Healing Potion", "Minor Healing Potion"
    },
    ManaPotions = {
        "Major Mana Potion", "Superior Mana Potion", "Greater Mana Potion",
        "Mana Potion", "Lesser Mana Potion", "Minor Mana Potion"
    },
    Stones = {
        "Major Healthstone", "Greater Healthstone", "Healthstone",
        "Lesser Healthstone", "Minor Healthstone", "Whipper Root Tuber"
    },
    ManaStones = { "Demonic Rune" },
    Bandages = {
        "Heavy Runecloth Bandage", "Runecloth Bandage", "Heavy Mageweave Bandage",
        "Mageweave Bandage", "Heavy Silk Bandage", "Silk Bandage",
        "Heavy Wool Bandage", "Wool Bandage", "Linen Bandage"
    }
}

-- Usa o primeiro item da bag que bater com "name" e nao estiver em cooldown
function BadAzs_UseItem(name)
    local bag
    for bag = 0, 4 do
        local slot
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and string.find(link, name) then
                local start, duration, enabled = GetContainerItemCooldown(bag, slot)
                if start == 0 and enabled == 1 then
                    UseContainerItem(bag, slot)
                    return true
                end
            end
        end
    end
    return false
end

local function BadAzs_TryItemList(list)
    local _, item
    for _, item in pairs(list) do
        if BadAzs_UseItem(item) then return item end
    end
    return nil
end

-- Escolhe o item pela gravidade do deficit (0-100), nao so o mais forte disponivel.
-- "list" precisa estar ordenada do mais forte (indice 1) pro mais fraco (indice N).
-- Deficit alto -> mira perto do topo da lista (item forte). Deficit baixo -> mira perto do fim (item fraco).
-- Se o item do tier ideal nao estiver na bag, expande pros vizinhos (primeiro mais forte, depois mais fraco).
local function BadAzs_TryBySeverity(list, deficitPct)
    local n = table.getn(list)
    if n == 0 then return nil end

    local normalized = deficitPct / 100
    if normalized > 1 then normalized = 1 end
    if normalized < 0 then normalized = 0 end

    local tierIndex = n - math.floor(normalized * (n - 1))
    if tierIndex < 1 then tierIndex = 1 end
    if tierIndex > n then tierIndex = n end

    local order = { tierIndex }
    local up, down = tierIndex - 1, tierIndex + 1
    while up >= 1 or down <= n do
        if up >= 1 then table.insert(order, up); up = up - 1 end
        if down <= n then table.insert(order, down); down = down + 1 end
    end

    local i
    for i = 1, table.getn(order) do
        local item = list[order[i]]
        if BadAzs_UseItem(item) then return item end
    end
    return nil
end

function BadAzs_Sustain()
    if not BadAzsCoreDB.SustainEnabled then return end

    local hp, hmax = UnitHealth("player"), UnitHealthMax("player")
    if not hmax or hmax == 0 then return end
    local hpPct = (hp / hmax) * 100
    local hpDeficit = 100 - hpPct
    local hasMana = UnitManaMax("player") > 0
    local manaPct = hasMana and BadAzs_GetMana() or 0
    local manaDeficit = 100 - manaPct
    local combat = UnitAffectingCombat("player")

    UIErrorsFrame:Clear()

    if combat then
        -- Se o alvo ja esta quase morto, o combate acaba logo - nao vale gastar
        -- poucao a toa, a menos que voce mesmo esteja num aperto de verdade.
        local targetDying = false
        if UnitExists("target") and not UnitIsDead("target") then
            local thp, thmax = UnitHealth("target"), UnitHealthMax("target")
            if thmax and thmax > 0 then
                local targetPct = (thp / thmax) * 100
                if targetPct <= BadAzsCoreDB.TargetLowHPSkip then
                    targetDying = true
                end
            end
        end

        local emergency = hpPct <= BadAzsCoreDB.EmergencyHPThreshold
        local shouldSustain = emergency or not targetDying

        -- Vida primeiro: stone (sem cooldown compartilhado com pocoes) depois pocao,
        -- ambos escolhendo o tier certo pra gravidade do deficit
        if hpPct <= BadAzsCoreDB.HPThreshold and shouldSustain then
            if BadAzs_TryBySeverity(BadAzs_SustainItems.Stones, hpDeficit) then return end
            if BadAzs_TryBySeverity(BadAzs_SustainItems.HealPotions, hpDeficit) then return end
        end

        -- Mana: pocao (por gravidade), depois Demonic Rune (item unico, sem tier)
        if hasMana and manaPct <= BadAzsCoreDB.ManaThreshold and shouldSustain then
            if BadAzs_TryBySeverity(BadAzs_SustainItems.ManaPotions, manaDeficit) then return end
            if BadAzs_TryItemList(BadAzs_SustainItems.ManaStones) then return end
        end
    else
        -- Cannibalize so funciona FORA de combate (o BannionNurse original chamava
        -- isso durante combate, o que nunca funcionaria - corrigido aqui)
        if UnitRace("player") == "Undead" and hpPct > 0 and hpPct < 80 then
            if BadAzs_Ready("Cannibalize") then
                CastSpellByName("Cannibalize")
                return
            end
        end

        if hpPct <= BadAzsCoreDB.RestHPThreshold and GetUnitSpeed("player") == 0 then
            local i
            for i = 1, 16 do
                local debuff = UnitDebuff("player", i)
                if debuff and string.find(debuff, "Bandage") then
                    BadAzs_Msg("|cffff0000Sem bandagem: debuff ativo!|r")
                    return
                end
            end

            local used = BadAzs_TryBySeverity(BadAzs_SustainItems.Bandages, hpDeficit)
            if used then
                BadAzs_Msg("|cff00ff00Aplicando " .. used .. "...|r")
                return
            end
        end
    end
end

-- ALT + /basustain = First Aid manual (respeitando debuff de bandagem)
do
    local _BadAzs_Sustain = BadAzs_Sustain
    function BadAzs_Sustain()
        if IsAltKeyDown() then
            if UnitAffectingCombat("player") then return end
            if GetUnitSpeed("player") ~= 0 then
                BadAzs_Msg("|cffff0000Pare de andar pra usar First Aid.|r")
                return
            end
            local i
            for i = 1, 16 do
                local debuff = UnitDebuff("player", i)
                if debuff and string.find(debuff, "Bandage") then
                    BadAzs_Msg("|cffff0000First Aid bloqueado (debuff ativo).|r")
                    return
                end
            end
            CastSpellByName("First Aid")
            return
        end
        _BadAzs_Sustain()
    end
end

SLASH_BASUSTAIN1 = "/basustain"
SlashCmdList["BASUSTAIN"] = BadAzs_Sustain

-- =========================
-- [6] ROTEADOR DE PAINEIS (/badazs <classe>)
-- =========================
-- Unico dono do slash "/badazs". Cada addon de classe se registra aqui
-- com BadAzs_PanelRegistry["warrior"] = function() ... end
-- Isso evita que dois addons tentem reivindicar o mesmo slash command
-- (o que faria o ultimo carregado roubar o comando do outro).
BadAzs_PanelRegistry = BadAzs_PanelRegistry or {}

SLASH_BADAZS1 = "/badazs"
SlashCmdList["BADAZS"] = function(msg)
    msg = string.lower(msg)
    if msg and BadAzs_PanelRegistry[msg] then
        BadAzs_PanelRegistry[msg]()
    else
        BadAzs_Msg("Uso: /badazs [warrior | pally | priest]")
    end
end
