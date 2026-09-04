// Fill out your copyright notice in the Description page of Project Settings.

#include "AC_Inventario.h"
#include "AC_Atributos.h"
#include "GameFramework/Actor.h"

UAC_Inventario::UAC_Inventario()
{
	PrimaryComponentTick.bCanEverTick = false;
	CapacidadeMaxima = 28;
	HotbarItemIDs.Init(TEXT(""), 6);
	HotbarItens.Init(FItemInventario(), 6);
	TabelaItens = nullptr;
}

void UAC_Inventario::BeginPlay()
{
	Super::BeginPlay();
	GarantirTamanhoSlots();

	if (!TabelaItens)
	{
		TabelaItens = LoadObject<UDataTable>(nullptr, TEXT("/Game/Chronicles/Date/DT_Items.DT_Items"));
		if (!TabelaItens)
		{
			TabelaItens = LoadObject<UDataTable>(nullptr, TEXT("/Game/Chronicles/Data/DT_Items.DT_Items"));
		}
	}
}

void UAC_Inventario::GarantirTamanhoSlots()
{
	if (Itens.Num() < CapacidadeMaxima)
	{
		int32 Falta = CapacidadeMaxima - Itens.Num();
		for (int32 i = 0; i < Falta; ++i)
		{
			Itens.Add(FItemInventario());
		}
	}
	if (HotbarItens.Num() < 6)
	{
		int32 Falta = 6 - HotbarItens.Num();
		for (int32 i = 0; i < Falta; ++i)
		{
			HotbarItens.Add(FItemInventario());
		}
	}
	if (HotbarItemIDs.Num() < 6)
	{
		HotbarItemIDs.Init(TEXT(""), 6);
	}
}

TArray<FItemInventario> UAC_Inventario::GetItens() const
{
	if (Itens.Num() < CapacidadeMaxima)
	{
		const_cast<UAC_Inventario*>(this)->GarantirTamanhoSlots();
	}
	return Itens;
}

