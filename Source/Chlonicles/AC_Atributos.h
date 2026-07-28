// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "AC_Atributos.generated.h"

/**
 * Componente de gerenciamento de atributos (Vida, Mana, Nível e XP) para Chronicles of the Eternal.
 */
UCLASS(ClassGroup=(Custom), meta=(BlueprintSpawnableComponent))
class CHLONICLES_API UAC_Atributos : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Define valores padrão para o componente
	UAC_Atributos();

protected:
	// Chamado quando o jogo começa
	virtual void BeginPlay() override;

	/** Atributos de Vida */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Atributos|Vida", meta = (ClampMin = "0.0"))
	float VidaAtual;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Atributos|Vida", meta = (ClampMin = "1.0"))
	float VidaMax;

	/** Atributos de Mana */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Atributos|Mana", meta = (ClampMin = "0.0"))
	float ManaAtual;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Atributos|Mana", meta = (ClampMin = "1.0"))
	float ManaMax;

	/** Atributos de Progressão */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Atributos|Progressão", meta = (ClampMin = "1"))
	int32 Nivel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Atributos|Progressão", meta = (ClampMin = "0.0"))
	float XPAtual;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Atributos|Progressão", meta = (ClampMin = "10.0"))
	float XPMax;

	/** Estado de Debug / Trapaça */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Atributos|Debug")
	bool bGodMode;

public:
	/** Getters para os Atributos */
	UFUNCTION(BlueprintCallable, Category = "Atributos|Getters")
	float GetVidaAtual() const { return VidaAtual; }

	UFUNCTION(BlueprintCallable, Category = "Atributos|Getters")
	float GetVidaMax() const { return VidaMax; }

	UFUNCTION(BlueprintCallable, Category = "Atributos|Getters")
	float GetManaAtual() const { return ManaAtual; }

	UFUNCTION(BlueprintCallable, Category = "Atributos|Getters")
	float GetManaMax() const { return ManaMax; }

	UFUNCTION(BlueprintCallable, Category = "Atributos|Getters")
	int32 GetNivel() const { return Nivel; }

	UFUNCTION(BlueprintCallable, Category = "Atributos|Getters")
	float GetXPAtual() const { return XPAtual; }

	UFUNCTION(BlueprintCallable, Category = "Atributos|Getters")
	float GetXPMax() const { return XPMax; }

	UFUNCTION(BlueprintCallable, Category = "Atributos|Getters")
	bool IsGodModeActive() const { return bGodMode; }

	/** Métodos de Modificação de Atributos */

	// Cura o personagem. Se Valor <= 0, cura totalmente.
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void Curar(float Valor = 0.f);

	// Modifica a vida atual diretamente (respeitando limites e God Mode)
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void ModificarVida(float Valor);

	// Define a vida atual diretamente
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void SetVida(float NovaVida);

	// Modifica a mana atual diretamente
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void ModificarMana(float Valor);

	// Adiciona uma quantidade de XP, tratando lógica de Level Up
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void AdicionarXP(float Quantidade);

	// Define o XP atual diretamente
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void SetXP(float NovoXP);

	// Define a mana atual diretamente
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void SetMana(float NovaMana);

	// Define o Nível diretamente
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void SetNivel(int32 NovoNivel);

	// Alterna o estado do modo God (Imortal)
	UFUNCTION(BlueprintCallable, Category = "Atributos|Ações")
	void ToggleGodMode();

private:
	// Função interna para processar o ganho de níveis
	void ProcessarLevelUp();
};
