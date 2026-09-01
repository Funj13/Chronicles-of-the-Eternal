// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "ChroniclesPauseLibrary.generated.h"

/**
 * Biblioteca de funções C++ para Gerenciamento de Pause, Salvar Jogo e Navegação de Menus.
 */
UCLASS()
class CHLONICLES_API UChroniclesPauseLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/**
	 * Pausa ou despausa o jogo, ajustando o Input Mode e visibilidade do Cursor do Mouse.
	 */
	UFUNCTION(BlueprintCallable, Category = "Chronicles|PauseSystem", meta = (WorldContext = "WorldContextObject"))
	static void DefinirPausaJogo(UObject* WorldContextObject, APlayerController* PlayerController, bool bPausar);

	/**
	 * Alterna o estado de Pause automaticamente (Abre se fechado, Fecha se aberto).
	 * Funciona universalmente para qualquer personagem (BP_PlayerGirl, BP_PlayerBoy, etc.).
	 */
	UFUNCTION(BlueprintCallable, Category = "Chronicles|PauseSystem", meta = (WorldContext = "WorldContextObject"))
	static void AlternarPausa(UObject* WorldContextObject, APlayerController* PlayerController, TSubclassOf<UUserWidget> PauseWidgetClass);

	/**
	 * Alterna a exibição do Inventário (Abre se fechado, Fecha se aberto) ajustando o Input Mode.
	 * Funciona universalmente para qualquer personagem.
	 */
	UFUNCTION(BlueprintCallable, Category = "Chronicles|InventorySystem", meta = (WorldContext = "WorldContextObject"))
	static void AlternarInventario(UObject* WorldContextObject, APlayerController* PlayerController, TSubclassOf<UUserWidget> InventoryWidgetClass);

	/**
	 * Executa o salvamento dos atributos do jogador no slot padrão.
	 */
	UFUNCTION(BlueprintCallable, Category = "Chronicles|PauseSystem", meta = (WorldContext = "WorldContextObject"))
	static bool SalvarJogoAtual(UObject* WorldContextObject);

	/**
	 * Despausa o jogo e redireciona para o Menu Inicial.
	 */
	UFUNCTION(BlueprintCallable, Category = "Chronicles|PauseSystem", meta = (WorldContext = "WorldContextObject"))
	static void VoltarAoMenuInicial(UObject* WorldContextObject, FName NomeMapaMenu = TEXT("Map_MainMenu"));

	/**
	 * Encerra o jogo.
	 */
	UFUNCTION(BlueprintCallable, Category = "Chronicles|PauseSystem")
	static void SairDoJogo(APlayerController* PlayerController);
};
