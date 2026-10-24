"""Исправленная обработка транзакции в системе лояльности."""


def get_balance(user_id):
    """Заглушка: возвращает баланс пользователя."""
    return 1000


def update_balance(user_id, new_balance):
    """Заглушка: сохраняет новый баланс пользователя."""
    return None


def process_transaction(user_id, amount, db_connection):
    # Дефект 1 исправлен: status определён до блока if
    status = "pending"

    if amount > 0:
        status = "approved"
        balance = get_balance(user_id)
        new_balance = balance - amount
        update_balance(user_id, new_balance)

    # Дефект 2 исправлен: лишнее присваивание "Start processing" убрано
    log_entry = "Transaction finished with status: " + status

    # Дефект 3 исправлен: with гарантирует закрытие файла
    with open("audit_log.txt", "w") as file:
        file.write(log_entry)

    return status
