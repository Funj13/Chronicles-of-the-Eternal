// Fill out your copyright notice in the Description page of Project Settings.


#include "AC_Atributos.h"
#include "SaveGame_Chronicles.h"
#include "AC_Inventario.h"
#include "Kismet/GameplayStatics.h"

// Define valores padrão para o construtor
UAC_Atributos::UAC_Atributos()
{
	PrimaryComponentTick.bCanEverTick = false;

	// Inicialização padrão dos atributos
	VidaMax = 100.0f;
	VidaAtual = 100.0f;
	ManaMax = 80.0f;
	ManaAtual = 80.0f;
	Nivel = 1;
	XPAtual = 0.0f;
	XPMax = 100.0f;
	bGodMode = false;
	bEstaMorto = false;
}

// Chamado quando o jogo começa
void UAC_Atributos::BeginPlay()
{
	Super::BeginPlay();

	// Tenta carregar automaticamente o progresso salvo do jogador
	CarregarAtributos();
}

// Aplica dano ao personagem (respeitando God Mode). Retorna a vida restante.
float UAC_Atributos::ReceberDano(float QuantidadeDano, AActor* Atacante)
{
	if (QuantidadeDano <= 0.f || bEstaMorto)
	{
		return VidaAtual;
	}

	if (bGodMode)
	{
		UE_LOG(LogTemp, Warning, TEXT("[Combate] Dano de %.1f ignorado devido ao God Mode."), QuantidadeDano);
		return VidaAtual;
	}

	VidaAtual = FMath::Clamp(VidaAtual - QuantidadeDano, 0.f, VidaMax);
	OnVidaAlterada.Broadcast(VidaAtual, VidaMax);

	UE_LOG(LogTemp, Warning, TEXT("[Combate] Dano de %.1f recebido. Vida Restante: %.1f / %.1f"), QuantidadeDano, VidaAtual, VidaMax);

	if (VidaAtual <= 0.f)
	{
		bEstaMorto = true;
		OnPersonagemMorreu.Broadcast();
		UE_LOG(LogTemp, Error, TEXT("[Combate] O PERSONAGEM MORREU!"));
	}

	return VidaAtual;
}

// Cura o personagem. Se Valor <= 0, restaura tudo (Vida e Mana)
void UAC_Atributos::Curar(float Valor)
{
	if (Valor <= 0.f)
	{
		VidaAtual = VidaMax;
		ManaAtual = ManaMax;
		bEstaMorto = false;
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] Cura completa aplicada (Vida e Mana maximizadas)."));
	}
	else
	{
		VidaAtual = FMath::Clamp(VidaAtual + Valor, 0.f, VidaMax);
		if (VidaAtual > 0.f)
		{
			bEstaMorto = false;
		}
		UE_LOG(LogTemp, Log, TEXT("[Atributos] Cura de %.1f pontos aplicada. Vida Atual: %.1f"), Valor, VidaAtual);
	}

	OnVidaAlterada.Broadcast(VidaAtual, VidaMax);
	OnManaAlterada.Broadcast(ManaAtual, ManaMax);
}

// Modifica a vida atual diretamente (recebe valores positivos ou negativos)
void UAC_Atributos::ModificarVida(float Valor)
{
	if (Valor < 0.f && bGodMode)
	{
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] Dano de %.1f ignorado devido ao God Mode."), -Valor);
		return;
	}

	VidaAtual = FMath::Clamp(VidaAtual + Valor, 0.f, VidaMax);
	if (VidaAtual > 0.f)
	{
		bEstaMorto = false;
	}

	OnVidaAlterada.Broadcast(VidaAtual, VidaMax);
	UE_LOG(LogTemp, Log, TEXT("[Atributos] Vida modificada em %.1f. Vida Atual: %.1f / %.1f"), Valor, VidaAtual, VidaMax);
}

// Define a vida atual diretamente
void UAC_Atributos::SetVida(float NovaVida)
{
	VidaAtual = FMath::Clamp(NovaVida, 0.f, VidaMax);
	if (VidaAtual > 0.f)
	{
		bEstaMorto = false;
	}

	OnVidaAlterada.Broadcast(VidaAtual, VidaMax);
	UE_LOG(LogTemp, Log, TEXT("[Atributos] Vida definida diretamente para: %.1f / %.1f"), VidaAtual, VidaMax);
}

// Modifica a mana atual diretamente
void UAC_Atributos::ModificarMana(float Valor)
{
	ManaAtual = FMath::Clamp(ManaAtual + Valor, 0.f, ManaMax);
	OnManaAlterada.Broadcast(ManaAtual, ManaMax);
	UE_LOG(LogTemp, Log, TEXT("[Atributos] Mana modificada em %.1f. Mana Atual: %.1f / %.1f"), Valor, ManaAtual, ManaMax);
}

