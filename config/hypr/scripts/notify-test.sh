#!/bin/sh
# Fire a test notification so the popup styling, animation and sound can be
# checked without waiting for a real one.
#
#   notify-test.sh            one normal notification
#   notify-test.sh critical   one critical notification (stays until clicked)
#   notify-test.sh burst      four in a row, to check stacking and rate limiting

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
