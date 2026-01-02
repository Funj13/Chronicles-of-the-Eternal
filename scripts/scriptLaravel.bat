@echo off
setlocal enabledelayedexpansion

echo =======================================
echo   Iniciando script do Projeto Laravel
echo =======================================

set /p nome_projeto=Digite o nome do projeto:

echo Criando projeto %nome_projeto% com Laravel na Versão 12...
composer create-project --prefer-dist laravel/laravel %nome_projeto%

if %errorlevel% neq 0 (
    echo Erro ao criar o projeto Laravel. Verifique o Composer.
    exit /b
)

echo Projeto %nome_projeto% criado com sucesso!

cd %nome_projeto%

echo Instalando JetStream com Livewire...
composer require laravel/jetstream
php artisan jetstream:install livewire

echo Instalando dependências do JetStream...
npm install
npm run build

echo Instalando Spatie Laravel Permission...
composer require spatie/laravel-permission
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag="config"
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag="migrations"

echo Executando migrações...
php artisan migrate

echo.
echo ==============================
echo Projeto %nome_projeto% finalizado com sucesso!
echo ==============================

pause
