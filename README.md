# [B]adAzs CORE – GLOBAL COMBAT FOUNDATION (v1.6)

**Battle Analysis Driven Assistant Zmart System – Core Layer**  
*Turtle WoW Edition – Global Attack API*
<a href="https://www.paypal.com/donate/?hosted_button_id=VLAFP6ZT8ATGU">
  <img src="https://github.com/ThePeregris/MainAssets/blob/main/Donate_PayPal.png" alt="Tips Appreciated!" align="right" width="120" height="75">
</a>

## 1. TECHNICAL MANIFESTO | BadAzs CORE

**Version:** v1.6

**Target:** Turtle WoW (Client 1.12.x – LUA 5.0)

**Architecture:** Global Utility Core + Combat State API

**Author:** **ThePeregris**

The **BadAzs CORE** is the **fundamental layer** of the BadAzs ecosystem. It does not execute rotations or class-specific decisions—instead, it provides **reliable infrastructure**, **global combat state**, and **universal utilities** that other modules (Warrior, Rogue, Paladin, etc.) can use securely.

✔️ Lightweight

✔️ Modular

✔️ Zero mandatory dependencies

✔️ Compatible with any class

✔️ Built-in protection against missing addons (e.g., ItemRack)

---

## 2. CORE SYSTEMS OVERVIEW

### ⚔️ Global Auto-Attack API

The CORE exposes a single, secure function:

```lua
BadAzs_StartAttack()

```

It ensures:

* No `AttackTarget()` spamming (prevents accidental "toggle-off").
* Full synchronization with the actual combat state.
* Correct visual feedback (crossed swords).
* Total compatibility with Turtle WoW’s core mechanics.

📌 State is maintained by:
`BadAzs_IsAttacking (true / false)`

This value updates automatically via events: `PLAYER_ENTER_COMBAT` & `PLAYER_LEAVE_COMBAT`.

---

## 3. FOCUS SYSTEM (Target Intelligence)

The CORE implements a **lightweight Focus system**, independent of the modern WoW focus frame.

### 🎯 Setting Focus

Priority-based logic:

1. **Current Target** (Standard 1.12 stable method)
2. No target → Focus cleared

```text
/badfocus

```

📌 The Focus stores **only the unit name**, ensuring:

* Low memory footprint.
* Vanilla compatibility.
* Easy implementation for other scripts.

### ❌ Clearing Focus

```text
/badclear

```

Removes any active focus and notifies the chat.

### 🤝 Assist & Follow

New specialized commands for focus-based utility:

* **/focusassist**: Targets your focus's current target.
* **/focusfollow**: Commences following your focus unit.

---

## 4. VISION MODULE (Camera & Nameplates)

The **Vision Module** adjusts critical CVars for a modern combat experience in Vanilla:

```text
/badvis

```

### Applied Settings:

* `cameraDistanceMax = 50`
* `cameraDistanceMaxFactor = 2`
* `nameplateDistance = 41`
* Executes `SetView(4)` twice for guaranteed application.

✔️ Uses `pcall()` to prevent errors.

✔️ Safe against locked CVars.

✔️ Automatically executed upon entering the world.

---

## 5. UNIVERSAL RACIAL ENGINE

The CORE automatically detects the player's race and casts the correct racial ability:

| Race | Ability |
| --- | --- |
| Human | Perception |
| Orc | Blood Fury |
| Troll | Berserking |
| Undead | Will of the Forsaken |
| Dwarf | Stoneform |
| Gnome | Escape Artist |
| Night Elf | Shadowmeld |
| Tauren | War Stomp |
| Goblin | Rocket Barrage |
| High Elf | Mana Tap |

```lua
BadAzs_UseRacial()

```

---

## 6. ITEMRACK WRAPPER (Optional)

A universal wrapper for **ItemRack**, compatible with both known APIs:

```lua
BadAzs_EquipSet("SET_NAME")

```

📌 If ItemRack is not installed, the function **fails silently**, allowing the rest of your macro/script to continue without errors.

