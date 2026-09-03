// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Engine/Texture2D.h"
#include "Engine/DataTable.h"
#include "AC_Inventario.generated.h"

/**
 * Estrutura que representa um Item do Inventário e Linha da DataTable em C++
 */
USTRUCT(BlueprintType)
struct FItemInventario : public FTableRowBase
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Item")
	FString ItemID;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Item")
	FText NomeItem;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Item")
	FText Descricao;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Item")
	int32 Quantidade;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Item")
	int32 QuantidadeMaximaStack;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Item")
	UTexture2D* Icone;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Item")
	bool bConsumivel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Item")
	float ValorEfeito; // ex: recupera 50 de vida ou 30 de mana

	FItemInventario()
		: ItemID(TEXT("none"))
		, NomeItem(FText::FromString(TEXT("Vazio")))
		, Descricao(FText::GetEmpty())
		, Quantidade(0)
		, QuantidadeMaximaStack(99)
		, Icone(nullptr)
		, bConsumivel(false)
		, ValorEfeito(0.0f)
	{}
};

// Delegate acionado quando o inventário é alterado
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnInventarioAtualizado);

/**
 * Componente de Inventário C++ para o jogo Chronicles of the Eternal.
 */
UCLASS(ClassGroup=(Custom), meta=(BlueprintSpawnableComponent))
class CHLONICLES_API UAC_Inventario : public UActorComponent
{
	GENERATED_BODY()

public:	
	UAC_Inventario();

protected:
	virtual void BeginPlay() override;

	/** Capacidade máxima de slots do inventário */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Inventário", meta = (ClampMin = "1"))
	int32 CapacidadeMaxima;

	/** Lista de Itens no Inventário */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Inventário")
	TArray<FItemInventario> Itens;

	/** IDs dos Itens equipados nos Atalhos da Hotbar (0 a 5 -> Teclas 1 a 6) */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Inventário|Hotbar")
	TArray<FString> HotbarItemIDs;

	/** Referência à Tabela de Dados de Itens (DT_Items) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Inventário|DataTable")
	UDataTable* TabelaItens;

public:
	/** Evento disparado para a UI sempre que o inventário ou hotbar mudar */
	UPROPERTY(BlueprintAssignable, Category = "Inventário|Eventos")
	FOnInventarioAtualizado OnInventarioAtualizado;

	/** Adiciona um item ao inventário buscando diretamente na DT_Items por RowName ou ItemID. */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Ações")
	bool AdicionarItemPorID(FName ItemIDOuRowName, int32 Quantidade = 1);

	/** Busca um item na DataTable por RowName ou ItemID */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Getters")
	bool BuscarItemNaTabela(FName ItemIDOuRowName, FItemInventario& OutItem) const;

	/** Adiciona um item ao inventário. Retorna true se adicionou completamente. */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Ações")
	bool AdicionarItem(FItemInventario NovoItem);

	/** Remove uma quantidade de item pelo ItemID. */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Ações")
	bool RemoverItem(FString ItemID, int32 Quantidade = 1);

	/** Usa um item consumível do slot. */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Ações")
	bool UsarItemSlot(int32 SlotIndex);

	/** Troca ou move a posição de dois slots no inventário (Drag & Drop) */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Ações")
	bool TrocarSlotsInventario(int32 DeIndex, int32 ParaIndex);

	/** Equipar ItemID no slot da Hotbar (0 a 5) */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Hotbar")
	bool EquiparHotbar(int32 HotbarIndex, FString ItemID);

	/** Usa o item atrelado ao slot da Hotbar (0 a 5 -> Teclas 1 a 6) */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Hotbar")
	bool UsarHotbar(int32 HotbarIndex);

	/** Obtém o item associado a um slot da Hotbar */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Hotbar")
	bool GetItemHotbar(int32 HotbarIndex, FItemInventario& OutItem) const;

	/** Obtém a lista de IDs da Hotbar */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Hotbar")
	TArray<FString> GetHotbarItemIDs() const { return HotbarItemIDs; }

	/** Obtém a lista completa de itens */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Getters")
	TArray<FItemInventario> GetItens() const { return Itens; }

	/** Obtém a capacidade máxima */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Getters")
	int32 GetCapacidadeMaxima() const { return CapacidadeMaxima; }

	/** Limpa todo o inventário */
	UFUNCTION(BlueprintCallable, Category = "Inventário|Ações")
	void LimparInventario();
};
