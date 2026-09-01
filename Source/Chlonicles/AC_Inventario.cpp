// Fill out your copyright notice in the Description page of Project Settings.

#include "AC_Inventario.h"
#include "AC_Atributos.h"
#include "GameFramework/Actor.h"

UAC_Inventario::UAC_Inventario()
{
	PrimaryComponentTick.bCanEverTick = false;
	CapacidadeMaxima = 20;
	HotbarItemIDs.Init(TEXT(""), 6);
}

void UAC_Inventario::BeginPlay()
{
	Super::BeginPlay();
	if (HotbarItemIDs.Num() < 6)
	{
		HotbarItemIDs.Init(TEXT(""), 6);
	}
}

bool UAC_Inventario::EquiparHotbar(int32 HotbarIndex, FString ItemID)
{
	if (!HotbarItemIDs.IsValidIndex(HotbarIndex))
	{
		return false;
	}

	HotbarItemIDs[HotbarIndex] = ItemID;
	UE_LOG(LogTemp, Warning, TEXT("[Hotbar] Item '%s' equipado no atalho %d da Hotbar."), *ItemID, HotbarIndex + 1);

	OnInventarioAtualizado.Broadcast();
	return true;
}

bool UAC_Inventario::UsarHotbar(int32 HotbarIndex)
{
	if (!HotbarItemIDs.IsValidIndex(HotbarIndex))
	{
		return false;
	}

	FString TargetID = HotbarItemIDs[HotbarIndex];
	if (TargetID.IsEmpty())
	{
		return false;
	}

	// Encontra o primeiro slot do inventário que contém esse ItemID
	for (int32 i = 0; i < Itens.Num(); ++i)
	{
		if (Itens[i].ItemID.Equals(TargetID, ESearchCase::IgnoreCase))
		{
			return UsarItemSlot(i);
		}
	}

	UE_LOG(LogTemp, Warning, TEXT("[Hotbar] Item '%s' do atalho %d não encontrado no inventário."), *TargetID, HotbarIndex + 1);
	return false;
}

bool UAC_Inventario::GetItemHotbar(int32 HotbarIndex, FItemInventario& OutItem) const
{
	OutItem = FItemInventario();
	if (!HotbarItemIDs.IsValidIndex(HotbarIndex))
	{
		return false;
	}

	FString TargetID = HotbarItemIDs[HotbarIndex];
	if (TargetID.IsEmpty())
	{
		return false;
	}

	for (const FItemInventario& Item : Itens)
	{
		if (Item.ItemID.Equals(TargetID, ESearchCase::IgnoreCase))
		{
			OutItem = Item;
			return true;
		}
	}

	return false;
}

bool UAC_Inventario::AdicionarItem(FItemInventario NovoItem)
{
	if (NovoItem.ItemID.IsEmpty() || NovoItem.Quantidade <= 0)
	{
		return false;
	}

	// 1. Tenta empilhar em um slot existente que ainda não está cheio
	for (FItemInventario& Item : Itens)
	{
		if (Item.ItemID.Equals(NovoItem.ItemID, ESearchCase::IgnoreCase))
		{
			int32 EspacoRestante = Item.QuantidadeMaximaStack - Item.Quantidade;
			if (EspacoRestante > 0)
			{
				int32 QtdAdicionar = FMath::Min(EspacoRestante, NovoItem.Quantidade);
				Item.Quantidade += QtdAdicionar;
				NovoItem.Quantidade -= QtdAdicionar;

				UE_LOG(LogTemp, Log, TEXT("[Inventário] Empilhado %dx de '%s'. Quantidade total no slot: %d"),
					QtdAdicionar, *Item.ItemID, Item.Quantidade);

				if (NovoItem.Quantidade <= 0)
				{
					OnInventarioAtualizado.Broadcast();
					return true;
				}
			}
		}
	}

	// 2. Se sobrou quantidade e há espaço livre no inventário, cria novo slot
	while (NovoItem.Quantidade > 0 && Itens.Num() < CapacidadeMaxima)
	{
		FItemInventario SlotNovo = NovoItem;
		SlotNovo.Quantidade = FMath::Min(NovoItem.Quantidade, NovoItem.QuantidadeMaximaStack);
		NovoItem.Quantidade -= SlotNovo.Quantidade;

		Itens.Add(SlotNovo);
		UE_LOG(LogTemp, Warning, TEXT("[Inventário] Novo slot criado para '%s' (Qtd: %d). Total de slots usados: %d/%d"),
			*SlotNovo.ItemID, SlotNovo.Quantidade, Itens.Num(), CapacidadeMaxima);
	}

	OnInventarioAtualizado.Broadcast();
	return NovoItem.Quantidade <= 0;
}

