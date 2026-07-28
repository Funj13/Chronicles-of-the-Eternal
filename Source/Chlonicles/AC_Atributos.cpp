// Fill out your copyright notice in the Description page of Project Settings.


#include "AC_Atributos.h"

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
}

// Chamado quando o jogo começa
void UAC_Atributos::BeginPlay()
{
	Super::BeginPlay();
}

// Cura o personagem. Se Valor <= 0, restaura tudo (Vida e Mana)
void UAC_Atributos::Curar(float Valor)
{
	if (Valor <= 0.f)
	{
		VidaAtual = VidaMax;
		ManaAtual = ManaMax;
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] Cura completa aplicada (Vida e Mana maximizadas)."));
	}
	else
	{
		VidaAtual = FMath::Clamp(VidaAtual + Valor, 0.f, VidaMax);
		UE_LOG(LogTemp, Log, TEXT("[Atributos] Cura de %.1f pontos aplicada. Vida Atual: %.1f"), Valor, VidaAtual);
	}
}

// Modifica a vida atual diretamente (recebe valores positivos ou negativos)
void UAC_Atributos::ModificarVida(float Valor)
{
	// Se for dano (Valor negativo) e God Mode estiver ativo, o dano é ignorado
	if (Valor < 0.f && bGodMode)
	{
		UE_LOG(LogTemp, Warning, TEXT("[Atributos] Dano de %.1f ignorado devido ao God Mode."), -Valor);
		return;
	}

	VidaAtual = FMath::Clamp(VidaAtual + Valor, 0.f, VidaMax);
	UE_LOG(LogTemp, Log, TEXT("[Atributos] Vida modificada em %.1f. Vida Atual: %.1f / %.1f"), Valor, VidaAtual, VidaMax);
}

// Define a vida atual diretamente
void UAC_Atributos::SetVida(float NovaVida)
{
	VidaAtual = FMath::Clamp(NovaVida, 0.f, VidaMax);
	UE_LOG(LogTemp, Log, TEXT("[Atributos] Vida definida diretamente para: %.1f / %.1f"), VidaAtual, VidaMax);
}

// Modifica a mana atual diretamente
void UAC_Atributos::ModificarMana(float Valor)
{
	ManaAtual = FMath::Clamp(ManaAtual + Valor, 0.f, ManaMax);
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

	// Processa múltiplos level ups se o XP for muito alto, limitado ao Nível 99
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
	UE_LOG(LogTemp, Log, TEXT("[Atributos] Mana definida diretamente para: %.1f"), ManaAtual);
}

// Define o Nível diretamente (com Hardcap de Nível 99)
void UAC_Atributos::SetNivel(int32 NovoNivel)
{
	// Limita o nível entre 1 e 99
	Nivel = FMath::Clamp(NovoNivel, 1, 99);
	
	// Multiplicador de 1.5x por nível: XPMax = 100 * (1.5 ^ (Nivel - 1))
	XPMax = 100.0f * FMath::Pow(1.5f, static_cast<float>(Nivel - 1));

	if (Nivel >= 99)
	{
		XPAtual = XPMax;
	}
	else
	{
		XPAtual = FMath::Clamp(XPAtual, 0.f, XPMax);
	}
	
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
	
	// Multiplicador de 1.5x de XP necessário para o próximo nível
	XPMax = 100.0f * FMath::Pow(1.5f, static_cast<float>(Nivel - 1));
	VidaMax += 20.0f;       // Aumenta vida máxima
	ManaMax += 15.0f;       // Aumenta mana máxima
	
	// Restaura a vida e mana completamente ao subir de nível
	VidaAtual = VidaMax;
	ManaAtual = ManaMax;

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
