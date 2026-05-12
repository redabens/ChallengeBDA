@echo off
setlocal

:: Configuration
set VENV_PATH=.venv
set PSQL_PATH="C:\Program Files\PostgreSQL\18\bin\psql.exe"
set DB_NAME=soumiatech_db
set DB_USER=postgres

echo [1/2] Ingestion des donnees via Python...
%VENV_PATH%\Scripts\python.exe ingest_orders.py
if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de l'ingestion Python.
    exit /b %ERRORLEVEL%
)

echo [2/2] Declenchement de la transformation SQL...
:: Note: PGPASSWORD doit etre configure dans l'environnement ou utiliser un fichier .pgpass
%PSQL_PATH% -U %DB_USER% -d %DB_NAME% -c "CALL sp_transform_staging_to_core();"

echo Pipeline termine avec succes !
pause
