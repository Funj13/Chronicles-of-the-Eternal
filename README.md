<div align="center">

![Banner Chronicles of the Eternal](https://github.com/user-attachments/assets/534efad7-96fc-49cc-8d94-0c6d90fb8d1a)

# ⚔️ Chronicles of the Eternal
### Um RPG de Ação 3D desenvolvido na Godot Engine 4

![Badge em Desenvolvimento](https://img.shields.io/badge/Status-Abandonado-yellow?style=for-the-badge)
![Badge Godot](https://img.shields.io/badge/Engine-Godot_4-blue?style=for-the-badge&logo=godot-engine)
![Badge Versão](https://img.shields.io/badge/Versão_Atual-v6.8_Alpha-orange?style=for-the-badge)

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
**Chronicles of the Eternal** é um projeto de RPG de ação em terceira pessoa, focado em criar uma experiência imersiva com estilo visual de Anime. O jogo estava sendo construído do zero utilizando a **Godot Engine 4**, com o objetivo de documentar e aprimorar habilidades em desenvolvimento de jogos, design de sistemas e lógica de programação.

Após alguns meses de trabalho CLT e muita dedicação na faculdade, montei um PC gamer para voltar ao desenvolvimento em uma engine mais parruda. Agora o jogo está sendo refeito dentro da Unreal Engine 5.

Este repositório serve como um **Devlog (Diário de Desenvolvimento)** e documentação das atualizações.

### ✨ Novas Funcionalidades (v6.0-Alpha)

#### 🎒 Inventory UI 2.0 (Visual Overhaul)
<img width="628" height="452" alt="image" src="https://github.com/user-attachments/assets/0016b84e-5e62-4aac-ae5d-c37b2ccee8d6" />

- **Estética "Tech-Ruins":** Nova paleta de cores baseada em equipamentos militares antigos e interfaces digitais desgastadas.
- **Painel de Detalhes Dinâmico:** Ao clicar em um item, o painel lateral exibe:
  - Ícone em alta resolução (Preparado para visualização 3D/Holográfica).
  - Descrição completa com *text wrapping* automático.
  - Botões de ação contextuais.
- **Lógica de Botões Inteligentes:**
  - O botão de ação muda dinamicamente entre **"Equipar"**, **"Desequipar"** e **"Usar"** baseando-se no tipo do item (Arma vs Consumível) e no estado atual do Player.
<img width="818" height="451" alt="image" src="https://github.com/user-attachments/assets/64c27a99-ef2b-4896-bee0-a90491439ca1" />




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
- **Novo Inimigo (Zumbi):** Implementação do primeiro mob hostil utilizando modelo estilo Anime (VRoid).

- **Sistema de IA Básica:** Inimigo persegue o jogador quando detectado e possui física de gravidade.
- **Sistema de Dano Real:**
  - Implementação de **Hitbox** (Espada) e **Hurtbox** (Inimigo).
  - Feedback visual e físico (Knockback) ao acertar o inimigo.
- **Animações Reativas:**
  - Máquina de estados para: `Idle` (Parado), `Run` (Perseguição), `Hit` (Dano) e `Death` (Morte).
  - Integração de animações Mixamo com esqueleto VRoid via BoneMap.
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
- [x] Tooltip (Informação de Itens)
- [x] Inimigos e IA Básica
- [ ] **Sistema de Quests** 🚧 *Em Breve*
- [ ] **Save/Load System** 🚧 *Em Breve*

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
