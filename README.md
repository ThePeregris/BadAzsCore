# [B]adAzs CORE – GLOBAL COMBAT FOUNDATION (v1.6)

**Battle Analysis Driven Assistant Zmart System – Core Layer** *Turtle WoW Edition – Global Attack API*
<a href="https://www.paypal.com/donate/?hosted_button_id=VLAFP6ZT8ATGU">
  <img src="https://github.com/ThePeregris/MainAssets/blob/main/Donate_PayPal.png" alt="Tips Appreciated!" align="right" width="120" height="75">
</a>

## 1. TECHNICAL MANIFESTO | BadAzs CORE

**Version:** v1.6

**Target:** Turtle WoW (Client 1.12.x – LUA 5.0)

**Architecture:** Global Utility Core + Combat State API

**Author:** **ThePeregris**

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
