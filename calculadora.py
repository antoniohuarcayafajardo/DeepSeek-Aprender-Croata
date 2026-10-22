#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Calculadora de línea de comandos.

Modo interactivo:
    python calculadora.py

Una sola operación (sin entrar al bucle):
    python calculadora.py "2 + 3 * 4"

Operadores: + - * / // % ** y paréntesis.
Funciones: sqrt, abs, round. Constantes: pi, e. 'ans' = último resultado.
"""

import ast
import math
import operator
import sys

OPERADORES = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod,
    ast.Pow: operator.pow,
}

FUNCIONES = {"sqrt": math.sqrt, "abs": abs, "round": round}
CONSTANTES = {"pi": math.pi, "e": math.e}
MAX_EXPONENTE = 1000

AYUDA = """\
Operadores:  +   -   *   /   //   %   **   ( )
Funciones:   sqrt(x)   abs(x)   round(x[, decimales])
Constantes:  pi   e
'ans'        repite el resultado anterior
Comandos:    ayuda   historial   salir

Ejemplos:
    12 + 5 * 3          -> 27
    (12 + 5) * 3        -> 51
    sqrt(144) / 2       -> 6
    2 ** 10             -> 1024
    ans * 2             -> el doble del último resultado"""


class ErrorCalculo(ValueError):
    """Expresión no válida o cálculo imposible."""


def evaluar(expresion, anterior=None):
    """Evalúa una expresión aritmética sin usar eval()."""
    texto = expresion.strip()
    if not texto:
        raise ErrorCalculo("escribe una operación")
    try:
        arbol = ast.parse(texto, mode="eval")
    except SyntaxError:
        raise ErrorCalculo("la expresión está incompleta o mal escrita") from None
    try:
        return _evaluar_nodo(arbol.body, anterior)
    except ZeroDivisionError:
        raise ErrorCalculo("no se puede dividir por cero") from None
    except OverflowError:
        raise ErrorCalculo("el resultado es demasiado grande") from None


def _evaluar_nodo(nodo, anterior):
    if isinstance(nodo, ast.Constant):
        if isinstance(nodo.value, bool) or not isinstance(nodo.value, (int, float)):
            raise ErrorCalculo("solo se admiten números")
        return nodo.value

    if isinstance(nodo, ast.Name):
        if nodo.id in CONSTANTES:
            return CONSTANTES[nodo.id]
        if nodo.id == "ans":
            if anterior is None:
                raise ErrorCalculo("todavía no hay un resultado anterior")
            return anterior
        raise ErrorCalculo(f"nombre desconocido: {nodo.id}")

    if isinstance(nodo, ast.UnaryOp) and isinstance(nodo.op, (ast.UAdd, ast.USub)):
        valor = _evaluar_nodo(nodo.operand, anterior)
        return valor if isinstance(nodo.op, ast.UAdd) else -valor

    if isinstance(nodo, ast.BinOp) and type(nodo.op) in OPERADORES:
        izquierda = _evaluar_nodo(nodo.left, anterior)
        derecha = _evaluar_nodo(nodo.right, anterior)
        if isinstance(nodo.op, ast.Pow) and abs(derecha) > MAX_EXPONENTE and abs(izquierda) > 1:
            raise ErrorCalculo("exponente demasiado grande")
        return OPERADORES[type(nodo.op)](izquierda, derecha)

    if isinstance(nodo, ast.Call) and isinstance(nodo.func, ast.Name) and nodo.func.id in FUNCIONES:
        if nodo.keywords:
            raise ErrorCalculo("no se admiten argumentos con nombre")
        nombre = nodo.func.id
        argumentos = [_evaluar_nodo(arg, anterior) for arg in nodo.args]
        try:
            return FUNCIONES[nombre](*argumentos)
        except TypeError:
            raise ErrorCalculo(f"número de argumentos incorrecto para {nombre}()") from None
        except ValueError:
            raise ErrorCalculo(f"valor no válido para {nombre}()") from None

    raise ErrorCalculo("operación no permitida")


def formatear(valor):
    """Convierte el número a texto sin ceros ni decimales sobrantes."""
    if isinstance(valor, float):
        if math.isnan(valor):
            return "nan"
        if math.isinf(valor):
            return "infinito" if valor > 0 else "-infinito"
        if valor.is_integer() and abs(valor) < 1e16:
            return str(int(valor))
        return f"{valor:.12g}"
    return str(valor)


def mostrar_historial(historial):
    if not historial:
        print("Todavía no hay operaciones.")
        return
    print("Últimas operaciones:")
    for numero, (expresion, resultado) in enumerate(historial[-10:], 1):
        print(f"  {numero:>2}. {expresion} = {formatear(resultado)}")


def bucle_interactivo():
    print("Calculadora. Escribe 'ayuda' para ver las operaciones y 'salir' para terminar.")
    historial = []
    anterior = None

    while True:
        try:
            linea = input("calc> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nHasta luego.")
            return 0

        if not linea:
            continue

        comando = linea.lower()
        if comando in ("salir", "exit", "quit", "q"):
            print("Hasta luego.")
            return 0
        if comando in ("ayuda", "help", "?"):
            print(AYUDA)
            continue
        if comando in ("historial", "hist", "h"):
            mostrar_historial(historial)
            continue

        try:
            resultado = evaluar(linea, anterior)
        except ErrorCalculo as error:
            print(f"Error: {error}")
            continue

        anterior = resultado
        historial.append((linea, resultado))
        print(f"= {formatear(resultado)}")


def main(argv):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")

    if len(argv) > 1:
        try:
            print(formatear(evaluar(" ".join(argv[1:]))))
        except ErrorCalculo as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1
        return 0

    return bucle_interactivo()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
