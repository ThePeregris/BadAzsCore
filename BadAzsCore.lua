-- [[ [|cff355E3BB|r]adAzs |cff32CD32CORE|r ]]
-- Author:  ThePeregris
-- Version: 2.6 (Cleanup: removido auto-attack duplicado com bug, codigo morto)
-- Target:  Vanilla/Classic WoW (1.12 / LUA 5.0)

BadAzs_Debug = true
BadAzs_FocusName = nil

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

BadAzs_CoreFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        BadAzs_Msg("v2.6 (Generic Core) Carregado.")
        BadAzs_Vision()

        if not BadAzsCoreDB then BadAzsCoreDB = {} end
        if BadAzsCoreDB.SustainEnabled == nil then BadAzsCoreDB.SustainEnabled = true end
        if not BadAzsCoreDB.HPThreshold then BadAzsCoreDB.HPThreshold = 75 end
        if not BadAzsCoreDB.ManaThreshold then BadAzsCoreDB.ManaThreshold = 20 end
        if not BadAzsCoreDB.RestHPThreshold then BadAzsCoreDB.RestHPThreshold = 90 end
        if not BadAzsCoreDB.EmergencyHPThreshold then BadAzsCoreDB.EmergencyHPThreshold = 30 end
        if not BadAzsCoreDB.TargetLowHPSkip then BadAzsCoreDB.TargetLowHPSkip = 20 end
        if not BadAzsCoreDB.Locale then BadAzsCoreDB.Locale = "EN" end
        
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
end)

-- =========================
-- [2] MANUAL MOUSEOVER (/bamo)
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
-- [3] HELPERS
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
-- [3a] AUTO-ATTACK (unica fonte de verdade)
-- AttackTarget() E um toggle de verdade (confirmado): chamar de novo enquanto
-- ja ataca DESLIGA o auto-attack em vez de mante-lo. Rastrear isso por eventos
-- de combate (PLAYER_ENTER_COMBAT etc.) e pouco confiavel - esse evento so diz
-- que voce esta "em combate" (ex: apanhando), nao que seu auto-attack real
-- esta ligado. A forma confiavel e perguntar pro proprio jogo: achar o slot
-- do botao de Attack na actionbar (IsAttackAction) e checar se esta ativo
-- (IsCurrentAction) antes de decidir se chama o toggle.
-- =========================
local BadAzs_AttackSlot = nil

local BadAzs_AttackSlotFrame = CreateFrame("Frame")
BadAzs_AttackSlotFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
BadAzs_AttackSlotFrame:SetScript("OnEvent", function()
    BadAzs_AttackSlot = nil
end)

local function BadAzs_FindAttackSlot()
    local i
    for i = 1, 120 do
        if IsAttackAction(i) then return i end
    end
    return nil
end

function BadAzs_StartAttack()
    if not BadAzs_AttackSlot then
        BadAzs_AttackSlot = BadAzs_FindAttackSlot()
    end

    -- Se achamos o slot e ele ja esta ativo, NAO chama AttackTarget() de novo
    -- (isso desligaria o ataque). Se nao achamos o slot (Attack nao esta em
    -- nenhuma actionbar), cai pro toggle direto mesmo, sem como confirmar.
    if BadAzs_AttackSlot and IsCurrentAction(BadAzs_AttackSlot) then
        return
    end

    if UnitExists("target") and not UnitIsDead("target") then
        AttackTarget()
    end
end

-- =========================
-- [3b] DETECTOR DE MOVIMENTO
-- GetUnitSpeed nao existe no cliente 1.12 (so foi adicionada no WotLK).
-- Sobrescrever MoveForwardStart/StrafeLeftStart etc. e BLOQUEADO pelo client
-- (sao funcoes protegidas, so a UI da Blizzard pode mexer nelas). A unica
-- forma segura: so LER a posicao do jogador periodicamente e comparar.
-- Nao funciona dentro de masmorras/instancias (GetPlayerMapPosition retorna
-- 0,0 la dentro) - nesse caso assume "parado" e nao bloqueia o Sustain.
-- =========================
local BadAzsMoveFrame = CreateFrame("Frame")
local BadAzsLastX, BadAzsLastY = nil, nil
local BadAzsIsMovingFlag = false
local BadAzsLastMoveCheck = 0

BadAzsMoveFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - BadAzsLastMoveCheck < 0.2 then return end
    BadAzsLastMoveCheck = now

    local x, y = GetPlayerMapPosition("player")
    if x and y and (x ~= 0 or y ~= 0) then
        if BadAzsLastX == nil then
            BadAzsIsMovingFlag = false
        else
            local dx, dy = x - BadAzsLastX, y - BadAzsLastY
            BadAzsIsMovingFlag = (dx * dx + dy * dy) > 0.0000001
        end
        BadAzsLastX, BadAzsLastY = x, y
    else
        BadAzsIsMovingFlag = false
    end
end)

function BadAzs_IsMoving()
    return BadAzsIsMovingFlag
end

-- =========================
-- [4] SUSTAIN (Pocoes / Stones / Bandagens) - baseado no BannionNurse
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
    local emergency = hpPct <= BadAzsCoreDB.EmergencyHPThreshold

    UIErrorsFrame:Clear()

    -- Bandagem tem PRIORIDADE sobre pocao: e de graca (sem cooldown
    -- compartilhado com pocao/stone, so gasto de pano), entao vale tentar
    -- primeiro sempre que der (parado, sem debuff ativo) - poupa pocao pra
    -- quando realmente precisar. Excecao: emergencia real (HP critico) pula
    -- direto pra pocao, porque bandagem tem cast time e pode ser interrompida
    -- por dano, e ali velocidade importa mais que economia.
    if not emergency and hpPct <= BadAzsCoreDB.RestHPThreshold and not BadAzs_IsMoving() then
        local hasDebuff = false
        local i
        for i = 1, 16 do
            local debuff = UnitDebuff("player", i)
            if debuff and string.find(debuff, "Bandage") then
                hasDebuff = true
                break
            end
        end

        if not hasDebuff then
            local used = BadAzs_TryBySeverity(BadAzs_SustainItems.Bandages, hpDeficit)
            if used then
                BadAzs_Msg("|cff00ff00Aplicando " .. used .. "...|r")
                return
            end
        else
            BadAzs_Msg("|cffff0000Sem bandagem: debuff ativo!|r")
        end
    end

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

        local shouldSustain = emergency or not targetDying

        -- Vida: stone (sem cooldown compartilhado com pocoes) depois pocao,
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
    end
end

-- ALT + /basustain = First Aid manual (respeitando debuff de bandagem)
do
    local _BadAzs_Sustain = BadAzs_Sustain
    function BadAzs_Sustain()
        if IsAltKeyDown() then
            if UnitAffectingCombat("player") then return end
            if BadAzs_IsMoving() then
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
-- [5] COMANDOS MANUAIS DE POCAO
-- Sem argumento: usa uma pocao AGORA (por gravidade), ignorando o threshold
-- automatico - voce decidiu, o addon so escolhe qual tier faz mais sentido.
-- Com numero: redefine o threshold que o automatico usa (ex: /bapotion 40).
-- =========================
local function BadAzs_ManualHeal()
    local hp, hmax = UnitHealth("player"), UnitHealthMax("player")
    if not hmax or hmax == 0 then return end
    local hpDeficit = 100 - ((hp / hmax) * 100)

    UIErrorsFrame:Clear()
    if BadAzs_TryBySeverity(BadAzs_SustainItems.Stones, hpDeficit) then return end
    if BadAzs_TryBySeverity(BadAzs_SustainItems.HealPotions, hpDeficit) then return end
    BadAzs_Msg("|cffff0000Nenhuma poucao/stone de heal disponivel na bag.|r")
