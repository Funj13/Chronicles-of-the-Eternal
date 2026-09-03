// Fill out your copyright notice in the Description page of Project Settings.


#include "ConsoleManager.h"
#include "AC_Atributos.h"
#include "AC_Inventario.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/Pawn.h"

// Construtor
UConsoleManager::UConsoleManager()
{
	PrimaryComponentTick.bCanEverTick = false;
}

// Chamado no início do jogo
void UConsoleManager::BeginPlay()
{
	Super::BeginPlay();
}

// Função de entrada exposta para Blueprints
FString UConsoleManager::ExecuteConsoleCommand(const FString& RawInput)
{
	// 1. Limpa espaços adicionais do início e fim da string
	FString CleanInput = RawInput.TrimStartAndEnd();

	if (CleanInput.IsEmpty())
	{
		return TEXT("Console: Entrada de comando vazia.");
	}

	// 2. Remove a barra '/' inicial se o desenvolvedor a incluiu (ex: "/xp add 100" -> "xp add 100")
	if (CleanInput.StartsWith(TEXT("/")))
	{
		CleanInput = CleanInput.RightChop(1);
	}

	// 3. Divide a string por espaços em branco, ignorando espaços repetidos (CullEmpty = true)
	TArray<FString> Tokens;
	CleanInput.ParseIntoArray(Tokens, TEXT(" "), true);

	if (Tokens.Num() == 0)
	{
		return TEXT("Console: Nenhum comando válido detectado.");
	}

	// 4. Identifica o comando primário de forma case-insensitive
	FString PrimaryCommand = Tokens[0].ToLower();

	// 5. Isola os argumentos restantes
	TArray<FString> CommandArgs;
	for (int32 i = 1; i < Tokens.Num(); ++i)
	{
		CommandArgs.Add(Tokens[i]);
	}

	// 6. Roteamento de comandos sem necessidade de componente de atributos (ex: help)
	if (PrimaryCommand == TEXT("help") || PrimaryCommand == TEXT("h") || PrimaryCommand == TEXT("?"))
	{
		return HandleHelpCommand();
	}

	// 7. Obtém o componente de atributos do personagem
	UAC_Atributos* Atributos = GetPlayerAttributes();
	if (!Atributos)
	{
		return TEXT("[Erro] Componente de Atributos (AC_Atributos) não encontrado no personagem controlado atual.");
	}

	// 8. Roteamento dos comandos dependentes de atributos
	if (PrimaryCommand == TEXT("xp"))
	{
		return HandleXPCommand(CommandArgs, Atributos);
	}
	else if (PrimaryCommand == TEXT("heal"))
	{
		return HandleHealCommand(CommandArgs, Atributos);
	}
	else if (PrimaryCommand == TEXT("mana"))
	{
		return HandleManaCommand(CommandArgs, Atributos);
	}
	else if (PrimaryCommand == TEXT("level") || PrimaryCommand == TEXT("lvl"))
	{
		return HandleLevelCommand(CommandArgs, Atributos);
	}
	else if (PrimaryCommand == TEXT("god") || PrimaryCommand == TEXT("godmode"))
	{
		return HandleGodCommand(CommandArgs, Atributos);
	}
	else if (PrimaryCommand == TEXT("save"))
	{
		bool bOk = Atributos->SalvarAtributos();
		return bOk ? TEXT("[Console] Progresso do jogo salvo com SUCESSO no disco!") : TEXT("[Erro] Falha ao salvar o jogo.");
	}
	else if (PrimaryCommand == TEXT("load"))
	{
		bool bOk = Atributos->CarregarAtributos();
		return bOk ? FString::Printf(TEXT("[Console] Progresso CARREGADO! Nível %d, HP %.1f / %.1f, Mana %.1f / %.1f, XP %.1f / %.1f"),
			Atributos->GetNivel(), Atributos->GetVidaAtual(), Atributos->GetVidaMax(), Atributos->GetManaAtual(), Atributos->GetManaMax(), Atributos->GetXPAtual(), Atributos->GetXPMax()) 
			: TEXT("[Console] Nenhum arquivo de save encontrado.");
	}
	else if (PrimaryCommand == TEXT("damage") || PrimaryCommand == TEXT("dano"))
	{
		if (CommandArgs.Num() == 0)
		{
			return TEXT("[Erro] Sintaxe incorreta. Use: /damage <quantidade>");
		}
		float Dano = FCString::Atof(*CommandArgs[0]);
		float Restante = Atributos->ReceberDano(Dano);
		return FString::Printf(TEXT("[Combate] Dano de %.1f aplicado! Vida Restante: %.1f / %.1f"), Dano, Restante, Atributos->GetVidaMax());
	}
	else if (PrimaryCommand == TEXT("item"))
	{
		if (CommandArgs.Num() == 0)
		{
			return TEXT("[Erro] Sintaxe incorreta. Use: /item add <id> [qtd], /item use <slot> ou /item clear.");
		}

		AActor* OwnerPawn = GetPlayerAttributes() ? GetPlayerAttributes()->GetOwner() : nullptr;
		UAC_Inventario* Inventario = OwnerPawn ? OwnerPawn->FindComponentByClass<UAC_Inventario>() : nullptr;
		if (!Inventario)
		{
			return TEXT("[Erro] Componente de Inventário (AC_Inventario) não encontrado no personagem.");
		}

		FString Action = CommandArgs[0].ToLower();
		if (Action == TEXT("add") && CommandArgs.Num() >= 2)
		{
			FName ItemTargetName = FName(*CommandArgs[1]);
			int32 Qtd = CommandArgs.Num() >= 3 ? FCString::Atoi(*CommandArgs[2]) : 1;

			FItemInventario ItemEncontrado;
			if (!Inventario->BuscarItemNaTabela(ItemTargetName, ItemEncontrado))
			{
				return FString::Printf(TEXT("[Erro] O item '%s' não existe na tabela DT_Items!"), *CommandArgs[1]);
			}

			bool bOk = Inventario->AdicionarItemPorID(ItemTargetName, Qtd);
			return bOk ? FString::Printf(TEXT("[Inventário] %dx de '%s' adicionado ao inventário!"), Qtd, *ItemEncontrado.NomeItem.ToString())
					   : TEXT("[Erro] Inventário cheio ou falha ao adicionar item.");
		}
		else if (Action == TEXT("use") && CommandArgs.Num() >= 2)
		{
			int32 SlotIdx = FCString::Atoi(*CommandArgs[1]);
			bool bOk = Inventario->UsarItemSlot(SlotIdx);
			return bOk ? FString::Printf(TEXT("[Inventário] Item do slot %d usado com sucesso!"), SlotIdx) : TEXT("[Erro] Falha ao usar item do slot.");
		}
		else if (Action == TEXT("equip") && CommandArgs.Num() >= 3)
		{
			int32 HotbarSlot = FCString::Atoi(*CommandArgs[1]) - 1; // converte de 1-6 para 0-5
			FString ItemID = CommandArgs[2];
			bool bOk = Inventario->EquiparHotbar(HotbarSlot, ItemID);
			return bOk ? FString::Printf(TEXT("[Hotbar] Item '%s' equipado na Tecla %d!"), *ItemID, HotbarSlot + 1)
					   : TEXT("[Erro] Falha ao equipar item na Hotbar.");
		}
		else if (Action == TEXT("clear"))
		{
			Inventario->LimparInventario();
			return TEXT("[Inventário] Inventário limpo.");
		}
	}
	else if (PrimaryCommand == TEXT("hotbar"))
	{
		if (CommandArgs.Num() == 0)
		{
			return TEXT("[Erro] Sintaxe: /hotbar <1-6> [use]");
		}

		AActor* OwnerPawn = GetPlayerAttributes() ? GetPlayerAttributes()->GetOwner() : nullptr;
		UAC_Inventario* Inventario = OwnerPawn ? OwnerPawn->FindComponentByClass<UAC_Inventario>() : nullptr;
		if (!Inventario)
		{
			return TEXT("[Erro] Componente de Inventário (AC_Inventario) não encontrado.");
		}

		int32 HotbarSlot = FCString::Atoi(*CommandArgs[0]) - 1;
		bool bOk = Inventario->UsarHotbar(HotbarSlot);
		return bOk ? FString::Printf(TEXT("[Hotbar] Atalho %d usado com sucesso!"), HotbarSlot + 1)
				   : FString::Printf(TEXT("[Erro] Nenhum item utilizável no atalho %d."), HotbarSlot + 1);
	}

	// Comando desconhecido
	return FString::Printf(TEXT("[Erro] Comando desconhecido: '%s'. Digite '/help' para obter assistência."), *PrimaryCommand);
}