bool UAC_Inventario::BuscarItemNaTabela(FName ItemIDOuRowName, FItemInventario& OutItem) const
{
	UDataTable* Table = TabelaItens;
	if (!Table)
	{
		Table = LoadObject<UDataTable>(nullptr, TEXT("/Game/Chronicles/Date/DT_Items.DT_Items"));
		if (!Table)
		{
			Table = LoadObject<UDataTable>(nullptr, TEXT("/Game/Chronicles/Data/DT_Items.DT_Items"));
		}
	}

	if (Table)
	{
		// 1. Tenta buscar direto pelo RowName na DataTable
		FItemInventario* Row = Table->FindRow<FItemInventario>(ItemIDOuRowName, TEXT("BuscarItemNaTabela"));
		if (Row)
		{
			OutItem = *Row;
			if (OutItem.ItemID.IsEmpty() || OutItem.ItemID == TEXT("none"))
			{
				OutItem.ItemID = ItemIDOuRowName.ToString();
			}
			return true;
		}

		// 2. Tenta buscar pela coluna ItemID do GDD
		FString SearchStr = ItemIDOuRowName.ToString();
		for (const auto& It : Table->GetRowMap())
		{
			const FItemInventario* ItemRow = reinterpret_cast<const FItemInventario*>(It.Value);
			if (ItemRow && (ItemRow->ItemID.Equals(SearchStr, ESearchCase::IgnoreCase) || It.Key.ToString().Equals(SearchStr, ESearchCase::IgnoreCase)))
			{
				OutItem = *ItemRow;
				return true;
			}
		}
	}

	// 3. Fallback C++ com os 14 itens e materiais cadastrados do GDD
	FString ID = ItemIDOuRowName.ToString().ToLower();

	if (ID == TEXT("itm_potion_hp_small") || ID == TEXT("pocao_vida_pequena"))
	{
		OutItem.ItemID = TEXT("itm_potion_hp_small");
		OutItem.NomeItem = FText::FromString(TEXT("Poção Pequena"));
		OutItem.Descricao = FText::FromString(TEXT("Uma poção pequena para curar raladuras. Restaura 20 de vida"));
		OutItem.QuantidadeMaximaStack = 99;
		OutItem.bConsumivel = true;
		OutItem.ValorEfeito = 20.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_pocao_small.T_pocao_small"));
		return true;
	}
	if (ID == TEXT("itm_potion_hp_mid") || ID == TEXT("pocao_vida_media"))
	{
		OutItem.ItemID = TEXT("itm_potion_hp_mid");
		OutItem.NomeItem = FText::FromString(TEXT("Poção Média"));
		OutItem.Descricao = FText::FromString(TEXT("Recupera vida levemente. Gosto amargo. Um pouco maior que a poção pequena"));
		OutItem.QuantidadeMaximaStack = 99;
		OutItem.bConsumivel = true;
		OutItem.ValorEfeito = 35.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_pocao_small.T_pocao_small"));
		return true;
	}
	if (ID == TEXT("itm_ether_stamina") || ID == TEXT("cantil"))
	{
		OutItem.ItemID = TEXT("itm_ether_stamina");
		OutItem.NomeItem = FText::FromString(TEXT("Cantil"));
		OutItem.Descricao = FText::FromString(TEXT("Nada melhor para descansar que um pouco de água."));
		OutItem.QuantidadeMaximaStack = 99;
		OutItem.bConsumivel = true;
		OutItem.ValorEfeito = 100.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_pocao_mana_Small.T_pocao_mana_Small"));
		return true;
	}
	if (ID == TEXT("itm_potion_hp_big") || ID == TEXT("pocao_vida"))
	{
		OutItem.ItemID = TEXT("itm_potion_hp_big");
		OutItem.NomeItem = FText::FromString(TEXT("Poção Grande"));
		OutItem.Descricao = FText::FromString(TEXT("Recupera vida moderadamente. Gosto amargo."));
		OutItem.QuantidadeMaximaStack = 99;
		OutItem.bConsumivel = true;
		OutItem.ValorEfeito = 50.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_PocaoVida.T_PocaoVida"));
		return true;
	}
	if (ID == TEXT("itm_ether_mana") || ID == TEXT("pocao_mana"))
	{
		OutItem.ItemID = TEXT("itm_ether_mana");
		OutItem.NomeItem = FText::FromString(TEXT("Éter Mana"));
		OutItem.Descricao = FText::FromString(TEXT("Recupera mana. Brilha no escuro."));
		OutItem.QuantidadeMaximaStack = 99;
		OutItem.bConsumivel = true;
		OutItem.ValorEfeito = 30.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_pocao_mana_big.T_pocao_mana_big"));
		return true;
	}
	if (ID == TEXT("mat_iron_ore") || ID == TEXT("minerio_ferro"))
	{
		OutItem.ItemID = TEXT("mat_iron_ore");
		OutItem.NomeItem = FText::FromString(TEXT("Minério de Ferro"));
		OutItem.Descricao = FText::FromString(TEXT("Usado para forjar armas básicas."));
		OutItem.QuantidadeMaximaStack = 99;
		OutItem.bConsumivel = false;
		OutItem.ValorEfeito = 0.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_cubo.T_cubo"));
		return true;
	}
	if (ID == TEXT("mat_copper_ore") || ID == TEXT("minerio_cobre"))
	{
		OutItem.ItemID = TEXT("mat_copper_ore");
		OutItem.NomeItem = FText::FromString(TEXT("Minério de Cobre"));
		OutItem.Descricao = FText::FromString(TEXT("Usado para forjar armas básicas."));
		OutItem.QuantidadeMaximaStack = 99;
		OutItem.bConsumivel = false;
		OutItem.ValorEfeito = 0.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_cubo.T_cubo"));
		return true;
	}
	if (ID == TEXT("mat_energy_cube") || ID == TEXT("cubo_energia"))
	{
		OutItem.ItemID = TEXT("mat_energy_cube");
		OutItem.NomeItem = FText::FromString(TEXT("Cubo de Energia"));
		OutItem.Descricao = FText::FromString(TEXT("Um item desconhecido..."));
		OutItem.QuantidadeMaximaStack = 1;
		OutItem.bConsumivel = false;
		OutItem.ValorEfeito = 0.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_cubo.T_cubo"));
		return true;
	}
	if (ID == TEXT("itm_heal_injector") || ID == TEXT("injetor_vida"))
	{
		OutItem.ItemID = TEXT("itm_heal_injector");
		OutItem.NomeItem = FText::FromString(TEXT("Injetor de Vida"));
		OutItem.Descricao = FText::FromString(TEXT("Seringa de metal estilo steampunk/militar."));
		OutItem.QuantidadeMaximaStack = 1;
		OutItem.bConsumivel = true;
		OutItem.ValorEfeito = 50.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_pocao_small.T_pocao_small"));
		return true;
	}
	if (ID == TEXT("itm_battery_cell") || ID == TEXT("celula_mana"))
	{
		OutItem.ItemID = TEXT("itm_battery_cell");
		OutItem.NomeItem = FText::FromString(TEXT("Célula de Mana"));
		OutItem.Descricao = FText::FromString(TEXT("Bateria retangular brilhando azul neon."));
		OutItem.QuantidadeMaximaStack = 1;
		OutItem.bConsumivel = true;
		OutItem.ValorEfeito = 50.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_pocao_mana_Small.T_pocao_mana_Small"));
		return true;
	}
	if (ID == TEXT("mat_scrap_metal") || ID == TEXT("sucata"))
	{
		OutItem.ItemID = TEXT("mat_scrap_metal");
		OutItem.NomeItem = FText::FromString(TEXT("Sucata"));
		OutItem.Descricao = FText::FromString(TEXT("Engrenagem quebrada ou chapa amassada."));
		OutItem.QuantidadeMaximaStack = 99;
		OutItem.bConsumivel = false;
		OutItem.ValorEfeito = 0.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_cubo.T_cubo"));
		return true;
	}
	if (ID == TEXT("mat_tech_chip") || ID == TEXT("chip_eterno"))
	{
		OutItem.ItemID = TEXT("mat_tech_chip");
		OutItem.NomeItem = FText::FromString(TEXT("Chip Eterno"));
		OutItem.Descricao = FText::FromString(TEXT("Placa de circuito brilhante e limpa."));
		OutItem.QuantidadeMaximaStack = 1;
		OutItem.bConsumivel = false;
		OutItem.ValorEfeito = 0.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_cubo.T_cubo"));
		return true;
	}
	if (ID == TEXT("key_valve_wheel") || ID == TEXT("valvula_chave"))
	{
		OutItem.ItemID = TEXT("key_valve_wheel");
		OutItem.NomeItem = FText::FromString(TEXT("Válvula (Chave)"));
		OutItem.Descricao = FText::FromString(TEXT("Roda de registro de água (abre portas humanas)."));
		OutItem.QuantidadeMaximaStack = 1;
		OutItem.bConsumivel = false;
		OutItem.ValorEfeito = 0.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_cubo.T_cubo"));
		return true;
	}
	if (ID == TEXT("key_access_card") || ID == TEXT("cartao_acesso"))
	{
		OutItem.ItemID = TEXT("key_access_card");
		OutItem.NomeItem = FText::FromString(TEXT("Cartão Acesso"));
		OutItem.Descricao = FText::FromString(TEXT("Cartão magnético de vidro/plástico (abre dungeons)."));
		OutItem.QuantidadeMaximaStack = 1;
		OutItem.bConsumivel = false;
		OutItem.ValorEfeito = 0.0f;
		OutItem.Icone = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Chronicles/UI/Icons/T_cubo.T_cubo"));
		return true;
	}

	return false;
}

