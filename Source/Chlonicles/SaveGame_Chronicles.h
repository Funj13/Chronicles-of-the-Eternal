// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "AC_Inventario.h"
#include "SaveGame_Chronicles.generated.h"

/**
 * Objeto de SaveGame para o jogo Chronicles of the Eternal.
 * Armazena a persistência dos atributos do jogador, localização no mundo e inventário.
 */
UCLASS()
class CHLONICLES_API USaveGame_Chronicles : public USaveGame
{
	GENERATED_BODY()

public:
	USaveGame_Chronicles();

	/** Nome do Slot Padrão de Salvamento */
	UPROPERTY(VisibleAnywhere, Category = "SaveGame")
	FString SaveSlotName;

	/** Índice do Usuário */
	UPROPERTY(VisibleAnywhere, Category = "SaveGame")
	uint32 UserIndex;

	/** Localização e Mapa Salvo (Passo 4) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Mundo")
	FVector SavedLocation;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Mundo")
	FRotator SavedRotation;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Mundo")
	FString SavedMapName;

	/** Atributos Salvos */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Atributos")
	float SavedVidaAtual;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Atributos")
	float SavedVidaMax;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Atributos")
	float SavedManaAtual;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Atributos")
	float SavedManaMax;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Atributos")
	int32 SavedNivel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Atributos")
	float SavedXPAtual;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Atributos")
	float SavedXPMax;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Atributos")
	bool SavedGodMode;

	/** Inventário Salvo (Passo 5) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Inventário")
	TArray<FItemInventario> SavedItens;

	/** Hotbar Salva (Passo 5) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "SaveGame|Inventário")
	TArray<FItemInventario> SavedHotbarItens;
};