// Obtém o componente de atributos de forma robusta e segura
UAC_Atributos* UConsoleManager::GetPlayerAttributes() const
{
	APawn* ControlledPawn = nullptr;

	// Tenta obter o Player Controller proprietário do componente
	if (APlayerController* PC = Cast<APlayerController>(GetOwner()))
	{
		ControlledPawn = PC->GetPawn();
	}
	// Se este componente estiver anexado diretamente a um Pawn/Character
	else
	{
		ControlledPawn = Cast<APawn>(GetOwner());
	}

	if (ControlledPawn)
	{
		// Procura o componente de atributos no Pawn
		return ControlledPawn->FindComponentByClass<UAC_Atributos>();
	}

	return nullptr;
}

// Tratamento do comando de XP (/xp add <valor>, /xp set <valor>)
FString UConsoleManager::HandleXPCommand(const TArray<FString>& Args, UAC_Atributos* Atributos)
{
	if (Args.Num() < 2)
	{
		return TEXT("[Erro] Uso incorreto. Sintaxe correta: /xp <add|set> <quantidade>");
	}

	FString SubCommand = Args[0].ToLower();
	float Value = FCString::Atof(*Args[1]);

	if (SubCommand == TEXT("add"))
	{
		if (Value < 0.f)
		{
			return TEXT("[Erro] Não é possível adicionar XP negativo. Use '/xp set' para definir valores baixos.");
		}
		Atributos->AdicionarXP(Value);
		return FString::Printf(TEXT("[Console] Adicionado %.1f de XP. Status: XP %.1f / %.1f (Nível %d)"), 
			Value, Atributos->GetXPAtual(), Atributos->GetXPMax(), Atributos->GetNivel());
	}
	else if (SubCommand == TEXT("set"))
	{
		if (Value < 0.f)
		{
			return TEXT("[Erro] O XP do personagem não pode ser negativo.");
		}
		Atributos->SetXP(Value);
		return FString::Printf(TEXT("[Console] XP definido para %.1f. Status: XP %.1f / %.1f (Nível %d)"), 
			Value, Atributos->GetXPAtual(), Atributos->GetXPMax(), Atributos->GetNivel());
	}

	return FString::Printf(TEXT("[Erro] Ação de XP desconhecida: '%s'. Use 'add' ou 'set'."), *SubCommand);
}

