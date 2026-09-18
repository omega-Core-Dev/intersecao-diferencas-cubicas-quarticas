#!/usr/bin/env sage
"""Certificado reprodutível para a interseção D_3(n) = D_4(m).

Executar com:

    sage scripts/verificar_d3_d4.sage

O script ativa o modo de prova do SageMath, verifica a redução algébrica,
certifica o grupo de Mordell--Weil, enumera todos os pontos inteiros da curva
elíptica e aplica o filtro congruencial que recupera (n, m).
"""

from sage.all import EllipticCurve, PolynomialRing, QQ, ZZ, proof, version


SCAN_BOUND = 10_000

EXPECTED_INTEGRAL_POINTS = {
    (ZZ(4), ZZ(-10)),
    (ZZ(4), ZZ(10)),
    (ZZ(6), ZZ(-18)),
    (ZZ(6), ZZ(18)),
    (ZZ(186), ZZ(-2538)),
    (ZZ(186), ZZ(2538)),
}

EXPECTED_ADMISSIBLE = [
    (ZZ(0), ZZ(0), ZZ(6), ZZ(18)),
    (ZZ(70), ZZ(15), ZZ(186), ZZ(2538)),
]


def progressive_difference(d, n):
    """Retorna D_d(n) = (n + 1)^d - n^d em ZZ."""
    n = ZZ(n)
    return (n + 1) ** d - n**d


def verify_polynomial_reduction():
    """Verifica simbolicamente a equivalência com a curva de Weierstrass."""
    ring = PolynomialRing(QQ, names=("n", "m"))
    n, m = ring.gens()

    d3 = (n + 1) ** 3 - n**3
    d4 = (m + 1) ** 4 - m**4
    X = 12 * m + 6
    Y = 36 * n + 18
    residual = Y**2 - (X**3 + 36 * X - 108)

    assert d3 == 3 * n**2 + 3 * n + 1
    assert d4 == 4 * m**3 + 6 * m**2 + 4 * m + 1
    assert residual == 432 * (d3 - d4)


def finite_monotone_scan(bound):
    """Busca de sanidade por intercalação; não substitui a prova global."""
    n = ZZ(0)
    m = ZZ(0)
    hits = []

    while n <= bound and m <= bound:
        d3 = progressive_difference(3, n)
        d4 = progressive_difference(4, m)

        if d3 == d4:
            hits.append((n, m, d3))
            n += 1
            m += 1
        elif d3 < d4:
            n += 1
        else:
            m += 1

    return hits


def certify_elliptic_curve():
    """Certifica invariantes, pontos inteiros e soluções admissíveis."""
    curve = EllipticCurve(QQ, [0, 0, 0, 36, -108])

    assert curve.discriminant() == -8024832
    assert curve.global_minimal_model() == curve
    assert curve.conductor() == 3096
    assert curve.rank(proof=True) == 1
    assert curve.torsion_subgroup().order() == 1

    generators = curve.gens(proof=True)
    assert len(generators) == 1
    assert ZZ(generators[0][0]) == 6
    assert abs(ZZ(generators[0][1])) == 18

    saturated_basis, saturation_index, saturation_regulator = curve.saturation(
        generators
    )
    assert saturation_index == 1

    points = curve.integral_points(
        mw_base=generators,
        both_signs=True,
        verbose=True,
    )
    point_coordinates = {(ZZ(point[0]), ZZ(point[1])) for point in points}
    assert point_coordinates == EXPECTED_INTEGRAL_POINTS

    admissible = []
    for X, Y in sorted(point_coordinates):
        if X > 0 and Y > 0 and X % 12 == 6 and Y % 36 == 18:
            m = (X - 6) // 12
            n = (Y - 18) // 36
            assert progressive_difference(3, n) == progressive_difference(4, m)
            admissible.append((n, m, X, Y))

    assert admissible == EXPECTED_ADMISSIBLE

    generator = curve(6, 18)
    assert 2 * generator == curve(4, -10)
    assert -3 * generator == curve(186, 2538)

    return {
        "curve": curve,
        "generators": generators,
        "saturated_basis": saturated_basis,
        "saturation_index": saturation_index,
        "saturation_regulator": saturation_regulator,
        "points": sorted(point_coordinates),
        "admissible": admissible,
    }


def main():
    proof.all(True)
    print("SAGE_VERSION", version())

    verify_polynomial_reduction()
    print("POLYNOMIAL_REDUCTION", "OK")

    scan_hits = finite_monotone_scan(SCAN_BOUND)
    expected_scan_hits = [
        (ZZ(0), ZZ(0), ZZ(1)),
        (ZZ(70), ZZ(15), ZZ(14911)),
    ]
    assert scan_hits == expected_scan_hits
    print("FINITE_SCAN_BOUND", SCAN_BOUND)
    print("FINITE_SCAN_HITS", scan_hits)

    certificate = certify_elliptic_curve()
    print("CURVE", certificate["curve"])
    print("GENERATORS", certificate["generators"])
    print("SATURATION_INDEX", certificate["saturation_index"])
    print("ALL_INTEGRAL_POINTS", certificate["points"])
    print("ADMISSIBLE", certificate["admissible"])
    print("THEOREM_CHECK", "OK")


if __name__ == "__main__":
    main()
