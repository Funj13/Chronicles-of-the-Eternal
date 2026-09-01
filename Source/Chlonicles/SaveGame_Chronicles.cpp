// Fill out your copyright notice in the Description page of Project Settings.

#include "SaveGame_Chronicles.h"

USaveGame_Chronicles::USaveGame_Chronicles()
{
	SaveSlotName = TEXT("ChroniclesSaveSlot");
	UserIndex = 0;

	SavedLocation = FVector::ZeroVector;
	SavedRotation = FRotator::ZeroRotator;
	SavedMapName = TEXT("");

	SavedVidaAtual = 100.0f;
	SavedVidaMax = 100.0f;
	SavedManaAtual = 80.0f;
	SavedManaMax = 80.0f;
	SavedNivel = 1;
	SavedXPAtual = 0.0f;
	SavedXPMax = 100.0f;
	SavedGodMode = false;
}
