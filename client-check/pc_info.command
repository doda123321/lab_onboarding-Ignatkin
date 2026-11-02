#!/bin/bash

# ============================================================
# Практическая работа 8, часть 2: диагностика и аудит клиентского ПК (macOS)
# Автор: Игнаткин
# Дата: 02.11.2026
#
# Скрипт собирает сведения о компьютере, сверяет установленные программы
# с эталонными списками и формирует рекомендации для администратора.
# Рекомендации — это повод проверить, а не указание удалять.
#
# Проверка логики: EXTRA_APPS="uTorrent|Keka" ./pc_info.command
# (добавляет тестовые названия в список программ, в отчёте это отмечается)
# ============================================================

# --- Работаем в папке, где лежит сам файл ---
cd "$(dirname "$0")" || exit 1
REPORT="$(pwd)/pc_report.txt"

# --- Временный файл со списком программ; удаляется при любом выходе ---
APPS=$(mktemp "${TMPDIR:-/tmp}/apps_list.XXXXXX")
trap 'rm -f "$APPS"' EXIT

# --- Счётчики для итога ---
BASIC_CHECKED=0     # сколько категорий базового ПО проверено
UNWANTED_CHECKED=0  # сколько групп нежелательного ПО проверено
RECS=0              # сколько рекомендаций выдано

# ------------------------------------------------------------
# Подпрограммы (в bash их описывают ДО использования)
# ------------------------------------------------------------

# log "текст" — выводит строку на экран и дописывает в отчёт.
# printf вместо echo: пустой аргумент даёт пустую строку, а символы
# < > & | в тексте не воспринимаются как команды.
log() {
    printf '%s\n' "$1" | tee -a "$REPORT"
}

# say "текст" — сообщение о ходе работы, только на экран.
say() {
    printf '>>> %s\n' "$1"
}

# value_or_fail "значение" — само значение или понятное сообщение об ошибке.
value_or_fail() {
    if [ -n "$1" ]; then
        printf '%s' "$1"
    else
        printf 'не удалось получить данные'
    fi
}

# check_basic "Категория" "regex" "Совет" ["regex системных компонентов"]
# Ищет в списке программ хотя бы одно название из regex (без учёта регистра).
# Найдено — отметка [OK] и название; не найдено — рекомендация [!].
# Если все найденные программы — компоненты macOS, это отмечается отдельно:
# их наличие не говорит о том, что рабочее место настроено.
check_basic() {
    local title="$1" regex="$2" advice="$3" sysregex="$4"
    local found nonsys note=""
    BASIC_CHECKED=$((BASIC_CHECKED + 1))
    found=$(grep -iE "$regex" "$APPS" | head -3 | paste -sd, - | sed 's/,/, /g')
    if [ -n "$found" ]; then
        if [ -n "$sysregex" ]; then
            nonsys=$(grep -iE "$regex" "$APPS" | grep -ivE "$sysregex")
            [ -z "$nonsys" ] && note=" (компонент системы, а не результат настройки)"
        fi
        log "[OK] $title: $found$note"
    else
        log "[!]  $title: не обнаружено. $advice"
        RECS=$((RECS + 1))
    fi
}

# check_unwanted "Группа" "regex"
# Ищет программы группы нежелательного ПО и выводит найденные названия.
check_unwanted() {
    local title="$1" regex="$2"
    local found
    UNWANTED_CHECKED=$((UNWANTED_CHECKED + 1))
    found=$(grep -iE "$regex" "$APPS")
    if [ -n "$found" ]; then
        log "[?]  $title: найдено, рекомендуется проверить необходимость:"
        printf '%s\n' "$found" | while IFS= read -r app; do
            log "       - $app"
        done
        RECS=$((RECS + 1))
    else
        log "[OK] $title: ничего не найдено"
    fi
}

# ------------------------------------------------------------
# Заголовок отчёта (первая запись перезаписывает старый файл)
# ------------------------------------------------------------
: > "$REPORT"
log "=============================="
log "   Диагностика компьютера"
log "=============================="
log "Отчёт сформирован: $(date '+%d.%m.%Y %H:%M:%S')"
log ""

# ------------------------------------------------------------
# Операционная система
# ------------------------------------------------------------
say "Собираю сведения о системе..."
OS_NAME=""; OS_VER=""
OS_NAME=$(sw_vers -productName 2>/dev/null)
OS_VER=$(sw_vers -productVersion 2>/dev/null)
log "Операционная система"
log "------------------------------"
log "Название: $(value_or_fail "$OS_NAME")"
log "Версия: $(value_or_fail "$OS_VER")"
log ""

# ------------------------------------------------------------
# Процессор
# ------------------------------------------------------------
CPU=""
CPU=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
log "Процессор"
log "------------------------------"
log "$(value_or_fail "$CPU")"
log ""

# ------------------------------------------------------------
# Оперативная память (переводим в ГБ)
# ------------------------------------------------------------
TOTAL_B=""; PAGE=""; FREE_PAGES=""; TOTAL_GB=""; FREE_GB=""
TOTAL_B=$(sysctl -n hw.memsize 2>/dev/null)
PAGE=$(vm_stat 2>/dev/null | awk '/page size of/ {print $8}')
FREE_PAGES=$(vm_stat 2>/dev/null | awk '/Pages free|Pages inactive|Pages speculative/ {gsub("\\.","",$NF); s+=$NF} END {print s}')
[ -n "$TOTAL_B" ] && TOTAL_GB=$((TOTAL_B / 1073741824))
[ -n "$PAGE" ] && [ -n "$FREE_PAGES" ] && FREE_GB=$(awk -v p="$FREE_PAGES" -v s="$PAGE" 'BEGIN {printf "%.1f", p*s/1073741824}')
log "Оперативная память"
log "------------------------------"
log "Всего памяти: $(value_or_fail "${TOTAL_GB:+$TOTAL_GB ГБ}")"
log "Свободно памяти: $(value_or_fail "${FREE_GB:+$FREE_GB ГБ}")"
log ""