end

local function BadAzs_ManualMana()
    if UnitManaMax("player") == 0 then
        BadAzs_Msg("|cffff0000Sua classe nao usa mana.|r")
        return
    end
    local manaDeficit = 100 - BadAzs_GetMana()

    UIErrorsFrame:Clear()
    if BadAzs_TryBySeverity(BadAzs_SustainItems.ManaPotions, manaDeficit) then return end
    if BadAzs_TryItemList(BadAzs_SustainItems.ManaStones) then return end
    BadAzs_Msg("|cffff0000Nenhuma pocao de mana/Demonic Rune disponivel na bag.|r")
end

SLASH_BAPOTION1 = "/bapotion"
SlashCmdList["BAPOTION"] = function(msg)
    local num = tonumber(msg)
    if num then
        BadAzsCoreDB.HPThreshold = num
        BadAzs_Msg("|cff00ff00Threshold de HP pra pocao automatica: " .. num .. "%|r")
    else
        BadAzs_ManualHeal()
    end
end

SLASH_BAMANA1 = "/bamana"
SlashCmdList["BAMANA"] = function(msg)
    local num = tonumber(msg)
    if num then
        BadAzsCoreDB.ManaThreshold = num
        BadAzs_Msg("|cff00ff00Threshold de mana pra pocao automatica: " .. num .. "%|r")
    else
        BadAzs_ManualMana()
    end
end

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
        BadAzs_Msg("Uso: /badazs [warrior | pally | priest | core]")
    end
end

-- =========================
-- [7] PAINEL DE CONFIGURACAO (/badazs core)
-- Formato de livro: pagina esquerda = controles, pagina direita = explicacoes
-- =========================
local BadAzsCore_L = {
    EN = {
        title         = "BadAzs Core",
        enableLabel   = "Enable Sustain",
        hpLabel       = "HP% - use heal (in combat)",
        manaLabel     = "Mana% - use mana potion (in combat)",
        restLabel     = "HP% - use bandage (out of combat)",
        emergencyLabel = "HP% - always heal (real emergency)",
        targetSkipLabel = "Target HP% - skip potion if dying",
        explainEnable   = "Turns Sustain on/off entirely. Doesn't affect /bapotion and /bamana.",
        explainHP       = "Below this HP in combat: healthstone, then heal potion, tier by severity.",
        explainMana     = "Below this Mana in combat: mana potion, then Demonic Rune.",
        explainRest     = "Below this HP out of combat, while standing still: applies a bandage.",
        explainEmergency = "Safety net: below this HP, always heals - even if the enemy is dying.",
        explainTargetSkip = "Target HP at or below this: skip the potion, fight's ending soon.",
        cmdHeader = "Macros",
        cmdList = {
            "/bapotion - Use a heal item now (ignores threshold)",
            "/bapotion N - Set HP threshold to N%",
            "/bamana - Use a mana potion now (ignores threshold)",
            "/bamana N - Set mana threshold to N%",
            "Hold ALT + /basustain - Cast First Aid manually",
            "/badazs <class> - Open a class panel"
        }
    },
    PT = {
        title         = "BadAzs Core",
        enableLabel   = "Ativar Sustain",
        hpLabel       = "HP% - usar heal (em combate)",
        manaLabel     = "Mana% - usar pocao de mana (em combate)",
        restLabel     = "HP% - usar bandagem (fora de combate)",
        emergencyLabel = "HP% - curar sempre (emergencia real)",
        targetSkipLabel = "HP% do alvo - poupar pocao se quase morto",
        explainEnable   = "Liga/desliga o Sustain inteiro. Nao afeta /bapotion e /bamana.",
        explainHP       = "Abaixo desse HP em combate: healthstone, depois pocao de heal, tier por gravidade.",
        explainMana     = "Abaixo dessa mana em combate: pocao de mana, depois Demonic Rune.",
        explainRest     = "Abaixo desse HP fora de combate, parado: aplica bandagem.",
        explainEmergency = "Rede de seguranca: abaixo desse HP, cura sempre - mesmo com o inimigo quase morto.",
        explainTargetSkip = "HP do alvo nesse % ou menos: poupa a pocao, o combate ta acabando.",
        cmdHeader = "Macros",
        cmdList = {
            "/bapotion - Usa um item de heal agora (ignora o threshold)",
            "/bapotion N - Define o threshold de HP pra N%",
            "/bamana - Usa pocao de mana agora (ignora o threshold)",
            "/bamana N - Define o threshold de mana pra N%",
            "Segure ALT + /basustain - Cast manual de First Aid",
            "/badazs <classe> - Abre o painel de uma classe"
        }
    }
}

