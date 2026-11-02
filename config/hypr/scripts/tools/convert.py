#!/usr/bin/env python3
"""Переводит величину из одних единиц в другие и печатает ответ одной JSON-строкой.

    convert.py "100 usd"         → в гривны
    convert.py "5 mi km"         → «в», «to», «in», «у», «->», «=» между ними можно
    convert.py "36.6 c f"

Без второй единицы берётся естественная пара: доллар → гривна, гривна →
доллар, мили → километры, фунты → килограммы. Курсы — официальные курсы НБУ,
кэш живёт шесть часов; без сети используется последний сохранённый. Выход 1 —
запрос не похож на перевод; вызывающая сторона просто ничего не показывает.
"""
import json
import os
import re
import sys
import time
import urllib.request

CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
                     "f", "nbu-rates.json")
NBU = "https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?json"
FRESH = 6 * 3600

UNITS = {
    "length": {
        "mm": 0.001, "cm": 0.01, "dm": 0.1, "m": 1, "km": 1000,
        "in": 0.0254, "ft": 0.3048, "yd": 0.9144, "mi": 1609.344, "nmi": 1852,
    },
    "mass": {
        "mg": 1e-6, "g": 0.001, "kg": 1, "t": 1000,
        "oz": 0.028349523125, "lb": 0.45359237, "st": 6.35029318,
    },
    "volume": {
        "ml": 0.001, "l": 1, "m3": 1000,
        "tsp": 0.00492892159375, "tbsp": 0.01478676478125, "floz": 0.0295735295625,
        "cup": 0.2365882365, "pt": 0.473176473, "qt": 0.946352946, "gal": 3.785411784,
    },
    "area": {
        "mm2": 1e-6, "cm2": 1e-4, "m2": 1, "ha": 1e4, "km2": 1e6,
        "in2": 0.00064516, "ft2": 0.09290304, "ac": 4046.8564224, "mi2": 2589988.110336,
    },
    "speed": {
        "m/s": 1, "km/h": 1 / 3.6, "mph": 0.44704, "kn": 0.514444, "ft/s": 0.3048,
    },
    "time": {
        "ms": 0.001, "s": 1, "min": 60, "h": 3600, "d": 86400, "wk": 604800,
        "mo": 2629746, "yr": 31556952,
    },
    "data": {
        "b": 1, "kb": 1e3, "mb": 1e6, "gb": 1e9, "tb": 1e12,
        "kib": 1024, "mib": 1024 ** 2, "gib": 1024 ** 3, "tib": 1024 ** 4,
    },
    "temperature": {"c": None, "f": None, "k": None},
}

LABEL = {
    "m3": "m³", "mm2": "mm²", "cm2": "cm²", "m2": "m²", "km2": "km²", "in2": "in²",
    "ft2": "ft²", "mi2": "mi²", "floz": "fl oz", "l": "L", "ml": "mL",
    "c": "°C", "f": "°F", "k": "K", "b": "B", "kb": "KB", "mb": "MB", "gb": "GB",
    "tb": "TB", "kib": "KiB", "mib": "MiB", "gib": "GiB", "tib": "TiB",
}

ALIAS = {
    "мм": "mm", "см": "cm", "дм": "dm", "м": "m", "метр": "m", "метров": "m", "метра": "m",
    "км": "km", "километр": "km", "километров": "km", "inch": "in", "inches": "in",
    "дюйм": "in", "дюймов": "in", "дюйма": "in", '"': "in", "feet": "ft", "foot": "ft",
    "фут": "ft", "футов": "ft", "yard": "yd", "ярд": "yd", "mile": "mi", "miles": "mi",
    "миля": "mi", "миль": "mi", "мили": "mi", "мі": "mi",
    "мг": "mg", "г": "g", "гр": "g", "грамм": "g", "кг": "kg", "кило": "kg", "т": "t",
    "тонн": "t", "тонна": "t", "ounce": "oz", "унция": "oz", "унций": "oz", "lbs": "lb",
    "pound": "lb", "pounds": "lb", "фунт": "lb", "фунтов": "lb", "stone": "st",
    "мл": "ml", "л": "l", "литр": "l", "литров": "l", "литра": "l", "м3": "m3", "м³": "m3",
    "m³": "m3", "fl oz": "floz", "gallon": "gal", "gallons": "gal", "галлон": "gal",
    "pint": "pt", "quart": "qt", "cups": "cup",
    "м2": "m2", "м²": "m2", "m²": "m2", "км2": "km2", "km²": "km2", "см2": "cm2",
    "cm²": "cm2", "га": "ha", "гектар": "ha", "acre": "ac", "acres": "ac", "sqft": "ft2",
    "ft²": "ft2", "sqm": "m2",
    "kmh": "km/h", "kph": "km/h", "км/ч": "km/h", "км/год": "km/h", "м/с": "m/s",
    "mps": "m/s", "knot": "kn", "knots": "kn", "узлов": "kn", "узел": "kn",
    "мс": "ms", "с": "s", "сек": "s", "sec": "s", "мин": "min", "минут": "min",
    "ч": "h", "час": "h", "часов": "h", "hr": "h", "hrs": "h", "hour": "h", "hours": "h",
    "д": "d", "дн": "d", "дней": "d", "day": "d", "days": "d", "нед": "wk",
    "week": "wk", "weeks": "wk", "мес": "mo", "month": "mo", "months": "mo",
    "лет": "yr", "year": "yr", "years": "yr", "y": "yr",
    "байт": "b", "кб": "kb", "мб": "mb", "гб": "gb", "тб": "tb",
    "°c": "c", "°f": "f", "°": "c", "℃": "c", "℉": "f", "цельсия": "c",
    "фаренгейта": "f", "кельвин": "k", "kelvin": "k", "celsius": "c", "fahrenheit": "f",
}