// Tratamento do comando de Cura (/heal, /heal full, /heal add <valor>, /heal set <valor>)
FString UConsoleManager::HandleHealCommand(const TArray<FString>& Args, UAC_Atributos* Atributos)
{
	// /heal ou /heal full (cura 100% de Vida e Mana)
	if (Args.Num() == 0 || (Args.Num() >= 1 && Args[0].ToLower() == TEXT("full")))
	{
		Atributos->Curar(0.f);
		return FString::Printf(TEXT("[Console] Cura Completa aplicada! Vida: %.1f / %.1f | Mana: %.1f / %.1f"),
			Atributos->GetVidaAtual(), Atributos->GetVidaMax(), Atributos->GetManaAtual(), Atributos->GetManaMax());
	}

	FString SubCommand = Args[0].ToLower();

	// /heal add <valor> (ou /heal <valor> direto)
	if (SubCommand == TEXT("add"))
	{
		if (Args.Num() < 2)
		{
			return TEXT("[Erro] Sintaxe incorreta. Use: /heal add <quantidade>");
		}
		float Value = FCString::Atof(*Args[1]);
		if (Value <= 0.f)
		{
			return TEXT("[Erro] O valor de cura precisa ser um número positivo.");
		}
		Atributos->Curar(Value);
		return FString::Printf(TEXT("[Console] Adicionado %.1f de cura. Vida: %.1f / %.1f"),
			Value, Atributos->GetVidaAtual(), Atributos->GetVidaMax());
	}
	// /heal set <valor>
	else if (SubCommand == TEXT("set"))
	{
		if (Args.Num() < 2)
		{
			return TEXT("[Erro] Sintaxe incorreta. Use: /heal set <quantidade>");
		}
		float Value = FCString::Atof(*Args[1]);
		if (Value < 0.f)
		{
			return TEXT("[Erro] A vida não pode ser definida para valores negativos.");
		}
		Atributos->SetVida(Value);
		return FString::Printf(TEXT("[Console] Vida definida para %.1f / %.1f"),
			Atributos->GetVidaAtual(), Atributos->GetVidaMax());
	}
	// Atalho direto de número: /heal <valor>
	else
	{
		float Value = FCString::Atof(*SubCommand);
		if (Value > 0.f)
		{
			Atributos->Curar(Value);
			return FString::Printf(TEXT("[Console] Curado em %.1f de vida. Vida: %.1f / %.1f"),
				Value, Atributos->GetVidaAtual(), Atributos->GetVidaMax());
		}
	}

	return TEXT("[Erro] Sintaxe de cura desconhecida. Use '/heal full', '/heal add <valor>' ou '/heal set <valor>'.");
}

