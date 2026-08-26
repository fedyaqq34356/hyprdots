#!/bin/sh

case "${1:-normal}" in
    critical)
        notify-send -u critical -a "test" \
            "Критическое" "Рамка статичная, висит до клика"
        ;;
    burst)
        notify-send -a "test" "Первое" "Проверка стопки"
        sleep 0.6
        notify-send -a "test" "Второе" "Соседи подтягиваются"
        sleep 0.6
        notify-send -a "test" "Третье" "Звук ограничен по частоте"
        sleep 0.6
        notify-send -u critical -a "test" "Четвёртое" "И одно критическое"
        ;;
    *)
        notify-send -a "test" \
            "Тестовое уведомление" "Обводка отсчитывает время, наведи мышь чтобы поставить на паузу"
        ;;
esac