# ------------------------------------------------------------
# Диск (переводим КБ в ГБ)
# ------------------------------------------------------------
DISK_TOTAL_KB=""; DISK_FREE_KB=""; DISK_TOTAL_GB=""; DISK_FREE_GB=""
read -r DISK_TOTAL_KB DISK_FREE_KB < <(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $2, $4}')
[ -n "$DISK_TOTAL_KB" ] && DISK_TOTAL_GB=$((DISK_TOTAL_KB / 1048576))
[ -n "$DISK_FREE_KB" ] && DISK_FREE_GB=$((DISK_FREE_KB / 1048576))
log "Диск"
log "------------------------------"
log "Всего: $(value_or_fail "${DISK_TOTAL_GB:+$DISK_TOTAL_GB ГБ}")"
log "Свободно: $(value_or_fail "${DISK_FREE_GB:+$DISK_FREE_GB ГБ}")"
log ""

# ------------------------------------------------------------
# Список установленных программ -> временный файл
# Опрашиваем все стандартные места: общие, пользовательские и системные
# программы. Оставляем только названия, сортируем и убираем повторы.
# ------------------------------------------------------------
say "Идёт поиск установленных программ..."
{
    ls /Applications
    ls "$HOME/Applications"
    ls /System/Applications
    ls /System/Applications/Utilities
    ls /System/Library/CoreServices/Applications
} 2>/dev/null | grep '\.app$' | sed 's/\.app$//' | sort -u > "$APPS"

# Режим проверки логики: добавляем тестовые названия из EXTRA_APPS
if [ -n "$EXTRA_APPS" ]; then
    printf '%s\n' "$EXTRA_APPS" | tr '|' '\n' >> "$APPS"
    sort -u "$APPS" -o "$APPS"
fi

log "Установленные программы"
log "------------------------------"
if [ -s "$APPS" ]; then
    while IFS= read -r app; do
        log "$app"
    done < "$APPS"
else
    log "не удалось получить данные"
fi
log ""

# ------------------------------------------------------------
# Анализ: базовое ПО для офисной работы
# Выбор категорий: документы, интернет, PDF, архивы, защита от вирусов.
# ------------------------------------------------------------
say "Анализирую базовое ПО..."
log "=============================="
log "Проверка базового ПО"
log "=============================="
[ -n "$EXTRA_APPS" ] && log "ВНИМАНИЕ: в список добавлены тестовые данные: $EXTRA_APPS" && log ""

check_basic "Офисный пакет" \
    'Microsoft (Word|Excel)|Office|LibreOffice|OpenOffice|МойОфис|Pages|Numbers' \
    "Для работы с документами рекомендуется установить LibreOffice или Microsoft Office."
check_basic "Браузер" \
    'Chrome|Firefox|Edge|Yandex|Яндекс|Safari|Opera|Brave' \
    "Для работы с веб-сервисами рекомендуется установить Chrome или Firefox." \
    'Safari'
check_basic "Просмотр PDF" \
    'Acrobat|Foxit|Sumatra|PDF Expert|Preview|Adobe Reader|Skim' \
    "Для чтения документов рекомендуется установить Adobe Acrobat Reader или PDF Expert." \
    'Preview'
check_basic "Архиватор" \
    '7-Zip|WinRAR|WinZip|Keka|Unarchiver|BetterZip|Archive Utility' \
    "Для работы с вложениями в почте рекомендуется установить Keka или The Unarchiver." \
    'Archive Utility'
check_basic "Антивирус" \
    'Defender|Kaspersky|ESET|Dr\.Web|Malwarebytes|Avast|AVG|Sophos|Bitdefender|Norton|McAfee' \
    "Встроенная защита macOS (XProtect) есть, но для рабочего места рекомендуется корпоративный антивирус, например Kaspersky или ESET."
log ""

# ------------------------------------------------------------
# Анализ: ПО, не относящееся к базовым офисным задачам
# Это перечень признаков для проверки, а не приказ удалять.
# ------------------------------------------------------------
say "Анализирую излишнее ПО..."
log "=============================="
log "Проверка излишнего ПО"
log "=============================="
check_unwanted "Игры и игровые платформы" \
    'Steam|Epic Games|GOG|Origin|Ubisoft|Battle\.net|Riot|Roblox|Minecraft|game|gaming'
check_unwanted "Торрент-клиенты" \
    'torrent|Vuze|Transmission'
check_unwanted "Мессенджеры для личного общения" \
    'Discord|Telegram|WhatsApp|Viber|Skype'
check_unwanted "Развлекательные инструменты" \
    'Wallpaper Engine|^OBS( |$)|Soundpad|VLC|Spotify|IINA'
log ""
log "ВАЖНО: это рекомендации к проверке, а не указание к удалению. Часть программ"
log "может быть установлена по согласованию с руководством. Решение принимает человек."
log ""

# ------------------------------------------------------------
# Итог
# ------------------------------------------------------------
log "=============================="
log "Итог"
log "=============================="
log "Категорий базового ПО проверено: $BASIC_CHECKED"
log "Групп излишнего ПО проверено: $UNWANTED_CHECKED"
log "Выдано рекомендаций: $RECS"
log "Отчёт сохранён: $REPORT"
echo

# --- Ждём нажатия клавиши, чтобы окно не закрылось сразу ---
read -n 1 -s -r -p "Нажмите любую клавишу для выхода..."
echo
