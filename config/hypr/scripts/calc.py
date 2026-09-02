#!/usr/bin/env python3
"""Считает одно арифметическое выражение и печатает результат.

Имена ограничены белым списком из math: eval получает пустые builtins, а
всякий идентификатор вне списка обрывает разбор до вычисления. Выход 1 —
выражение неполное или неверное; вызывающая сторона просто ничего не
показывает.
"""
import math
import re
import sys

ALLOWED = {k: v for k, v in vars(math).items() if not k.startswith("_")}
ALLOWED.update({
    "abs": abs, "round": round, "min": min, "max": max,
    "sum": sum, "pow": pow, "int": int, "float": float,
})

NAME = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")

def calc(expr: str) -> str:
    expr = expr.strip()
    if not expr:
        raise ValueError("empty")

    expr = (expr.replace("^", "**")
                .replace("×", "*")
                .replace("÷", "/")
                .replace("−", "-"))

    if not NAME.search(expr):
        expr = expr.replace(",", ".")

    for name in set(NAME.findall(expr)):
        if name not in ALLOWED:
            raise ValueError(f"unknown name: {name}")

    val = eval(expr, {"__builtins__": {}}, ALLOWED)

    if isinstance(val, float):
        if val == int(val) and abs(val) < 1e15:
            return str(int(val))
        return repr(round(val, 10))
    return str(val)

def main() -> int:
    if len(sys.argv) < 2:
        return 1
    try:
        print(calc(sys.argv[1]))
    except Exception:
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
