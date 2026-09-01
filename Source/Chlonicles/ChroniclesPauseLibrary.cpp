// Fill out your copyright notice in the Description page of Project Settings.

#include "ChroniclesPauseLibrary.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "AC_Atributos.h"
#include "Blueprint/UserWidget.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/Pawn.h"

// Referência estática fracamente acoplada para a instância ativa do Widget de Pause e Inventário
static TWeakObjectPtr<UUserWidget> GActivePauseWidget = nullptr;
static TWeakObjectPtr<UUserWidget> GActiveInventoryWidget = nullptr;

void UChroniclesPauseLibrary::DefinirPausaJogo(UObject* WorldContextObject, APlayerController* PlayerController, bool bPausar)
{
	if (!WorldContextObject)
	{
		return;
	}

	// Define o estado de Pausa no mundo
	UGameplayStatics::SetGamePaused(WorldContextObject, bPausar);

	if (PlayerController)
	{
		if (bPausar)
		{
			// Modo Game and UI com cursor visível
			FInputModeGameAndUI InputMode;
			InputMode.SetHideCursorDuringCapture(false);
			InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
			PlayerController->SetInputMode(InputMode);
			PlayerController->bShowMouseCursor = true;
		}
		else
		{
			// Modo Game Only com cursor escondido e travado na câmera
			FInputModeGameOnly InputMode;
			InputMode.SetConsumeCaptureMouseDown(true);
			PlayerController->SetInputMode(InputMode);
			PlayerController->bShowMouseCursor = false;
			PlayerController->SetIgnoreLookInput(false);
		}
	}

	UE_LOG(LogTemp, Log, TEXT("[PauseLibrary] Estado de Pausa alterado para: %s"), bPausar ? TEXT("PAUSADO") : TEXT("DESPAUSADO"));
}

void UChroniclesPauseLibrary::AlternarPausa(UObject* WorldContextObject, APlayerController* PlayerController, TSubclassOf<UUserWidget> PauseWidgetClass)
{
	if (!WorldContextObject || !PlayerController)
	{
		return;
	}

	bool bIsPaused = UGameplayStatics::IsGamePaused(WorldContextObject);

	if (bIsPaused || (GActivePauseWidget.IsValid() && GActivePauseWidget->IsInViewport()))
	{
		// Se o jogo já está pausado ou o menu está na tela -> Remove da tela e despausa
		if (GActivePauseWidget.IsValid())
		{
			GActivePauseWidget->RemoveFromParent();
			GActivePauseWidget.Reset();
		}

		DefinirPausaJogo(WorldContextObject, PlayerController, false);
	}
	else
	{
		// Se o jogo não está pausado -> Cria ou reexibe o Widget e pausa
		if (!GActivePauseWidget.IsValid() && PauseWidgetClass)
		{
			UUserWidget* NewWidget = CreateWidget<UUserWidget>(PlayerController, PauseWidgetClass);
			GActivePauseWidget = NewWidget;
		}

		if (GActivePauseWidget.IsValid())
		{
			if (!GActivePauseWidget->IsInViewport())
			{
				GActivePauseWidget->AddToViewport(99);
			}
		}

		DefinirPausaJogo(WorldContextObject, PlayerController, true);
	}
}

void UChroniclesPauseLibrary::AlternarInventario(UObject* WorldContextObject, APlayerController* PlayerController, TSubclassOf<UUserWidget> InventoryWidgetClass)
{
	if (!WorldContextObject || !PlayerController)
	{
		return;
	}

	if (GActiveInventoryWidget.IsValid() && GActiveInventoryWidget->IsInViewport())
	{
		// Se o inventário está aberto -> Remove da tela e volta ao GameOnly
		GActiveInventoryWidget->RemoveFromParent();
		GActiveInventoryWidget.Reset();

		FInputModeGameOnly InputMode;
		InputMode.SetConsumeCaptureMouseDown(true);
		PlayerController->SetInputMode(InputMode);
		PlayerController->bShowMouseCursor = false;
		PlayerController->SetIgnoreLookInput(false);
		UE_LOG(LogTemp, Log, TEXT("[Inventário] Inventário FECHADO."));
	}
	else
	{
		// Se o inventário está fechado -> Cria ou reexibe o Widget e ativa GameAndUI
		if (!GActiveInventoryWidget.IsValid() && InventoryWidgetClass)
		{
			UUserWidget* NewWidget = CreateWidget<UUserWidget>(PlayerController, InventoryWidgetClass);
			GActiveInventoryWidget = NewWidget;
		}

		if (GActiveInventoryWidget.IsValid())
		{
			if (!GActiveInventoryWidget->IsInViewport())
			{
				GActiveInventoryWidget->AddToViewport(50);
			}

			FInputModeGameAndUI InputMode;
			InputMode.SetHideCursorDuringCapture(false);
			InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
			PlayerController->SetInputMode(InputMode);
			PlayerController->bShowMouseCursor = true;
			UE_LOG(LogTemp, Log, TEXT("[Inventário] Inventário ABERTO."));
		}
	}
}

bool UChroniclesPauseLibrary::SalvarJogoAtual(UObject* WorldContextObject)
{
	if (!WorldContextObject)
	{
		return false;
	}

	APlayerController* PC = UGameplayStatics::GetPlayerController(WorldContextObject, 0);
	if (!PC)
	{
		return false;
	}

	APawn* Pawn = PC->GetPawn();
	if (!Pawn)
	{
		return false;
	}

	UAC_Atributos* Atributos = Pawn->FindComponentByClass<UAC_Atributos>();
	if (!Atributos)
	{
		UE_LOG(LogTemp, Error, TEXT("[PauseLibrary] AC_Atributos não foi encontrado no personagem para salvar."));
		return false;
	}

	return Atributos->SalvarAtributos();
}

void UChroniclesPauseLibrary::VoltarAoMenuInicial(UObject* WorldContextObject, FName NomeMapaMenu)
{
	if (!WorldContextObject)
	{
		return;
	}

	// Garante que o jogo é despausado antes de trocar de nível
	UGameplayStatics::SetGamePaused(WorldContextObject, false);

	APlayerController* PC = UGameplayStatics::GetPlayerController(WorldContextObject, 0);
	if (PC)
	{
		FInputModeGameOnly InputMode;
		PC->SetInputMode(InputMode);
		PC->bShowMouseCursor = false;
	}

	FName TargetMap = NomeMapaMenu.IsNone() ? FName(TEXT("Map_MainMenu")) : NomeMapaMenu;
	UE_LOG(LogTemp, Warning, TEXT("[PauseLibrary] Redirecionando para o mapa de menu '%s'..."), *TargetMap.ToString());
	UGameplayStatics::OpenLevel(WorldContextObject, TargetMap);
}

void UChroniclesPauseLibrary::SairDoJogo(APlayerController* PlayerController)
{
	if (!PlayerController)
	{
		return;
	}

	UE_LOG(LogTemp, Warning, TEXT("[PauseLibrary] Encerrando a aplicação..."));
	UKismetSystemLibrary::QuitGame(PlayerController, PlayerController, EQuitPreference::Quit, false);
}