// Adiciona uma quantidade de XP, tratando lógica de Level Up e limite de Nível 99
void UAC_Atributos::AdicionarXP(float Quantidade)
{
	if (Quantidade <= 0.f)
	{
		return;
	}

	if (Nivel >= 99)
	{
		Nivel = 99;
		XPAtual = XPMax;
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] Nível máximo 99 já atingido. XP não acumulado."));
		return;
	}

	XPAtual += Quantidade;
	UE_LOG(LogTemp, Log, TEXT("[Atributos] XP adicionado: +%.1f. XP Atual: %.1f / %.1f"), Quantidade, XPAtual, XPMax);

	while (XPAtual >= XPMax && Nivel < 99)
	{
		ProcessarLevelUp();
	}

	if (Nivel >= 99)
	{
		Nivel = 99;
		XPAtual = XPMax;
	}
}

// Define o XP atual diretamente
void UAC_Atributos::SetXP(float NovoXP)
{
	XPAtual = FMath::Clamp(NovoXP, 0.f, XPMax);
	UE_LOG(LogTemp, Log, TEXT("[Atributos] XP definido diretamente para: %.1f"), XPAtual);
}

// Define a mana atual diretamente
void UAC_Atributos::SetMana(float NovaMana)
{
	ManaAtual = FMath::Clamp(NovaMana, 0.f, ManaMax);
	OnManaAlterada.Broadcast(ManaAtual, ManaMax);
	UE_LOG(LogTemp, Log, TEXT("[Atributos] Mana definida diretamente para: %.1f"), ManaAtual);
}

// Define o Nível diretamente (com Hardcap de Nível 99)
void UAC_Atributos::SetNivel(int32 NovoNivel)
{
	Nivel = FMath::Clamp(NovoNivel, 1, 99);
	XPMax = 100.0f * FMath::Pow(1.5f, static_cast<float>(Nivel - 1));

	if (Nivel >= 99)
	{
		XPAtual = XPMax;
	}
	else
	{
		XPAtual = FMath::Clamp(XPAtual, 0.f, XPMax);
	}
	
	OnLevelUp.Broadcast(Nivel, XPMax);
	UE_LOG(LogTemp, Log, TEXT("[Atributos] Nível definido diretamente para %d. Novo XPMax (1.5x): %.1f"), Nivel, XPMax);
}

// Alterna o estado do modo God (Imortal)
void UAC_Atributos::ToggleGodMode()
{
	bGodMode = !bGodMode;
	
	if (bGodMode)
	{
		VidaAtual = VidaMax;
		ManaAtual = ManaMax;
		bEstaMorto = false;
		OnVidaAlterada.Broadcast(VidaAtual, VidaMax);
		OnManaAlterada.Broadcast(ManaAtual, ManaMax);
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] God Mode ATIVADO. Vida e Mana restauradas."));
	}
	else
	{
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] God Mode DESATIVADO."));
	}
}

// Lógica de subir de nível com multiplicador de 1.5x de XP e limite no nível 99
void UAC_Atributos::ProcessarLevelUp()
{
	if (Nivel >= 99)
	{
		Nivel = 99;
		XPAtual = XPMax;
		return;
	}

	XPAtual -= XPMax;
	Nivel++;
	
	XPMax = 100.0f * FMath::Pow(1.5f, static_cast<float>(Nivel - 1));
	VidaMax += 20.0f;
	ManaMax += 15.0f;
	
	VidaAtual = VidaMax;
	ManaAtual = ManaMax;

	OnVidaAlterada.Broadcast(VidaAtual, VidaMax);
	OnManaAlterada.Broadcast(ManaAtual, ManaMax);
	OnLevelUp.Broadcast(Nivel, XPMax);

	if (Nivel >= 99)
	{
		Nivel = 99;
		XPAtual = XPMax;
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] PARABÉNS! ALCANÇOU O NÍVEL MÁXIMO (99)!"));
	}
	else
	{
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] PARABÉNS! Subiu para o nível %d! Próximo XPMax (1.5x): %.1f"), Nivel, XPMax);
	}
}

