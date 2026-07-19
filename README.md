# [B]adAzs CORE

**Battle Analysis Driven Assistant Zmart System ** <br> 
*Vanilla / Classic WoW Edition – Global Attack API*
<a href="https://www.paypal.com/donate/?hosted_button_id=VLAFP6ZT8ATGU">
  <img src="https://github.com/ThePeregris/MainAssets/blob/main/Donate_PayPal.png" alt="Tips Appreciated!" align="right" width="120" height="75">
</a>
<br><br><br>
<hr>

# BadAzs Core

Módulo base do conjunto de addons **BadAzs**, feito para **Vanilla/Classic WoW (cliente 1.12 / Lua 5.0)**.
Concentra só as funções **universais** — que qualquer classe usa — para que os addons de cada classe (`BadAzsWarrior`, `BadAzsPaladin`, `BadAzsPriest`, ...) fiquem enxutos e independentes entre si.

> Este addon **precisa estar habilitado** para qualquer outro addon `BadAzs*` funcionar.

## Instalação

Copie a pasta inteira para `Interface/AddOns/`, mantendo o nome:

```
AddOns/
  BadAzsCore/
    BadAzsCore.toc
    BadAzsCore.lua
```

## O que vive aqui (e por quê)

A regra do projeto: se a lógica é específica de uma classe (rotação, seleção de spell, checagem de buff/debuff de combate), ela mora dentro do addon daquela classe. Se é algo que **qualquer** addon poderia precisar, mora aqui.

### 1. Mouseover manual (`/bamo`)

`BadAzs_ManualMouseover(spellName, doAssist)` — lança uma spell em quem está sob o mouse **sem perder o seu alvo atual** (troca, casta, e volta pro target de antes). Usado internamente pelos smart-buffs do Paladin e do Priest, mas também dá pra chamar direto:

```
/bamo Power Word: Fortitude
/bamo Polymorph assist      -- lança e assiste o alvo do mouseover
```

### 2. Sistema de Focus

| Comando | O que faz |
|---|---|
| `/bafocus` | Define o Focus (prioriza mouseover; senão usa o target atual) |
| `/baclear` | Limpa o Focus |
| `/baassist` | Assiste o alvo do Focus |
| `/baffollow` | Segue o Focus |

Guardado só em memória (`BadAzs_FocusName`), reseta ao relogar — é intencional, evita seguir/assistir alguém que já saiu do grupo.

### 3. Vision (`/bavis`)

Ajusta câmera (`cameraDistanceMax`, `nameplateDistance`) pra uma visão mais confortável de combate. Roda automaticamente uma vez ao entrar no mundo.

### 4. Sustain — poções, healthstone e bandagens (`/basustain`)

`BadAzs_Sustain()` é chamado **automaticamente** no início de toda rotação dos addons de classe (Warrior, Paladin, Priest). Baseado no addon [BannionNurse](https://github.com/ThePeregris/BannionNurse), com poção de mana adicionada (o original não tinha):

- **Em combate:** HP ≤ limiar → Healthstone, senão poção de heal. Mana ≤ limiar → poção de mana, senão Demonic Rune.
- **Fora de combate:** HP ≤ limiar → aplica bandagem (verifica se já não tem o debuff de bandagem ativo antes).
- **Segurando ALT:** cast manual de First Aid (fora de combate).
- Undead: `Cannibalize` automático fora de combate se HP baixo (corrigido nessa versão — o BannionNurse original chamava isso *durante* combate, onde a spell nunca funciona).

Limiares em `BadAzsCoreDB` (`HPThreshold`, `ManaThreshold`, `RestHPThreshold`) — ainda sem painel gráfico próprio, ajustáveis só editando a SavedVariable por enquanto.

### 5. Roteador de painéis (`/badazs`)

Dono único do slash `/badazs`. Cada addon de classe se registra aqui em vez de reivindicar o comando sozinho — evita que dois addons carregados brigem pelo mesmo slash e um "roube" o comando do outro silenciosamente:

```lua
BadAzs_PanelRegistry["warrior"] = function() ... end
```

| Comando | Abre |
|---|---|
| `/badazs warrior` | Painel do Warrior |
| `/badazs pally` | Painel do Paladin |
| `/badazs priest holy` \| `disc` \| `shadow` | Painéis do Priest |

### 6. Funções de combate reutilizáveis

Ainda expostas globalmente pra qualquer addon usar, embora Warrior/Paladin/Priest já tenham suas próprias cópias internas (self-sufficient) por preferirem não depender do Core pra isso:

`BadAzs_Cast`, `BadAzs_GetTargetHP`, `BadAzs_GetMana`, `BadAzs_FindSpellId`, `BadAzs_Ready`, `BadAzs_HasBuff`, `BadAzs_TargetHasDebuff`, `BadAzs_UseItem`.

## SavedVariables

- `BadAzsCoreDB.SustainEnabled` — booleano, liga/desliga o Sustain
- `BadAzsCoreDB.HPThreshold` — % de HP pra usar heal/stone em combate (padrão 75)
- `BadAzsCoreDB.ManaThreshold` — % de mana pra usar poção de mana (padrão 20)
- `BadAzsCoreDB.RestHPThreshold` — % de HP pra bandagem fora de combate (padrão 90)

## Bugs corrigidos nesta versão

- `## SavedVariables` estava **ausente** do `.toc` — `BadAzsCoreDB` nunca era salvo entre sessões.
- `SLASH_BACLEAR1` apontava pra `BadAzs_ClearFocus`, que nunca tinha sido definida — `/baclear` não fazia nada.
- Slash principal corrigido de `/badasz` (typo) para `/badazs` (batendo com o nome `BadAzs`).

## Changelog

- **v2.5** — Módulo Sustain (poções/stones/bandagens), roteador de painéis `/badazs`, correção do `SavedVariables` e do `BadAzs_ClearFocus`.
- **v2.4** — (interno, absorvido pela v2.5)
- **v2.3** — Core genérico: mouseover manual, focus, vision.
