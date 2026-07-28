// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "ConsoleManager.generated.h"

class UAC_Atributos;

/**
 * Componente anexado ao Player Controller responsável por interceptar strings da UI,
 * fazer o parsing dos comandos de debug/trapaça e invocar os métodos correspondentes no UAC_Atributos.
 */
UCLASS(ClassGroup=(Custom), meta=(BlueprintSpawnableComponent))
class CHLONICLES_API UConsoleManager : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Define valores padrão para o componente
	UConsoleManager();

protected:
	// Chamado quando o jogo começa
	virtual void BeginPlay() override;

public:
	/**
	 * Processa uma string bruta de comando enviada pela UI do console.
	 * Exemplo de entradas: "/xp add 100", "heal", "/level set 5", "/god"
	 * 
	 * @param RawInput A string bruta do input do console.
	 * @return FString O resultado ou mensagem de feedback para ser exibida no log do console UI.
	 */
	UFUNCTION(BlueprintCallable, Category = "Console Debug")
	FString ExecuteConsoleCommand(const FString& RawInput);

private:
	/**
	 * Função auxiliar para obter o componente de atributos do Pawn atual do Player Controller proprietário.
	 */
	UAC_Atributos* GetPlayerAttributes() const;

	/**
	 * Handlers individuais para organizar de forma modular e limpa cada tipo de comando.
	 */
	FString HandleXPCommand(const TArray<FString>& Args, UAC_Atributos* Atributos);
	FString HandleHealCommand(const TArray<FString>& Args, UAC_Atributos* Atributos);
	FString HandleManaCommand(const TArray<FString>& Args, UAC_Atributos* Atributos);
	FString HandleLevelCommand(const TArray<FString>& Args, UAC_Atributos* Atributos);
	FString HandleGodCommand(const TArray<FString>& Args, UAC_Atributos* Atributos);
	FString HandleHelpCommand();
};