local Panel = CreateFrame("Frame", "BadAzsCorePanel", UIParent)
Panel:SetWidth(620)
Panel:SetHeight(620)
Panel:SetPoint("CENTER", 0, 0)
Panel:SetMovable(true)
Panel:EnableMouse(true)
Panel:RegisterForDrag("LeftButton")
Panel:SetScript("OnDragStart", function() this:StartMoving() end)
Panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
Panel:SetFrameStrata("DIALOG")
Panel:Hide()

local LeftPage = CreateFrame("Frame", nil, Panel)
LeftPage:SetWidth(300)
LeftPage:SetHeight(400)
LeftPage:SetPoint("TOPLEFT", Panel, "TOPLEFT", 0, -60)
LeftPage:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local RightPage = CreateFrame("Frame", nil, Panel)
RightPage:SetWidth(300)
RightPage:SetHeight(400)
RightPage:SetPoint("TOPLEFT", Panel, "TOPLEFT", 320, -60)
RightPage:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local title = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("|cff32CD32BadAzs Core|r")

local closeBtn = CreateFrame("Button", "BadAzsCorePanelClose", Panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -4, -4)

local langBtn = CreateFrame("Button", "BadAzsCore_LangBtn", Panel, "UIPanelButtonTemplate")
langBtn:SetPoint("TOPLEFT", 8, -10)
langBtn:SetWidth(44); langBtn:SetHeight(20)

-- ==================== PAGINA ESQUERDA: CONTROLES ====================
local enableCheck = CreateFrame("CheckButton", "BadAzsCore_EnableCheck", LeftPage, "UICheckButtonTemplate")
enableCheck:SetPoint("TOPLEFT", 20, -16)
getglobal(enableCheck:GetName().."Text"):SetText("")
local enableLabel = LeftPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
enableLabel:SetPoint("LEFT", enableCheck, "RIGHT", 4, 0)
enableLabel:SetJustifyH("LEFT")
enableCheck:SetScript("OnClick", function()
    BadAzsCoreDB.SustainEnabled = (this:GetChecked() == 1)
end)

-- Sliders individuais (cada um resolve o texto no refresh, conforme o idioma)
local hpSlider = CreateFrame("Slider", "BadAzsCore_HPSlider", LeftPage, "OptionsSliderTemplate")
hpSlider:SetPoint("TOP", 0, -52)
hpSlider:SetWidth(240)
hpSlider:SetMinMaxValues(0, 100)
hpSlider:SetValueStep(5)
getglobal(hpSlider:GetName().."Low"):SetText("0")
getglobal(hpSlider:GetName().."High"):SetText("100")
hpSlider:SetScript("OnValueChanged", function()
    BadAzsCoreDB.HPThreshold = this:GetValue()
    getglobal(this:GetName().."Text"):SetText(BadAzsCore_L[BadAzsCoreDB.Locale].hpLabel .. ": " .. this:GetValue())
end)

