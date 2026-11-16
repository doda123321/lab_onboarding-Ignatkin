#!/bin/bash
# Пути привязаны к скрипту, а результаты — к конкретному полному запуску.
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
session=$(mktemp -d "$DIR/.session.XXXXXX")
trap 'rm -rf "$session"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
run_module() {
    local status=0
    LAB_MENU=1 LAB_RESULT="$session/result$1.txt" "$DIR/chapter$1.command" || status=$?
    if (( status != 0 )); then
        printf 'Модуль %s прерван (код %s).\n' "$1" "$status" >&2
        return "$status"
    fi
}
while true; do
    printf '\n=== Система моделирования процессов разработки ПО ===\n'
    printf '1. Модуль выбора технологий\n2. Модуль инспекции кода\n3. Модуль сравнительного анализа\n4. Запустить все модули последовательно\n5. Выход\nВаш выбор: '
    if ! IFS= read -r choice; then printf '\nВвод завершён. Выход.\n'; exit 0; fi
    case "$choice" in
        1|2|3) run_module "$choice" || exit 1;;
        4)
            for module in 1 2 3; do run_module "$module" || exit 1; done
            # Сначала собираем полный отчёт, затем атомарно заменяем предыдущий.
            {
                printf '=== Итоговый отчёт системы: лабораторная №2, вариант 2 ===\n'
                printf 'Игнаткин Матвей Сергеевич, группа 3525П1ИН1\n'
                printf 'Время запуска отчёта: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
                for module in 1 2 3; do
                    while IFS= read -r line; do printf '%s\n' "$line"; done < "$session/result$module.txt"
                done
            } > "$session/report.txt"
            mv -f "$session/report.txt" "$DIR/report.txt"
            while IFS= read -r line; do printf '%s\n' "$line"; done < "$DIR/report.txt"
            printf '\nРезультаты сохранены: %s/report.txt\n' "$DIR"
            ;;
        5) printf 'Работа завершена.\n'; exit 0;;
        *) printf 'Ошибка: выберите пункт от 1 до 5.\n';;
    esac
done