---

## 7. SLASH COMMANDS

| Command | Function |
| --- | --- |
| `/badfocus` | Sets Focus to current target |
| `/badclear` | Clears active Focus |
| `/focusassist` | Assists the Focus unit |
| `/focusfollow` | Follows the Focus unit |
| `/badvis` | Applies Vision Module settings |

---

## 8. AUTO-INIT & DEBUG

### Automatic Initialization

Upon entering the world:

* Vision Module is automatically applied.
* CORE is loaded silently.

### Debug Mode

`BadAzs_Debug = true`

When active, state messages are displayed in the chat—useful for development and module integration.

---

## BADAZS CORE PHILOSOPHY

> **"No decisions. No rotation. Just a solid foundation."**

The **BadAzs CORE** exists to ensure that **other scripts never need to reinvent the wheel.**

---

**BadAzs CORE v1.6** *A stable foundation is invisible—until it’s gone.*

---
# PR-BR
---

O **BadAzs CORE** é a **camada fundamental** do ecossistema BadAzs. Ele fornece a infraestrutura confiável e o estado global de combate que módulos específicos (como o **Lunaty**) utilizam para operar com máxima performance e zero erros de script.

✔️ Leve & Modular

✔️ Zero dependências obrigatórias

✔️ Compatível com todas as classes

✔️ Proteção contra erros de ItemRack/Addons ausentes

---

## 2. CORE SYSTEMS OVERVIEW

### ⚔️ Global Auto-Attack API

O CORE expõe uma função inteligente que evita o "toggle off" (desligar o ataque por erro de clique):

```lua
BadAzs_StartAttack()

```

* Sincroniza o estado real de combate via eventos (`PLAYER_ENTER_COMBAT`).
* Mantém o valor global: `BadAzs_IsAttacking (true / false)`.

---

## 3. FOCUS SYSTEM (Target Intelligence)

O sistema de Focus v1.6 foi otimizado para ser estável tanto em UnitFrames quanto em alvos diretos.

| Comando | Função |
| --- | --- |
| **`/badfocus`** | Define o Focus no seu alvo atual. |
| **`/badclear`** | Limpa o foco e notifica no chat. |
| **`/focusassist`** | Assiste (pega o alvo) de quem está no seu Focus. |
| **`/focusfollow`** | Segue automaticamente o personagem em Focus. |

---

## 4. VISION MODULE (Camera & Nameplates)

Ajusta as variáveis de ambiente (CVars) para uma experiência de combate moderna:

```text
/badvis

```

* **Camera Max:** 50 metros | **Nameplates:** 41 metros.
* Executado automaticamente ao logar para garantir visibilidade máxima.

---

## 5. UNIVERSAL RACIAL ENGINE

Detecta e utiliza o racial da sua raça atual, incluindo as raças exclusivas do **Turtle WoW**.

* **Suporte:** Human, Orc, Troll, Undead, Dwarf, Gnome, Night Elf, Tauren, **Goblin** e **High Elf**.
* Chamada simples: `BadAzs_UseRacial()`.

---

## 6. SLASH COMMANDS QUICK REFERENCE

| Comando | Categoria | Descrição |
| --- | --- | --- |
| `/badfocus` | Focus | Define Focus no Alvo. |
| `/badclear` | Focus | Limpa o Focus ativo. |
| `/focusassist` | Utility | Assiste o alvo do Focus. |
| `/focusfollow` | Utility | Segue o Focus. |
| `/badvis` | Vision | Reseta Câmera e Nameplates. |

---

## 7. INTEGRAÇÃO & DESENVOLVIMENTO

O Core é projetado para ser "silencioso". Ele não polui o seu chat a menos que o modo de Debug esteja ativo:

```lua
BadAzs_Debug = true

```

---

> **"Uma base sólida é invisível — até faltar."**
> O BadAzs CORE garante que você foque no combate, enquanto ele cuida da mecânica do jogo.

---
**BadAzs CORE v1.6**
