@echo off
chcp 65001 >nul

REM ============================================================
REM Практическая работа: диагностика клиентского компьютера
REM Автор: Игнаткин
REM Дата: 26.10.2026
REM ============================================================

REM --- Путь к отчёту: файл лежит рядом с pc_info.bat ---
set "REPORT=%~dp0pc_report.txt"

REM --- Заголовок (первая запись создаёт/перезаписывает файл) ---
>"%REPORT%" echo ==============================
>>"%REPORT%" echo    Диагностика компьютера
>>"%REPORT%" echo ==============================
>>"%REPORT%" echo.

REM --- Операционная система ---
>>"%REPORT%" echo Операционная система
>>"%REPORT%" echo ------------------------------
for /f "tokens=2 delims==" %%a in ('wmic os get Caption /format:list') do >>"%REPORT%" echo Название: %%a
for /f "tokens=2 delims==" %%a in ('wmic os get Version /format:list') do >>"%REPORT%" echo Версия: %%a
>>"%REPORT%" echo.

REM --- Процессор ---
>>"%REPORT%" echo Процессор
>>"%REPORT%" echo ------------------------------
for /f "tokens=2 delims==" %%a in ('wmic cpu get Name /format:list') do >>"%REPORT%" echo %%a
>>"%REPORT%" echo.

REM --- Оперативная память (значения в КБ, переводим в ГБ) ---
>>"%REPORT%" echo Оперативная память
>>"%REPORT%" echo ------------------------------
for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:list') do set /a TOTAL_GB=%%a/1048576
for /f "tokens=2 delims==" %%a in ('wmic os get FreePhysicalMemory /format:list') do set /a FREE_GB=%%a/1048576
>>"%REPORT%" echo Всего памяти: %TOTAL_GB% ГБ
>>"%REPORT%" echo Свободно памяти: %FREE_GB% ГБ
>>"%REPORT%" echo.

REM --- Диск C (значения в байтах, переводим в ГБ) ---
REM set /a работает с числами до ~2 млрд, а размер диска в байтах больше,
REM поэтому сначала отбрасываем 6 последних цифр (получаем МБ), затем делим на 1074.
>>"%REPORT%" echo Диск C
>>"%REPORT%" echo ------------------------------
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='C:'" get Size /format:list') do set "DISK_SIZE=%%a"
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /format:list') do set "DISK_FREE=%%a"
set /a DISK_SIZE_GB=%DISK_SIZE:~0,-6%/1074
set /a DISK_FREE_GB=%DISK_FREE:~0,-6%/1074
>>"%REPORT%" echo Всего: %DISK_SIZE_GB% ГБ
>>"%REPORT%" echo Свободно: %DISK_FREE_GB% ГБ
>>"%REPORT%" echo.

REM --- Установленные программы (через реестр) ---
>>"%REPORT%" echo Установленные программы
>>"%REPORT%" echo ------------------------------
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s ^| findstr /R /C:"^ *DisplayName  *REG_SZ"') do >>"%REPORT%" echo %%b
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s ^| findstr /R /C:"^ *DisplayName  *REG_SZ"') do >>"%REPORT%" echo %%b
>>"%REPORT%" echo.

REM --- Вывод отчёта в окно (то же, что записано в файл) ---
type "%REPORT%"

REM --- Сообщение о сохранении ---
echo ------------------------------
echo Отчёт сохранён

pause