bool UAC_Inventario::AdicionarItemPorID(FName ItemIDOuRowName, int32 Quantidade)
{
	if (Quantidade <= 0)
	{
		return false;
	}

	FItemInventario ItemEncontrado;
	if (!BuscarItemNaTabela(ItemIDOuRowName, ItemEncontrado))
	{
		UE_LOG(LogTemp, Warning, TEXT("[Inventário] O item '%s' não existe na DataTable DT_Items!"), *ItemIDOuRowName.ToString());
		return false;
	}

	ItemEncontrado.Quantidade = Quantidade;
	return AdicionarItem(ItemEncontrado);
}

bool UAC_Inventario::MoverInventarioParaHotbar(int32 InvSlot, int32 HotbarSlot)
{
	if (InvSlot < 0 || InvSlot >= CapacidadeMaxima || HotbarSlot < 0 || HotbarSlot >= 6)
	{
		return false;
	}

	while (Itens.Num() <= InvSlot)
	{
		Itens.Add(FItemInventario());
	}

	if (HotbarItens.Num() < 6)
	{
		HotbarItens.Init(FItemInventario(), 6);
	}

	// Troca física direta do item da mochila com o item da Hotbar (estilo Minecraft)
	FItemInventario Temp = Itens[InvSlot];
	Itens[InvSlot] = HotbarItens[HotbarSlot];
	HotbarItens[HotbarSlot] = Temp;

	// Atualiza HotbarItemIDs para compatibilidade
	HotbarItemIDs[HotbarSlot] = HotbarItens[HotbarSlot].Quantidade > 0 ? HotbarItens[HotbarSlot].ItemID : TEXT("");

	UE_LOG(LogTemp, Log, TEXT("[Inventário] Item transferido fisicamente entre Mochila[%d] e Hotbar[%d]."), InvSlot, HotbarSlot);

	OnInventarioAtualizado.Broadcast();
	return true;
}