bool UAC_Inventario::RemoverItem(FString ItemID, int32 Quantidade)
{
	if (Quantidade <= 0 || ItemID.IsEmpty())
	{
		return false;
	}

	int32 RestanteParaRemover = Quantidade;

	for (int32 i = Itens.Num() - 1; i >= 0; --i)
	{
		if (Itens[i].ItemID.Equals(ItemID, ESearchCase::IgnoreCase))
		{
			if (Itens[i].Quantidade <= RestanteParaRemover)
			{
				RestanteParaRemover -= Itens[i].Quantidade;
				Itens.RemoveAt(i);
			}
			else
			{
				Itens[i].Quantidade -= RestanteParaRemover;
				RestanteParaRemover = 0;
			}

			if (RestanteParaRemover <= 0)
			{
				break;
			}
		}
	}

	OnInventarioAtualizado.Broadcast();
	return RestanteParaRemover < Quantidade;
}

bool UAC_Inventario::UsarItemSlot(int32 SlotIndex)
{
	if (!Itens.IsValidIndex(SlotIndex))
	{
		return false;
	}

	FItemInventario& Item = Itens[SlotIndex];
	if (!Item.bConsumivel)
	{
		UE_LOG(LogTemp, Warning, TEXT("[Inventário] O item '%s' não é consumível."), *Item.ItemID);
		return false;
	}

	AActor* OwnerActor = GetOwner();
	if (OwnerActor)
	{
		UAC_Atributos* Atributos = OwnerActor->FindComponentByClass<UAC_Atributos>();
		if (Atributos)
		{
			// Se o efeito for de cura de vida
			if (Item.ValorEfeito > 0.0f)
			{
				Atributos->Curar(Item.ValorEfeito);
				UE_LOG(LogTemp, Warning, TEXT("[Inventário] Item '%s' usado! Aplicado cura de %.1f."), *Item.ItemID, Item.ValorEfeito);
			}
		}
	}

	// Consome 1 unidade do item
	Item.Quantidade--;
	if (Item.Quantidade <= 0)
	{
		Itens.RemoveAt(SlotIndex);
	}

	OnInventarioAtualizado.Broadcast();
	return true;
}

bool UAC_Inventario::TrocarSlotsInventario(int32 DeIndex, int32 ParaIndex)
{
	if (DeIndex == ParaIndex || DeIndex < 0 || ParaIndex < 0 || DeIndex >= CapacidadeMaxima || ParaIndex >= CapacidadeMaxima)
	{
		return false;
	}

	int32 MaxIndex = FMath::Max(DeIndex, ParaIndex);
	while (Itens.Num() <= MaxIndex)
	{
		Itens.Add(FItemInventario());
	}

	Itens.Swap(DeIndex, ParaIndex);
	UE_LOG(LogTemp, Warning, TEXT("[Inventário] Trocados os slots %d e %d."), DeIndex, ParaIndex);

	OnInventarioAtualizado.Broadcast();
	return true;
}

void UAC_Inventario::LimparInventario()
{
	Itens.Empty();
	OnInventarioAtualizado.Broadcast();
	UE_LOG(LogTemp, Log, TEXT("[Inventário] Todo o inventário foi limpo."));
}
