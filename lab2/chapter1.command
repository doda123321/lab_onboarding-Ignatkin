#!/bin/bash
# Вариант 2. Числовой профиль и учебная балльная модель выбора.
set -e
ask() {
    local value
    while true; do
        printf '%s [1-2]: ' "$1"
        if ! IFS= read -r value; then
            printf '\nВвод завершён. Модуль прерван.\n' >&2; exit 1
        fi
        case "$value" in 1|2) answer=$value; return;; esac
        printf 'Ошибка: введите 1 или 2.\n'
    done
}
pause_end() {
    if [[ -t 0 && ${LAB_MENU:-0} != 1 ]]; then
        read -r -p 'Нажмите Enter для закрытия...' || true
    fi
}
printf '=== Модуль 1. Выбор текстового редактора ===\n'
printf 'Команда: 8 разработчиков, ограниченный бюджет. Баллы — учебная модель.\n'
printf 'Atom: поддержка прекращена; Notepad++: нативно только Windows.\n'
score_sublime=0; score_atom=0; score_notepadpp=0
ask 'Масштаб файлов: 1 — крупные, 2 — небольшие'
scale=$answer
if [[ $scale == 1 ]]; then
    score_sublime=$((score_sublime+3)); score_notepadpp=$((score_notepadpp+1))
else
    score_atom=$((score_atom+2)); score_notepadpp=$((score_notepadpp+2))
fi
ask 'Бюджет на 8 лицензий: 1 — средств нет, 2 — ограниченные средства есть'
budget=$answer
if [[ $budget == 1 ]]; then
    score_atom=$((score_atom+3)); score_notepadpp=$((score_notepadpp+3))
else
    score_sublime=$((score_sublime+3))
fi
ask 'Срок внедрения: 1 — один день, 2 — есть время на настройку'
deadline=$answer
if [[ $deadline == 1 ]]; then
    score_sublime=$((score_sublime+2)); score_notepadpp=$((score_notepadpp+2))
else
    score_atom=$((score_atom+2))
fi
ask 'Квалификация команды в настройке редакторов: 1 — начинающие, 2 — опытные'
skill=$answer
if [[ $skill == 1 ]]; then
    score_notepadpp=$((score_notepadpp+2))
else
    score_sublime=$((score_sublime+1)); score_atom=$((score_atom+2))
fi
ask 'Плагины: 1 — достаточно базовых функций, 2 — нужна глубокая настройка'
plugins=$answer
if [[ $plugins == 1 ]]; then
    score_notepadpp=$((score_notepadpp+2))
else
    score_sublime=$((score_sublime+2)); score_atom=$((score_atom+3))
fi
ask 'ОС команды: 1 — только Windows, 2 — есть macOS/Linux'
platform=$answer
# Ограничения важнее баллов: лицензия и нативная совместимость.
names=('Sublime Text' 'Atom' 'Notepad++')
scores=("$score_sublime" "$score_atom" "$score_notepadpp")
eligible=(1 1 1)
[[ $budget != 1 ]] || eligible[0]=0
[[ $platform != 2 ]] || eligible[2]=0
best=-1; winners=''; count=0
for i in 0 1 2; do
    [[ ${eligible[$i]} == 1 ]] || continue
    if (( scores[i] > best )); then
        best=${scores[$i]}; winners=${names[$i]}; count=1
    elif (( scores[i] == best )); then
        winners="$winners, ${names[$i]}"; count=$((count+1))
    fi
done
summary() {
    printf '\n=== Результат модуля 1 ===\n'
    printf 'Профиль: масштаб=%s; бюджет=%s; сроки=%s; квалификация=%s; плагины=%s; ОС=%s\n' "$scale" "$budget" "$deadline" "$skill" "$plugins" "$platform"
    for i in 0 1 2; do
        printf '%s: %s баллов; доступен по бюджету/ОС: %s\n' "${names[$i]}" "${scores[$i]}" "${eligible[$i]}"
    done
    printf 'Рекомендация (учебная модель): %s\n' "$winners"
    if (( count > 1 )); then printf 'Равенство баллов: единственного победителя нет. Нужен пробный запуск.\n'; fi
    if [[ $winners == *Atom* ]]; then
        printf 'Atom не поддерживается: для реального внедрения пересмотрите бюджет или список кандидатов.\n'
    fi
}
summary
if [[ -n ${LAB_RESULT:-} ]]; then summary > "$LAB_RESULT"; fi
pause_end
