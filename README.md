# [B]adAzs CORE – GLOBAL COMBAT FOUNDATION (v1.4)

**Battle Analysis Driven Assistant Zmart System – Core Layer**
*Turtle WoW Edition – Global Attack API*
<a href="https://www.paypal.com/donate/?hosted_button_id=VLAFP6ZT8ATGU">
  <img src="https://github.com/ThePeregris/MainAssets/blob/main/Donate_PayPal.png" alt="Tips Appreciated!" align="right" width="120" height="75">
</a>

## 1. TECHNICAL MANIFESTO | BadAzs CORE

**Version:** v1.4
**Target:** Turtle WoW (Client 1.12.x – LUA 5.0)
**Architecture:** Global Utility Core + Combat State API
**Author:** **ThePeregris**

O **BadAzs CORE** é a **camada fundamental** do ecossistema BadAzs.
Ele não executa rotações nem decisões de classe — ele fornece **infraestrutura confiável**, **estado global de combate** e **utilidades universais** que outros módulos (Warrior, Rogue, Mage, etc.) podem usar com segurança.

✔️ Leve
✔️ Modular
✔️ Zero dependências obrigatórias
✔️ Compatível com qualquer classe

---

## 2. CORE SYSTEMS OVERVIEW

### ⚔️ Global Auto-Attack API

O CORE expõe uma função única e segura:

```lua
BadAzs_StartAttack()
```

Ela garante:

* Nenhum spam de `AttackTarget()`
* Sincronização com o estado real de combate
* Controle visual correto (espadas cruzadas)
* Compatibilidade total com o Core do Turtle WoW

📌 O estado é mantido por:

```
BadAzs_IsAttacking (true / false)
```

Esse valor é atualizado automaticamente via eventos:

* `PLAYER_ENTER_COMBAT`
* `PLAYER_LEAVE_COMBAT`

---

## 3. FOCUS SYSTEM (Target Intelligence)

O CORE implementa um **sistema de Focus leve**, independente do sistema moderno do WoW.

### 🎯 Definição de Focus

A prioridade é inteligente:

1. **Mouseover** (Tooltip ativo)
2. **Target atual**
3. Nenhum alvo → Focus limpo

```text
/badfocus
```

📌 O Focus armazena **apenas o nome da unidade**, garantindo:

* Baixo custo
* Compatibilidade com Vanilla
* Uso simples por outros scripts

---

### ❌ Limpeza de Focus

```text
/badclear
```

Remove qualquer foco ativo e notifica no chat.

---

## 4. MOUSEOVER TRACKER

O CORE intercepta o `GameTooltip` para rastrear unidades sob o mouse:

* Atualiza `BadAzs_MouseoverUnit`
* Limpa automaticamente ao sair do tooltip
* Não interfere em addons de tooltip

📌 Esse sistema permite:

* Focus inteligente
* Futuras lógicas de CC, heal ou dispel por mouseover
* Zero impacto de performance

---

## 5. VISION MODULE (Camera & Nameplates)

O **Vision Module** ajusta CVars críticos para combate moderno no Vanilla:

```text
/badvis
```

### Configurações aplicadas:

* `cameraDistanceMax = 50`
* `cameraDistanceMaxFactor = 2`
* `nameplateDistance = 41`
* Aplica `View 4` duas vezes (garantia)

✔️ Uso de `pcall()` para evitar erros
✔️ Seguro contra CVars bloqueadas
✔️ Executado automaticamente ao entrar no mundo

---

## 6. UNIVERSAL RACIAL ENGINE

O CORE detecta automaticamente a raça do jogador e utiliza o racial correto:

| Raça      | Habilidade           |
| --------- | -------------------- |
| Human     | Perception           |
| Orc       | Blood Fury           |
| Troll     | Berserking           |
| Undead    | Will of the Forsaken |
| Dwarf     | Stoneform            |
| Gnome     | Escape Artist        |
| Night Elf | Shadowmeld           |
| Tauren    | War Stomp            |
| Goblin    | Rocket Barrage       |
| High Elf  | Mana Tap             |

📌 O sistema:

* Escaneia o Spellbook
* Não depende de IDs fixos
* É compatível com raças custom do Turtle WoW

```lua
BadAzs_UseRacial()
```

---

## 7. ITEMRACK WRAPPER (Opcional)

Wrapper universal para **ItemRack**, compatível com ambas APIs conhecidas:

```lua
BadAzs_EquipSet("NOME_DO_SET")
```

Compatível com:

* `ItemRack_EquipSet`
* `ItemRack.EquipSet`

📌 Se ItemRack não estiver instalado, a função falha silenciosamente.

---

## 8. SLASH COMMANDS

| Comando     | Função                            |
| ----------- | --------------------------------- |
| `/badfocus` | Define Focus (mouseover > target) |
| `/badclear` | Limpa o Focus                     |
| `/badvis`   | Aplica Vision Module              |

---

## 9. AUTO-INIT & DEBUG

### Inicialização Automática

Ao entrar no mundo:

* Vision Module é aplicado automaticamente
* CORE é carregado silenciosamente

### Debug Mode

```lua
BadAzs_Debug = true
```

Quando ativo:

* Mensagens de estado são exibidas no chat
* Útil para desenvolvimento e integração com outros módulos

---

## FILOSOFIA BADAZS CORE

> **Sem decisões.
> Sem rotação.
> Apenas fundação sólida.**

O **BadAzs CORE** existe para garantir que **outros scripts nunca precisem reinventar a roda**.

---

**BadAzs CORE v1.4**
*Uma base estável é invisível — até faltar.*

