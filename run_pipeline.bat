@echo off
setlocal

:: Configuration
set VENV_PATH=.venv
set PSQL_PATH="C:\Program Files\PostgreSQL\18\bin\psql.exe"
set DB_NAME=soumiatech_db
set DB_USER=postgres

echo [1/1] Ingestion et Transformation automatique...
%VENV_PATH%\Scripts\python.exe ingest_orders.py
if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors du pipeline.
    exit /b %ERRORLEVEL%
)

echo Pipeline termine avec succes ! (Le Trigger SQL a gere la transformation)
pause