bool UAC_Inventario::MoverHotbarParaInventario(int32 HotbarSlot, int32 InvSlot)
{
	return MoverInventarioParaHotbar(InvSlot, HotbarSlot);
}

bool UAC_Inventario::TrocarSlotsHotbar(int32 DeHotbarIndex, int32 ParaHotbarIndex)
{
	if (DeHotbarIndex < 0 || DeHotbarIndex >= 6 || ParaHotbarIndex < 0 || ParaHotbarIndex >= 6 || DeHotbarIndex == ParaHotbarIndex)
	{
		return false;
	}

	if (HotbarItens.Num() < 6)
	{
		HotbarItens.Init(FItemInventario(), 6);
	}

	HotbarItens.Swap(DeHotbarIndex, ParaHotbarIndex);
	HotbarItemIDs[DeHotbarIndex] = HotbarItens[DeHotbarIndex].Quantidade > 0 ? HotbarItens[DeHotbarIndex].ItemID : TEXT("");
	HotbarItemIDs[ParaHotbarIndex] = HotbarItens[ParaHotbarIndex].Quantidade > 0 ? HotbarItens[ParaHotbarIndex].ItemID : TEXT("");

	OnInventarioAtualizado.Broadcast();
	return true;
}

bool UAC_Inventario::EquiparHotbar(int32 HotbarIndex, FString ItemID)
{
	if (!HotbarItens.IsValidIndex(HotbarIndex))
	{
		return false;
	}

	FItemInventario ItemEncontrado;
	if (BuscarItemNaTabela(FName(*ItemID), ItemEncontrado))
	{
		ItemEncontrado.Quantidade = 1;
		HotbarItens[HotbarIndex] = ItemEncontrado;
	}
	else
	{
		HotbarItens[HotbarIndex].ItemID = ItemID;
		HotbarItens[HotbarIndex].Quantidade = 1;
	}

	HotbarItemIDs[HotbarIndex] = ItemID;
	UE_LOG(LogTemp, Warning, TEXT("[Hotbar] Item '%s' equipado no atalho %d da Hotbar."), *ItemID, HotbarIndex + 1);

	OnInventarioAtualizado.Broadcast();
	return true;
}

bool UAC_Inventario::UsarHotbar(int32 HotbarIndex)
{
	if (!HotbarItens.IsValidIndex(HotbarIndex) || HotbarItens[HotbarIndex].Quantidade <= 0)
	{
		return false;
	}

	FItemInventario& Item = HotbarItens[HotbarIndex];
	if (!Item.bConsumivel)
	{
		UE_LOG(LogTemp, Warning, TEXT("[Hotbar] O item '%s' no atalho %d não é consumível."), *Item.ItemID, HotbarIndex + 1);
		return false;
	}

	AActor* Owner = GetOwner();
	if (Owner)
	{
		UAC_Atributos* Atributos = Owner->FindComponentByClass<UAC_Atributos>();
		if (Atributos)
		{
			if (Item.ItemID.Contains(TEXT("mana")) || Item.ItemID.Contains(TEXT("ether")))
			{
				Atributos->ModificarMana(Item.ValorEfeito > 0.0f ? Item.ValorEfeito : 30.0f);
			}
			else
			{
				Atributos->Curar(Item.ValorEfeito > 0.0f ? Item.ValorEfeito : 50.0f);
			}
		}
	}

	Item.Quantidade -= 1;
	if (Item.Quantidade <= 0)
	{
		Item = FItemInventario();
		HotbarItemIDs[HotbarIndex] = TEXT("");
	}

	UE_LOG(LogTemp, Log, TEXT("[Hotbar] Usado 1x item do atalho %d. Quantidade restante: %d"), HotbarIndex + 1, Item.Quantidade);

	OnInventarioAtualizado.Broadcast();
	return true;
}