// Tratamento do comando de Mana (/mana add <valor>, /mana set <valor>)
FString UConsoleManager::HandleManaCommand(const TArray<FString>& Args, UAC_Atributos* Atributos)
{
	if (Args.Num() < 2)
	{
		return TEXT("[Erro] Uso incorreto. Sintaxe correta: /mana <add|set> <quantidade>");
	}

	FString SubCommand = Args[0].ToLower();
	float Value = FCString::Atof(*Args[1]);

	if (SubCommand == TEXT("add"))
	{
		Atributos->ModificarMana(Value);
		return FString::Printf(TEXT("[Console] Mana alterada em %.1f. Mana Atual: %.1f / %.1f"), 
			Value, Atributos->GetManaAtual(), Atributos->GetManaMax());
	}
	else if (SubCommand == TEXT("set"))
	{
		if (Value < 0.f)
		{
			return TEXT("[Erro] A mana não pode ser definida para valores negativos.");
		}
		Atributos->SetMana(Value);
		return FString::Printf(TEXT("[Console] Mana definida para %.1f / %.1f"), 
			Atributos->GetManaAtual(), Atributos->GetManaMax());
	}

	return FString::Printf(TEXT("[Erro] Ação de Mana desconhecida: '%s'. Use 'add' ou 'set'."), *SubCommand);
}

// Tratamento do comando de Nível (/level <valor> ou /level set <valor>)
FString UConsoleManager::HandleLevelCommand(const TArray<FString>& Args, UAC_Atributos* Atributos)
{
	if (Args.Num() == 0)
	{
		return TEXT("[Erro] Uso incorreto. Sintaxe correta: /level <número> ou /level set <número>");
	}

	int32 TargetLevel = 1;

	// Suporta tanto "/level set 5" quanto "/level 5"
	if (Args.Num() >= 2 && Args[0].ToLower() == TEXT("set"))
	{
		TargetLevel = FCString::Atoi(*Args[1]);
	}
	else
	{
		TargetLevel = FCString::Atoi(*Args[0]);
	}

	if (TargetLevel < 1)
	{
		return TEXT("[Erro] O nível do personagem deve ser pelo menos 1.");
	}

	Atributos->SetNivel(TargetLevel);
	return FString::Printf(TEXT("[Console] Nível alterado para %d. Vida Máx aumentada para %.1f."), 
		Atributos->GetNivel(), Atributos->GetVidaMax());
}

// Tratamento do comando de Invencibilidade (/god)
FString UConsoleManager::HandleGodCommand(const TArray<FString>& Args, UAC_Atributos* Atributos)
{
	Atributos->ToggleGodMode();
	
	FString StateStr = Atributos->IsGodModeActive() ? TEXT("ATIVADO") : TEXT("DESATIVADO");
	return FString::Printf(TEXT("[Console] God Mode %s!"), *StateStr);
}

// Lista os comandos disponíveis no console
FString UConsoleManager::HandleHelpCommand()
{
	return TEXT("================ Comandos de Desenvolvedor ================\n"
				"  /heal [full|add|set]    - Cura o herói. Ex: /heal full, /heal add 50, /heal set 100\n"
				"  /xp <add|set> <valor>   - Adiciona ou define a experiência (XP). Escala 1.5x por nível.\n"
				"  /mana <add|set> <valor> - Adiciona ou define o valor da Mana do herói.\n"
				"  /level <valor>          - Altera o nível do herói (Limite: Nível 99).\n"
				"  /god                    - Alterna o modo imortalidade (God Mode).\n"
				"  /save                   - Salva o progresso e atributos do herói no disco.\n"
				"  /load                   - Carrega o progresso salvo do herói do disco.\n"
				"  /help                   - Exibe este menu de documentação de comandos.\n"
				"===========================================================");
}
