# Анализ потоков данных (Def-Use)

Нумерация строк по фрагменту из Шага 1.1 (строка 1 — def ...).

python
 1  def process_transaction(user_id, amount, db_connection):
 2      log_entry = "Start processing"
 3
 4      if amount > 0:
 5          status = "approved"
 6          balance = get_balance(user_id)
 7          new_balance = balance - amount
 8          update_balance(user_id, new_balance)
 9
10      log_entry = "Transaction finished with status: " + status
11
12      file = open("audit_log.txt", "w")
13      file.write(log_entry)
14
15      return status


## Цепочки Def-Use

Переменная: log_entry
- Def: строка 2 (log_entry = "Start processing")
- Def: строка 10 (log_entry = "Transaction finished..." + status)
- Use: строка 13 (file.write(log_entry))
- Значение из строки 2 нигде не читается (мёртвое присваивание).

Переменная: status
- Def: строка 5 (status = "approved"), только при amount > 0
- Use: строка 10 (конкатенация строки)
- Use: строка 15 (return status)
- При amount <= 0 Def не выполняется, а Use есть: ошибка.

Переменная: balance
- Def: строка 6 (balance = get_balance(user_id))
- Use: строка 7 (balance - amount)

Переменная: new_balance
- Def: строка 7 (new_balance = balance - amount)
- Use: строка 8 (update_balance(user_id, new_balance))

Переменная: file
- Def: строка 12 (file = open(...))
- Use: строка 13 (file.write(...))
- Закрытия (file.close()) нет: ресурс не освобождается.

Параметры user_id, amount, db_connection:
- Def: строка 1 (параметры функции)
- user_id: Use в строках 6 и 8; amount: Use в строках 4 и 7
- db_connection: не используется

## Дефекты

1. Неинициализированная переменная: status на строке 10 (и 15),
   если amount <= 0. Блок if пропускается, и возникает
   UnboundLocalError.
2. Мёртвое присваивание: log_entry = "Start processing" (строка 2)
   перезаписывается на строке 10 без единого чтения.
3. Утечка ресурса: файл открыт на строке 12 и не закрыт. Данные могут
   не сброситься на диск, дескриптор остаётся занятым.