bool UAC_Inventario::GetItemHotbar(int32 HotbarIndex, FItemInventario& OutItem) const
{
	OutItem = FItemInventario();
	if (HotbarItens.IsValidIndex(HotbarIndex) && HotbarItens[HotbarIndex].Quantidade > 0)
	{
		OutItem = HotbarItens[HotbarIndex];
		return true;
	}

	return false;
}

bool UAC_Inventario::AdicionarItem(FItemInventario NovoItem)
{
	if (NovoItem.ItemID.IsEmpty() || NovoItem.Quantidade <= 0)
	{
		return false;
	}

	GarantirTamanhoSlots();

	// 1. Tenta empilhar em um slot existente que ainda não está cheio
	for (int32 i = 0; i < CapacidadeMaxima; ++i)
	{
		FItemInventario& Item = Itens[i];
		if (Item.Quantidade > 0 && Item.ItemID.Equals(NovoItem.ItemID, ESearchCase::IgnoreCase))
		{
			int32 EspacoRestante = Item.QuantidadeMaximaStack - Item.Quantidade;
			if (EspacoRestante > 0)
			{
				int32 QtdAdicionar = FMath::Min(EspacoRestante, NovoItem.Quantidade);
				Item.Quantidade += QtdAdicionar;
				NovoItem.Quantidade -= QtdAdicionar;

				UE_LOG(LogTemp, Log, TEXT("[Inventário] Empilhado %dx de '%s' no slot %d. Total: %d"),
					QtdAdicionar, *Item.ItemID, i, Item.Quantidade);

				if (NovoItem.Quantidade <= 0)
				{
					OnInventarioAtualizado.Broadcast();
					return true;
				}
			}
		}
	}

	// 2. Se sobrou quantidade, encontra o primeiro slot livre (sem encolher nem inflar o array)
	for (int32 i = 0; i < CapacidadeMaxima && NovoItem.Quantidade > 0; ++i)
	{
		FItemInventario& Item = Itens[i];
		if (Item.Quantidade <= 0 || Item.ItemID.IsEmpty() || Item.ItemID == TEXT("none"))
		{
			Item = NovoItem;
			Item.Quantidade = FMath::Min(NovoItem.Quantidade, NovoItem.QuantidadeMaximaStack);
			NovoItem.Quantidade -= Item.Quantidade;

			UE_LOG(LogTemp, Warning, TEXT("[Inventário] Novo item alocado no slot %d: '%s' (Qtd: %d)."),
				i, *Item.ItemID, Item.Quantidade);
		}
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

	GarantirTamanhoSlots();
	int32 RestanteParaRemover = Quantidade;

	for (int32 i = CapacidadeMaxima - 1; i >= 0; --i)
	{
		if (Itens[i].Quantidade > 0 && Itens[i].ItemID.Equals(ItemID, ESearchCase::IgnoreCase))
		{
			if (Itens[i].Quantidade <= RestanteParaRemover)
			{
				RestanteParaRemover -= Itens[i].Quantidade;
				Itens[i] = FItemInventario(); // esvazia o slot sem encolher o array!
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
	GarantirTamanhoSlots();
	if (!Itens.IsValidIndex(SlotIndex) || Itens[SlotIndex].Quantidade <= 0)
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
			if (Item.ItemID.Contains(TEXT("mana")) || Item.ItemID.Contains(TEXT("ether")))
			{
				Atributos->ModificarMana(Item.ValorEfeito > 0.0f ? Item.ValorEfeito : 30.0f);
			}
			else
			{
				Atributos->Curar(Item.ValorEfeito > 0.0f ? Item.ValorEfeito : 50.0f);
			}
		}
	}

	// Consome 1 unidade do item
	Item.Quantidade--;
	if (Item.Quantidade <= 0)
	{
		Item = FItemInventario(); // esvazia o slot sem encolher o array!
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

	GarantirTamanhoSlots();
	Itens.Swap(DeIndex, ParaIndex);
	UE_LOG(LogTemp, Warning, TEXT("[Inventário] Trocados os slots %d e %d."), DeIndex, ParaIndex);

	OnInventarioAtualizado.Broadcast();
	return true;
}

void UAC_Inventario::LimparInventario()
{
	Itens.Init(FItemInventario(), CapacidadeMaxima);
	HotbarItens.Init(FItemInventario(), 6);
	HotbarItemIDs.Init(TEXT(""), 6);
	OnInventarioAtualizado.Broadcast();
	UE_LOG(LogTemp, Log, TEXT("[Inventário] Todo o inventário foi limpo (28 slots vazios)."));
}
