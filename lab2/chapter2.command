#!/bin/bash
# Фрагменты стилизованы под Python-код плагинов редакторов; не исполняются.
set -e
correct=0; points=0; total=5
types=('Неинициализированная переменная' 'Мёртвое присваивание' 'Утечка ресурса' 'Магическое число' 'Отсутствие обработки ошибок')
review() {
    local expected=$1 explanation=$2 value i
    for i in 0 1 2 3 4; do printf '%s. %s\n' "$((i+1))" "${types[$i]}"; done
    while true; do
        printf 'Тип дефекта [1-5]: '
        if ! IFS= read -r value; then
            printf '\nВвод завершён. Модуль прерван.\n' >&2; exit 1
        fi
        case "$value" in [1-5]) break;; esac
        printf 'Ошибка: введите целое число от 1 до 5.\n'
    done
    if [[ $value == "$expected" ]]; then
        correct=$((correct+1)); points=$((points+10))
        printf 'Верно! +10 очков.\n'
    else
        points=$((points-5))
        printf 'Неверно. -5 очков. Ответ: %s (%s).\n' "$expected" "${types[$((expected-1))]}"
    fi
    printf '%s\n\n' "$explanation"
}
printf '=== Модуль 2. Ревью кода плагинов редакторов ===\n'
printf 'Правильный ответ: +10; неправильный: -5; ошибочный ввод не считается ответом.\n'
printf '%s\n' 'Фрагмент 1. Команда плагина Sublime Text:' \
    'def selected_text(view):' \
    '    if not view.sel()[0].empty():' \
    '        text = view.substr(view.sel()[0])' \
    '    return text'
review 1 'При пустом выделении локальная переменная text не инициализирована.'
printf '%s\n' 'Фрагмент 2. Конфигурация пакета Atom (псевдокод Python):' \
    'def configure(editor):' \
    '    theme = "light"' \
    '    theme = "dark"' \
    '    editor.set_theme(theme)'
review 2 'Первое значение theme перезаписывается без использования.'
printf '%s\n' 'Фрагмент 3. Журнал плагина Notepad++ (запись успешна):' \
    'def log_action(message):' \
    '    stream = open("plugin.log", "a")' \
    '    stream.write(message)' \
    '    return stream.tell()'
review 3 'Файл явно не закрыт. Используйте with open(...), а не сборщик мусора.'
printf '%s\n' 'Фрагмент 4. Настройка автосохранения редактора:' \
    'def enable_autosave(editor):' \
    '    editor.set_autosave_interval(173)'
review 4 'Назначение и единицы 173 не объяснены; нужна именованная константа.'
printf '%s\n' 'Фрагмент 5. Загрузка конфигурации плагина:' \
    'import json' \
    'def load_settings(path):' \
    '    with open(path, encoding="utf-8") as stream:' \
    '        return json.load(stream)'
review 5 'Нет обработки OSError и JSONDecodeError при отсутствии файла или неверном JSON.'
percentage=$((correct*100/total))
if (( percentage >= 80 )); then level='Senior Reviewer'
elif (( percentage >= 50 )); then level='Middle Reviewer'
else level='Junior Reviewer'; fi
summary() {
    printf '\n=== Результат модуля 2 ===\n'
    printf 'Просмотрено фрагментов: %s\nПравильных ответов: %s из %s\nОчки: %s\nТочность: %s%%\nУровень: %s\n' "$total" "$correct" "$total" "$points" "$percentage" "$level"
}
summary
if [[ -n ${LAB_RESULT:-} ]]; then summary > "$LAB_RESULT"; fi
if [[ -t 0 && ${LAB_MENU:-0} != 1 ]]; then
    read -r -p 'Нажмите Enter для закрытия...' || true
fi
