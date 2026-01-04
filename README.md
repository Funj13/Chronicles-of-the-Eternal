<div align="center">

![Banner Chronicles of the Eternal](https://github.com/user-attachments/assets/534efad7-96fc-49cc-8d94-0c6d90fb8d1a)

# ⚔️ Chronicles of the Eternal
### Um RPG de Ação 3D desenvolvido na Godot Engine 4

![Badge em Desenvolvimento](https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow?style=for-the-badge)
![Badge Godot](https://img.shields.io/badge/Engine-Godot_4-blue?style=for-the-badge&logo=godot-engine)
![Badge Versão](https://img.shields.io/badge/Versão_Atual-v4.5_Alpha-orange?style=for-the-badge)

<br />

**[ 📥 BAIXAR ÚLTIMA VERSÃO (Releases) ](https://github.com/Funj13/Chronicles-of-the-Eternal/releases)**
<br />

> 📢 **Ajude a criar o jogo!**
> **[ 📝 CLIQUE AQUI PARA RESPONDER A PESQUISA DE OPINIÃO ](https://forms.gle/9UvjRowauLskvrHAA)**

<br />
_(Clique acima para ver o histórico de versões e links de download)_

</div>

---

## 📜 Sobre o Projeto
**Chronicles of the Eternal** é um projeto de RPG de ação em terceira pessoa, focado em criar uma experiência imersiva com estilo visual de Anime. O jogo está sendo construído do zero utilizando a **Godot Engine 4**, com o objetivo de documentar e aprimorar habilidades em desenvolvimento de jogos, design de sistemas e lógica de programação.

Este repositório serve como um **Devlog (Diário de Desenvolvimento)** e documentação das atualizações.

### ✨ Novas Funcionalidades (v5.0-Alpha)
- **Novo Inimigo (Zumbi):** Implementação do primeiro mob hostil utilizando modelo estilo Anime (VRoid).
<img width="903" height="483" alt="image" src="https://github.com/user-attachments/assets/edbb5b5c-db5e-4fa0-b5ad-0a08140628a5" />

- **Sistema de IA Básica:** Inimigo persegue o jogador quando detectado e possui física de gravidade.
- **Sistema de Dano Real:**
  - Implementação de **Hitbox** (Espada) e **Hurtbox** (Inimigo).
  - Feedback visual e físico (Knockback) ao acertar o inimigo.
  
![gif-attack ‐ Feito com o Clipchamp](https://github.com/user-attachments/assets/c133b843-60b4-4f01-854e-547593b7b854)

- **Animações Reativas:**
  - Máquina de estados para: `Idle` (Parado), `Run` (Perseguição), `Hit` (Dano) e `Death` (Morte).
  - Integração de animações Mixamo com esqueleto VRoid via BoneMap.
 
![gif-death ‐ Feito com o Clipchamp](https://github.com/user-attachments/assets/ebd939f9-3034-4f2d-8cce-a49b69639c7a)


### 🛠️ Melhorias Técnicas
- **Refatoração de Colisão:** Ajuste nas *Collision Layers* para evitar que o Player cause dano a si mesmo.
- **Pipeline de Importação:** Correção de *Retargeting* de ossos para compatibilidade Godot 4 Humanoid.


## ✨ Funcionalidades Atuais
O jogo está em estágio **Alpha**, com as seguintes mecânicas já implementadas:

### 🎒 Sistema de Inventário & Loot (v4.5-Alpha)
- **Inventário em Grade:** Interface visual (UI) responsiva com slots.
- **Física de Itens:** Drop real de itens no mundo 3D (clique direito para jogar no chão).
- **Stacking:** Itens consumíveis (poções) se acumulam no mesmo slot.
- **Interação:** Baús que podem conter Ouro, XP e Itens variados.

### ⚔️ Combate & Equipamentos
- **Sistema de Equipar:** Visualização em tempo real de armas nas costas e nas mãos.
- **Toggle Inteligente:** Lógica para equipar/desequipar e trocar armas rapidamente.
- **Consumíveis:** Poções de vida funcionais que curam o personagem.

### 🎮 Gameplay Core
- **Movimentação:** Controle em terceira pessoa fluido.
- **HUD:** Interface de usuário com barras de Vida, XP e Ouro.

---

## 📸 Galeria (Devlog)

| Menu Inicial | Loading |
| :---: | :---: |
| ![Menu](https://github.com/user-attachments/assets/af7a7c7e-9996-4213-b808-ebde30e38820) | ![Loading](https://github.com/user-attachments/assets/401ec730-8713-4b04-9622-8e5c802bf2f8) |

---

## 🚀 Roadmap (Próximos Passos)

- [x] Movimentação Básica e Câmera
- [x] Sistema de UI e Menu Principal
- [x] Inventário Completo e Loot
- [ ] **Tooltip (Informação de Itens)** 🚧 *Em Breve*
- [x] **Inimigos e IA Básica** 🚧 *Em Breve*
- [ ] Sistema de Quests
- [ ] Save/Load System

---

## 🛠️ Tecnologias Utilizadas
* **Engine:** Godot 4.5
* **Linguagem:** GDScript
* **Modelagem/Assets:** Sloyd AI, Blender
* **Controle de Versão:** Git & GitHub

---

<div align="center">
    Developed with ❤️ by Funj13
</div>