CURRENCY_ALIAS = {
    "$": "USD", "доллар": "USD", "долларов": "USD", "доллара": "USD", "долл": "USD",
    "дол": "USD", "бакс": "USD", "баксов": "USD", "usd": "USD", "долар": "USD",
    "доларів": "USD", "€": "EUR", "евро": "EUR", "євро": "EUR", "eur": "EUR",
    "₴": "UAH", "грн": "UAH", "гривна": "UAH", "гривен": "UAH", "гривень": "UAH",
    "гривні": "UAH", "uah": "UAH", "£": "GBP", "фунтов стерлингов": "GBP",
    "zł": "PLN", "злотых": "PLN", "злотий": "PLN", "pln": "PLN", "¥": "JPY",
    "иен": "JPY", "юаней": "CNY", "юань": "CNY", "франков": "CHF", "лир": "TRY",
}

SYMBOL = {"USD": "$", "EUR": "€", "UAH": "₴", "GBP": "£", "PLN": "zł", "JPY": "¥",
          "CNY": "¥", "CHF": "₣", "TRY": "₺", "INR": "₹", "KRW": "₩", "ILS": "₪",
          "KZT": "₸", "GEL": "₾", "CZK": "Kč", "AZN": "₼"}

DEFAULT = {
    "km": "mi", "mi": "km", "m": "ft", "ft": "m", "cm": "in", "in": "cm", "mm": "in",
    "yd": "m", "nmi": "km", "dm": "cm",
    "kg": "lb", "lb": "kg", "g": "oz", "oz": "g", "t": "lb", "st": "kg", "mg": "g",
    "l": "gal", "gal": "l", "ml": "floz", "floz": "ml", "cup": "ml", "pt": "l", "qt": "l",
    "tsp": "ml", "tbsp": "ml", "m3": "l",
    "m2": "ft2", "ft2": "m2", "ha": "ac", "ac": "ha", "km2": "mi2", "mi2": "km2",
    "cm2": "in2", "in2": "cm2", "mm2": "cm2",
    "km/h": "mph", "mph": "km/h", "m/s": "km/h", "kn": "km/h", "ft/s": "m/s",
    "s": "min", "min": "h", "h": "min", "d": "h", "wk": "d", "mo": "d", "yr": "d", "ms": "s",
    "b": "kb", "kb": "mb", "mb": "gb", "gb": "mb", "tb": "gb",
    "kib": "kb", "mib": "mb", "gib": "gb", "tib": "tb",
    "c": "f", "f": "c", "k": "c",
}

GLYPH = {"length": "󰑭", "mass": "󰖡", "volume": "󰖌", "area": "󰹞", "speed": "󰓅",
         "time": "󰥔", "data": "󰋊", "temperature": "󰔏"}

SEP = re.compile(r"\s+(?:to|in|into|в|во|у|на)\s+|\s*(?:->|→|=>|=)\s*|\s+", re.I)
QUERY = re.compile(r"^\s*([-+]?\d[\d\s]*(?:[.,]\d+)?)\s*(.+?)\s*$")

def kind_of(unit):
    for k, table in UNITS.items():
        if unit in table:
            return k
    return None