local manaSlider = CreateFrame("Slider", "BadAzsCore_ManaSlider", LeftPage, "OptionsSliderTemplate")
manaSlider:SetPoint("TOP", 0, -108)
manaSlider:SetWidth(240)
manaSlider:SetMinMaxValues(0, 100)
manaSlider:SetValueStep(5)
getglobal(manaSlider:GetName().."Low"):SetText("0")
getglobal(manaSlider:GetName().."High"):SetText("100")
manaSlider:SetScript("OnValueChanged", function()
    BadAzsCoreDB.ManaThreshold = this:GetValue()
    getglobal(this:GetName().."Text"):SetText(BadAzsCore_L[BadAzsCoreDB.Locale].manaLabel .. ": " .. this:GetValue())
end)

local restSlider = CreateFrame("Slider", "BadAzsCore_RestSlider", LeftPage, "OptionsSliderTemplate")
restSlider:SetPoint("TOP", 0, -164)
restSlider:SetWidth(240)
restSlider:SetMinMaxValues(0, 100)
restSlider:SetValueStep(5)
getglobal(restSlider:GetName().."Low"):SetText("0")
getglobal(restSlider:GetName().."High"):SetText("100")
restSlider:SetScript("OnValueChanged", function()
    BadAzsCoreDB.RestHPThreshold = this:GetValue()
    getglobal(this:GetName().."Text"):SetText(BadAzsCore_L[BadAzsCoreDB.Locale].restLabel .. ": " .. this:GetValue())
end)

local emergencySlider = CreateFrame("Slider", "BadAzsCore_EmergencySlider", LeftPage, "OptionsSliderTemplate")
emergencySlider:SetPoint("TOP", 0, -220)
emergencySlider:SetWidth(240)
emergencySlider:SetMinMaxValues(0, 100)
emergencySlider:SetValueStep(5)
getglobal(emergencySlider:GetName().."Low"):SetText("0")
getglobal(emergencySlider:GetName().."High"):SetText("100")
emergencySlider:SetScript("OnValueChanged", function()
    BadAzsCoreDB.EmergencyHPThreshold = this:GetValue()
    getglobal(this:GetName().."Text"):SetText(BadAzsCore_L[BadAzsCoreDB.Locale].emergencyLabel .. ": " .. this:GetValue())
end)

local targetSkipSlider = CreateFrame("Slider", "BadAzsCore_TargetSkipSlider", LeftPage, "OptionsSliderTemplate")
targetSkipSlider:SetPoint("TOP", 0, -276)
targetSkipSlider:SetWidth(240)
targetSkipSlider:SetMinMaxValues(0, 100)
targetSkipSlider:SetValueStep(5)
getglobal(targetSkipSlider:GetName().."Low"):SetText("0")
getglobal(targetSkipSlider:GetName().."High"):SetText("100")
targetSkipSlider:SetScript("OnValueChanged", function()
    BadAzsCoreDB.TargetLowHPSkip = this:GetValue()
    getglobal(this:GetName().."Text"):SetText(BadAzsCore_L[BadAzsCoreDB.Locale].targetSkipLabel .. ": " .. this:GetValue())
end)

-- ==================== PAGINA DIREITA: EXPLICACOES ====================
local explainEnable = RightPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
explainEnable:SetPoint("TOP", 0, -14)
explainEnable:SetWidth(260); explainEnable:SetJustifyH("LEFT"); explainEnable:SetSpacing(2)

local explainHP = RightPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
explainHP:SetPoint("TOP", 0, -52)
explainHP:SetWidth(260); explainHP:SetJustifyH("LEFT"); explainHP:SetSpacing(2)

local explainMana = RightPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
explainMana:SetPoint("TOP", 0, -108)
explainMana:SetWidth(260); explainMana:SetJustifyH("LEFT"); explainMana:SetSpacing(2)

local explainRest = RightPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
explainRest:SetPoint("TOP", 0, -164)
explainRest:SetWidth(260); explainRest:SetJustifyH("LEFT"); explainRest:SetSpacing(2)

