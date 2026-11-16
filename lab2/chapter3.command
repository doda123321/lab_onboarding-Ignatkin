#!/bin/bash
# WSM: целые веса 0..100, оценки 1..5; больше всегда лучше.
set -e
number() {
    local value
    while true; do
        printf '%s [%s-%s]: ' "$1" "$2" "$3"
        if ! IFS= read -r value; then
            printf '\nВвод завершён. Модуль прерван.\n' >&2; exit 1
        fi
        # Проверка до арифметики: исключаем выражения, переполнение, дроби.
        if [[ $value =~ ^[0-9]{1,3}$ ]]; then
            answer=$((10#$value))
            if (( answer >= $2 && answer <= $3 )); then return; fi
        fi
        printf 'Ошибка: требуется целое число от %s до %s.\n' "$2" "$3"
    done
}
names=('Sublime Text' 'Atom' 'Notepad++')
criteria=('Скорость работы' 'Наличие плагинов' 'Доступность лицензии')
printf '=== Модуль 3. Сравнение редакторов (WSM) ===\n'
printf 'Команда: 8 разработчиков, ограниченный бюджет.\n'
printf 'Оценки 1..5: больше — лучше; лицензия: 5 = бесплатно/доступно, 1 = дорого.\n'
printf 'Оценивайте пригодность для своей ОС и актуальность плагинов: Atom не поддерживается, Notepad++ нативно для Windows.\n'
while true; do
    for k in 0 1 2; do
        number "Вес: ${criteria[$k]}" 0 100; weights[$k]=$answer
    done
    sum=$((weights[0]+weights[1]+weights[2]))
    if (( sum == 100 )); then break; fi
    printf 'Ошибка: сумма весов = %s, требуется 100. Введите все веса заново.\n' "$sum"
done
best=-1; winners=''; count=0
for i in 0 1 2; do
    scores[$i]=0
    for k in 0 1 2; do
        number "${names[$i]} — ${criteria[$k]}" 1 5
        ratings[$((i*3+k))]=$answer
        scores[$i]=$((scores[i]+weights[k]*answer))
    done
    if (( scores[i] > best )); then
        best=${scores[$i]}; winners=${names[$i]}; count=1
    elif (( scores[i] == best )); then
        winners="$winners, ${names[$i]}"; count=$((count+1))
    fi
done
summary() {
    printf '\n=== Результат модуля 3: матрица решений ===\n'
    printf 'Критерий | Вес | Sublime Text | Atom | Notepad++\n'
    for k in 0 1 2; do
        printf '%s | %s | %s | %s | %s\n' "${criteria[$k]}" "${weights[$k]}" "${ratings[$k]}" "${ratings[$((3+k))]}" "${ratings[$((6+k))]}"
    done
    printf 'ИТОГО S = Σ(W × X) | 100 | %s | %s | %s\n' "${scores[0]}" "${scores[1]}" "${scores[2]}"
    printf 'Веса заданы в процентах; S от 100 до 500, нормированный балл = S/100.\n'
    printf 'Победитель сравнительного анализа: %s\n' "$winners"
    if (( count > 1 )); then printf 'Равенство баллов: все перечисленные альтернативы делят первое место.\n'; fi
}
summary
if [[ -n ${LAB_RESULT:-} ]]; then summary > "$LAB_RESULT"; fi
if [[ -t 0 && ${LAB_MENU:-0} != 1 ]]; then
    read -r -p 'Нажмите Enter для закрытия...' || true
fi
