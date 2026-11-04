#!/usr/bin/env python3
"""Confere o CSV de referência do workshop sem acessar a OCI ou o AIDP."""

import argparse
import csv
import sys
from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from pathlib import Path


COLUNAS = [
    "Código",
    "Nome do cliente",
    "Empresa",
    "E-mail",
    "Telefone",
    "Status",
    "Tempo em negociação (dias, fictício)",
    "Quantidade de contatos realizados (fictício)",
    "Dias desde o último contato (fictício)",
    "Valor da proposta (BRL, fictício)",
    "Tornou-se ativo em 30 dias (fictício)",
]

STATUS = {
    "ativo": "Ativo",
    "inativo": "Inativo",
    "inatvo": "Inativo",
    "em negociação": "Em negociação",
    "em negociacao": "Em negociação",
    "": "Não informado",
    "n/a": "Não informado",
}


def conferir(descricao, obtido, esperado):
    """Falha também quando Python roda com -O, que desabilita assert."""
    if obtido != esperado:
        raise ValueError(
            f"{descricao}: esperado {esperado!r}, encontrado {obtido!r}."
        )


def moeda(valor):
    partes = f"{valor:,.2f}".split(".")
    return "R$ " + partes[0].replace(",", ".") + "," + partes[1]


def verificar(caminho):
    with caminho.open(encoding="utf-8-sig", newline="") as arquivo:
        leitor = csv.reader(arquivo, delimiter=",")
        cabecalho = next(leitor, None)
        conferir("Nomes e ordem das 11 colunas", cabecalho, COLUNAS)
        linhas = []
        for numero, valores in enumerate(leitor, start=2):
            conferir(f"Número de campos no registro {numero}", len(valores), 11)
            # csv.reader mantém todos os campos como texto, inclusive "001" e "".
            linhas.append(tuple(valores))

    conferir("Registros de origem", len(linhas), 100)
    frequencias = Counter(linhas)
    distintos = list(frequencias)
    conferir("Conteúdos distintos nos 11 campos originais", len(distintos), 95)
    excedentes = sum(quantidade - 1 for quantidade in frequencias.values())
    conferir("Cópias idênticas excedentes", excedentes, 5)
    registros = [dict(zip(COLUNAS, valores)) for valores in distintos]

    por_codigo = defaultdict(list)
    for registro in registros:
        codigo = registro["Código"]
        if codigo.strip():
            por_codigo[codigo].append(registro)
    colisoes = {codigo: grupo for codigo, grupo in por_codigo.items() if len(grupo) > 1}
    conferir("Códigos em colisão", sorted(colisoes), ["018", "037", "094"])
    conferir("Registros distintos nas colisões", sum(map(len, colisoes.values())), 6)

    por_status = Counter()
    por_desfecho = Counter()
    por_empresa = defaultdict(Decimal)
    for registro in registros:
        status_original = registro["Status"].strip().lower()
        if status_original not in STATUS:
            raise ValueError(f"Status sem regra de normalização: {registro['Status']!r}.")
        por_status[STATUS[status_original]] += 1
        por_desfecho[registro[COLUNAS[-1]].strip()] += 1
        empresa = registro["Empresa"].strip() or "Não informado"
        valor = Decimal(registro[COLUNAS[-2]].strip())
        if not valor.is_finite():
            raise ValueError("Valor de proposta precisa ser um número finito.")
        por_empresa[empresa] += valor

    conferir(
        "Status após normalização",
        dict(por_status),
        {"Ativo": 38, "Inativo": 24, "Em negociação": 20, "Não informado": 13},
    )
    conferir(
        "Desfechos em 30 dias",
        dict(por_desfecho),
        {"Sim": 27, "Não": 30, "Não se aplica": 38},
    )
    numerador = por_desfecho["Sim"]
    denominador = numerador + por_desfecho["Não"]
    conferir("Numerador da conversão", numerador, 27)
    conferir("Denominador da conversão", denominador, 57)
    percentual = (Decimal(numerador) / Decimal(denominador) * 100).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    conferir("Conversão arredondada (%)", percentual, Decimal("47.37"))
    total = sum(por_empresa.values(), Decimal(0))
    conferir("Valor total fictício das propostas", total, Decimal("3132500"))
    maior_valor = max(por_empresa.values())
    lideres = sorted(empresa for empresa, valor in por_empresa.items() if valor == maior_valor)
    conferir("Empresa com maior valor fictício de propostas", lideres, ["Sol Nascente"])
    conferir("Valor fictício de propostas da líder", maior_valor, Decimal("362000"))

    print(f"Arquivo: {caminho.resolve()}")
    print("VALIDAÇÃO LOCAL CONCLUÍDA")
    print("Origem: 100 registros, 11 colunas e 95 conteúdos distintos.")
    print("Deduplicação: 5 cópias idênticas excedentes; referência da prata: 95 registros.")
    print("Colisões: 018, 037 e 094; 6 registros distintos preservados.")
    print("Status: Ativo 38; Inativo 24; Em negociação 20; Não informado 13.")
    print("Desfecho: Sim 27; Não 30; Não se aplica 38.")
    print("Conversão: 27 / 57 = 47,37%.")
    print(f"Propostas fictícias: total {moeda(total)}.")
    print(f"Maior valor fictício por empresa: Sol Nascente, {moeda(maior_valor)}.")
    print("Esta conferência lê somente o CSV local. Não comprova execução no AIDP.")


def main():
    raiz = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(
        description="Valida os resultados de referência do CSV do workshop, sem dependências externas."
    )
    parser.add_argument(
        "csv", nargs="?", type=Path, default=raiz / "clientes.csv",
        help="CSV opcional. O padrão é clientes.csv na raiz do repositório.",
    )
    argumentos = parser.parse_args()
    try:
        verificar(argumentos.csv)
    except (OSError, UnicodeError, csv.Error, ValueError, InvalidOperation) as erro:
        print(f"FALHA NA VALIDAÇÃO: {erro}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