// Salva o estado atual dos atributos, posição e inventário no disco
bool UAC_Atributos::SalvarAtributos(const FString& SlotName)
{
	FString TargetSlot = SlotName.IsEmpty() ? TEXT("ChroniclesSaveSlot") : SlotName;

	USaveGame_Chronicles* SaveInstance = Cast<USaveGame_Chronicles>(UGameplayStatics::CreateSaveGameObject(USaveGame_Chronicles::StaticClass()));
	if (!SaveInstance)
	{
		UE_LOG(LogTemp, Error, TEXT("[SaveGame] Falha ao criar a instância de SaveGame_Chronicles."));
		return false;
	}

	AActor* OwnerActor = GetOwner();
	if (OwnerActor)
	{
		SaveInstance->SavedLocation = OwnerActor->GetActorLocation();
		SaveInstance->SavedRotation = OwnerActor->GetActorRotation();
		SaveInstance->SavedMapName = UGameplayStatics::GetCurrentLevelName(this);

		UAC_Inventario* Inventario = OwnerActor->FindComponentByClass<UAC_Inventario>();
		if (Inventario)
		{
			SaveInstance->SavedItens = Inventario->GetItens();
			SaveInstance->SavedHotbarItens = Inventario->GetHotbarItens();
		}
	}

	SaveInstance->SavedVidaAtual = VidaAtual;
	SaveInstance->SavedVidaMax = VidaMax;
	SaveInstance->SavedManaAtual = ManaAtual;
	SaveInstance->SavedManaMax = ManaMax;
	SaveInstance->SavedNivel = FMath::Clamp(Nivel, 1, 99);
	SaveInstance->SavedXPAtual = XPAtual;
	SaveInstance->SavedXPMax = XPMax;
	SaveInstance->SavedGodMode = bGodMode;

	bool bSuccess = UGameplayStatics::SaveGameToSlot(SaveInstance, TargetSlot, 0);
	if (bSuccess)
	{
		UE_LOG(LogTemp, Warning, TEXT("[SaveGame] Atributos e Posição salvos no slot '%s' (Nível %d, XP %.1f/%.1f, Pos %s)."), 
			*TargetSlot, Nivel, XPAtual, XPMax, *SaveInstance->SavedLocation.ToString());
	}

	return bSuccess;
}

// Carrega o estado dos atributos, posição e inventário do disco
bool UAC_Atributos::CarregarAtributos(const FString& SlotName)
{
	FString TargetSlot = SlotName.IsEmpty() ? TEXT("ChroniclesSaveSlot") : SlotName;

	if (!UGameplayStatics::DoesSaveGameExist(TargetSlot, 0))
	{
		UE_LOG(LogTemp, Log, TEXT("[SaveGame] Nenhum save encontrado no slot '%s'. Mantendo atributos padrão."), *TargetSlot);
		return false;
	}

	USaveGame_Chronicles* SaveInstance = Cast<USaveGame_Chronicles>(UGameplayStatics::LoadGameFromSlot(TargetSlot, 0));
	if (!SaveInstance)
	{
		UE_LOG(LogTemp, Error, TEXT("[SaveGame] Falha ao carregar o arquivo de Save do slot '%s'."), *TargetSlot);
		return false;
	}

	Nivel = FMath::Clamp(SaveInstance->SavedNivel, 1, 99);
	XPMax = SaveInstance->SavedXPMax > 0.f ? SaveInstance->SavedXPMax : (100.0f * FMath::Pow(1.5f, static_cast<float>(Nivel - 1)));
	XPAtual = FMath::Clamp(SaveInstance->SavedXPAtual, 0.f, XPMax);
	
	VidaMax = SaveInstance->SavedVidaMax > 0.f ? SaveInstance->SavedVidaMax : 100.0f;
	VidaAtual = FMath::Clamp(SaveInstance->SavedVidaAtual, 0.f, VidaMax);
	
	ManaMax = SaveInstance->SavedManaMax > 0.f ? SaveInstance->SavedManaMax : 80.0f;
	ManaAtual = FMath::Clamp(SaveInstance->SavedManaAtual, 0.f, ManaMax);
	
	bGodMode = SaveInstance->SavedGodMode;

	AActor* OwnerActor = GetOwner();
	if (OwnerActor)
	{
		if (!SaveInstance->SavedLocation.IsZero())
		{
			OwnerActor->SetActorLocationAndRotation(SaveInstance->SavedLocation, SaveInstance->SavedRotation);
			UE_LOG(LogTemp, Warning, TEXT("[SaveGame] Posição do jogador restaurada no mundo: %s"), *SaveInstance->SavedLocation.ToString());
		}

		UAC_Inventario* Inventario = OwnerActor->FindComponentByClass<UAC_Inventario>();
		if (Inventario)
		{
			if (SaveInstance->SavedItens.Num() > 0)
			{
				Inventario->SetItens(SaveInstance->SavedItens);
				UE_LOG(LogTemp, Warning, TEXT("[SaveGame] Inventário restaurado com %d slots."), SaveInstance->SavedItens.Num());
			}
			if (SaveInstance->SavedHotbarItens.Num() > 0)
			{
				Inventario->SetHotbarItens(SaveInstance->SavedHotbarItens);
				UE_LOG(LogTemp, Warning, TEXT("[SaveGame] Hotbar restaurada com %d slots."), SaveInstance->SavedHotbarItens.Num());
			}
		}
	}

	OnVidaAlterada.Broadcast(VidaAtual, VidaMax);
	OnManaAlterada.Broadcast(ManaAtual, ManaMax);
	OnLevelUp.Broadcast(Nivel, XPMax);

	UE_LOG(LogTemp, Warning, TEXT("[SaveGame] Atributos e Posição CARREGADOS do slot '%s' (Nível %d, XP %.1f/%.1f)."), 
		*TargetSlot, Nivel, XPAtual, XPMax);

	return true;
}