local explainEmergency = RightPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
explainEmergency:SetPoint("TOP", 0, -220)
explainEmergency:SetWidth(260); explainEmergency:SetJustifyH("LEFT"); explainEmergency:SetSpacing(2)

local explainTargetSkip = RightPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
explainTargetSkip:SetPoint("TOP", 0, -276)
explainTargetSkip:SetWidth(260); explainTargetSkip:SetJustifyH("LEFT"); explainTargetSkip:SetSpacing(2)

-- ==================== RODAPE: LEMBRETE DE COMANDOS ====================
local divider = Panel:CreateTexture(nil, "ARTWORK")
divider:SetPoint("TOP", 0, -468)
divider:SetWidth(590); divider:SetHeight(1)
divider:SetTexture(0.5, 0.5, 0.5, 0.5)

local cmdHeader = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cmdHeader:SetPoint("TOP", 0, -480)

local cmdText = Panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cmdText:SetPoint("TOP", 0, -500)
cmdText:SetWidth(560)
cmdText:SetJustifyH("LEFT")
cmdText:SetSpacing(3)

function BadAzsCore_RefreshPanel()
    local L = BadAzsCore_L[BadAzsCoreDB.Locale]

    title:SetText("|cff32CD32" .. L.title .. "|r")
    langBtn:SetText(BadAzsCoreDB.Locale)

    if BadAzsCoreDB.SustainEnabled then enableCheck:SetChecked(1) else enableCheck:SetChecked(nil) end
    enableLabel:SetText(L.enableLabel)

    hpSlider:SetValue(BadAzsCoreDB.HPThreshold or 75)
    manaSlider:SetValue(BadAzsCoreDB.ManaThreshold or 20)
    restSlider:SetValue(BadAzsCoreDB.RestHPThreshold or 90)
    emergencySlider:SetValue(BadAzsCoreDB.EmergencyHPThreshold or 30)
    targetSkipSlider:SetValue(BadAzsCoreDB.TargetLowHPSkip or 20)

    getglobal(hpSlider:GetName().."Text"):SetText(L.hpLabel .. ": " .. (BadAzsCoreDB.HPThreshold or 75))
    getglobal(manaSlider:GetName().."Text"):SetText(L.manaLabel .. ": " .. (BadAzsCoreDB.ManaThreshold or 20))
    getglobal(restSlider:GetName().."Text"):SetText(L.restLabel .. ": " .. (BadAzsCoreDB.RestHPThreshold or 90))
    getglobal(emergencySlider:GetName().."Text"):SetText(L.emergencyLabel .. ": " .. (BadAzsCoreDB.EmergencyHPThreshold or 30))
    getglobal(targetSkipSlider:GetName().."Text"):SetText(L.targetSkipLabel .. ": " .. (BadAzsCoreDB.TargetLowHPSkip or 20))

    explainEnable:SetText(L.explainEnable)
    explainHP:SetText(L.explainHP)
    explainMana:SetText(L.explainMana)
    explainRest:SetText(L.explainRest)
    explainEmergency:SetText(L.explainEmergency)
    explainTargetSkip:SetText(L.explainTargetSkip)

    cmdHeader:SetText("|cffffd200" .. L.cmdHeader .. "|r")
    local lines = ""
    local i
    for i = 1, table.getn(L.cmdList) do
        if i > 1 then lines = lines .. "\n" end
        lines = lines .. L.cmdList[i]
    end
    cmdText:SetText(lines)
end

langBtn:SetScript("OnClick", function()
    if BadAzsCoreDB.Locale == "EN" then BadAzsCoreDB.Locale = "PT" else BadAzsCoreDB.Locale = "EN" end
    BadAzsCore_RefreshPanel()
end)

Panel:SetScript("OnShow", function() BadAzsCore_RefreshPanel() end)

BadAzs_PanelRegistry = BadAzs_PanelRegistry or {}
BadAzs_PanelRegistry["core"] = function()
    if Panel:IsShown() then Panel:Hide() else Panel:Show() end
end