def unit_of(word):
    w = word.strip().lower().rstrip(".")
    if w in UNITS["temperature"] or any(w in t for t in UNITS.values()):
        return w
    return ALIAS.get(w)

def load_rates():
    cached = None
    try:
        with open(CACHE) as f:
            cached = json.load(f)
        if time.time() - cached.get("at", 0) < FRESH:
            return cached
    except (OSError, ValueError):
        pass
    try:
        with urllib.request.urlopen(NBU, timeout=3) as r:
            rows = json.load(r)
        rates = {"UAH": 1.0}
        date = ""
        for row in rows:
            rates[row["cc"]] = float(row["rate"])
            date = row.get("exchangedate", date)
        fresh = {"at": time.time(), "date": date, "rates": rates}
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        tmp = CACHE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(fresh, f)
        os.replace(tmp, CACHE)
        return fresh
    except Exception:
        return cached

def currency_of(word, rates):
    w = word.strip().lower()
    if w in CURRENCY_ALIAS:
        return CURRENCY_ALIAS[w]
    up = w.upper()
    if len(up) == 3 and up.isalpha() and rates and up in rates["rates"]:
        return up
    return None

def looks_currency(word):
    w = word.strip().lower()
    return w in CURRENCY_ALIAS or (len(w) == 3 and w.isascii() and w.isalpha())

def pretty(v, digits):
    if v != 0 and abs(v) < 10 ** -digits:
        s = f"{v:.3g}"
    else:
        s = f"{v:,.{digits}f}"
        if "." in s:
            s = s.rstrip("0").rstrip(".")
    return s.replace(",", " ").replace(".", ",")

def to_kelvin(u, v):
    return v + 273.15 if u == "c" else (v - 32) * 5 / 9 + 273.15 if u == "f" else v

def from_kelvin(u, k):
    return k - 273.15 if u == "c" else (k - 273.15) * 9 / 5 + 32 if u == "f" else k

def split_units(rest):
    parts = [p for p in SEP.split(rest) if p]
    out, i = [], 0
    while i < len(parts):
        if i + 1 < len(parts) and (parts[i] + " " + parts[i + 1]).lower() in ALIAS:
            out.append(parts[i] + " " + parts[i + 1])
            i += 2
        else:
            out.append(parts[i])
            i += 1
    return out

def convert(query):
    m = QUERY.match(query)
    if not m:
        return None
    value = float(m.group(1).replace(" ", "").replace(",", "."))
    words = split_units(m.group(2))
    if not 1 <= len(words) <= 2:
        return None

    a = unit_of(words[0])
    b = unit_of(words[1]) if len(words) == 2 else None
    if a and (len(words) == 1 or b):
        b = b or DEFAULT.get(a)
        kind = kind_of(a)
        if not b or kind_of(b) != kind or a == b:
            return None
        if kind == "temperature":
            out = from_kelvin(b, to_kelvin(a, value))
            per = None
        else:
            out = value * UNITS[kind][a] / UNITS[kind][b]
            per = UNITS[kind][a] / UNITS[kind][b]
        fa, fb = LABEL.get(a, a), LABEL.get(b, b)
        return {
            "kind": kind, "glyph": GLYPH[kind],
            "value": pretty(value, 6), "from": fa, "to": fb,
            "result": pretty(out, 4 if abs(out) < 1000 else 2), "raw": f"{out:.10g}",
            "note": f"1 {fa} = {pretty(per, 6)} {fb}" if per else "",
        }

    if not all(looks_currency(w) for w in words):
        return None
    rates = load_rates()
    if not rates:
        return None
    a = currency_of(words[0], rates)
    b = currency_of(words[1], rates) if len(words) == 2 else ("USD" if a == "UAH" else "UAH")
    if not a or not b or a == b:
        return None
    r = rates["rates"]
    if a not in r or b not in r:
        return None
    per = r[a] / r[b]
    out = value * per
    return {
        "kind": "currency", "glyph": "",
        "value": pretty(value, 2), "from": a, "to": b,
        "fromSym": SYMBOL.get(a, a), "toSym": SYMBOL.get(b, b),
        "result": pretty(out, 2), "raw": f"{out:.2f}",
        "note": f"1 {a} = {pretty(per, 4)} {b} · НБУ {rates.get('date', '')}".strip(),
    }

def main():
    if len(sys.argv) < 2:
        return 1
    try:
        res = convert(sys.argv[1])
    except Exception:
        return 1
    if not res:
        return 1
    print(json.dumps(res, ensure_ascii=False))
    return 0

if __name__ == "__main__":
    sys.exit(main())
