#!/usr/bin/env python3
"""print-capt-status.py <принтер>

Настоящее состояние принтера Canon CAPT — то, которого CUPS не знает.

CUPS про этот принтер умеет сказать только «idle»: счётчик страниц, спящий
режим, открытая крышка и кончившаяся бумага живут внутри проприетарного
демона ccpd и наружу через IPP не выходят вовсе (`lpstat -l` показывает
`Alerts: none` всегда).

Демон, однако, отвечает по TCP на порт из /etc/ccpd.conf — тот самый, к
которому ходит родная гуишка captstatusui. Протокол снят с живого обмена
strace и оказался простым:

    запрос:  b"ccp0" | u32 команда | u32 длина тела | тело
    ответ:   b"ccp1" | u32 тип     | u32 длина тела | тело

Строки в теле — length-prefixed: u32 длины и байты без нуля на конце. Команда
1 возвращает XML в формате Printer-MIB, где в PrtAlertTable лежит то, что
показывает лампочка на корпусе.

Печатает JSON. Отсутствие ответа — не ошибка скрипта: демон мог не успеть
подняться, и панель должна это пережить.
"""

import json
import re
import socket
import struct
import sys
import xml.etree.ElementTree as ET

MAGIC_OUT = b"ccp0"
MAGIC_IN = b"ccp1"

CMD_HELLO = 0x13
CMD_STATUS = 0x01

LOCALE = b"en_GB.UTF-8"

CONF = "/etc/ccpd.conf"
DEFAULT_PORT = 59787

def ui_port(path=CONF):
    """Порт берётся из конфига демона, а не зашивается: он настраиваемый."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            m = re.search(r"UI_Port\s+(\d+)", f.read())
            if m:
                return int(m.group(1))
    except OSError:
        pass
    return DEFAULT_PORT

def lstr(text):
    return struct.pack("<I", len(text)) + text

def request(cmd, printer, extra=b""):
    body = lstr(printer) + lstr(LOCALE) + extra
    return MAGIC_OUT + struct.pack("<II", cmd, len(body)) + body

def read_exactly(sock, n):
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise EOFError("демон закрыл соединение")
        buf += chunk
    return buf

def exchange(sock, payload):
    sock.sendall(payload)
    head = read_exactly(sock, 12)
    if head[:4] != MAGIC_IN:
        raise ValueError("чужой ответ: %r" % head[:4])
    kind, length = struct.unpack("<II", head[4:12])
    body = read_exactly(sock, length) if length else b""
    return kind, body

def alerts_from(xml_bytes):
    """PrtAlertTable → список тревог. Пустой список означает «всё в порядке»."""
    out = []
    try:
        root = ET.fromstring(xml_bytes.decode("utf-8", "replace"))
    except ET.ParseError:
        return out

    for entry in root.iter("PrtAlertEntry"):
        code = entry.findtext("PrtAlertCode", "").strip()
        if not code:
            continue
        out.append({
            "code": code,
            "severity": entry.findtext("PrtAlertSeverityLevel", "").strip(),
            "text": " ".join(entry.findtext("PrtAlertDescription", "").split()),
        })
    return out

def fail(code, message):
    print(json.dumps({"ok": False, "code": code, "error": message},
                     ensure_ascii=False))
    return 0

def main():
    if len(sys.argv) < 2 or not sys.argv[1]:
        return fail("noprinter", "принтер не указан")

    printer = sys.argv[1].encode("utf-8")
    port = ui_port()

    try:
        sock = socket.create_connection(("127.0.0.1", port), timeout=3)
    except OSError as e:
        return fail("nodaemon", "ccpd не отвечает на порту %d: %s" % (port, e))

    sock.settimeout(3)
    try:
        exchange(sock, request(CMD_HELLO, printer,
                               struct.pack("<II", 4, 0)))
        kind, body = exchange(sock, request(CMD_STATUS, printer,
                                            struct.pack("<I", 0)))
    except (OSError, EOFError, ValueError) as e:
        sock.close()
        return fail("protocol", "обмен не удался: %s" % e)
    sock.close()

    alerts = alerts_from(body)
    print(json.dumps({
        "ok": True,
        "port": port,
        "kind": kind,
        "alerts": alerts,
        "code": alerts[0]["code"] if alerts else "",
        "text": alerts[0]["text"] if alerts else "",
    }, ensure_ascii=False))
    return 0

if __name__ == "__main__":
    sys.exit(main())
