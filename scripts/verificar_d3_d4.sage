#!/usr/bin/env sage
"""Certificado reprodutível para a interseção D_3(n) = D_4(m).

Executar com:

    sage scripts/verificar_d3_d4.sage

O script ativa o modo de prova do SageMath, verifica a redução algébrica,
certifica o grupo de Mordell--Weil, enumera todos os pontos inteiros da curva
elíptica, aplica o filtro congruencial que recupera (n, m) e gera uma
visualização vetorial em ``figures/curva_eliptica_d3_d4.svg``.
"""

from pathlib import Path

from sage.all import EllipticCurve, PolynomialRing, QQ, ZZ, proof, version


SCAN_BOUND = 10_000
REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SVG_OUTPUT = REPOSITORY_ROOT / "figures" / "curva_eliptica_d3_d4.svg"

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


def generate_curve_svg(certificate, output_path=SVG_OUTPUT):
    """Gera uma figura vetorial; ela ilustra, mas não substitui, a prova."""
    import matplotlib as mpl

    mpl.use("Agg")
    mpl.rcParams["svg.hashsalt"] = "d3-d4-zaqueu-ribeiro"

    import matplotlib.pyplot as plt
    import numpy as np

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    points = [(int(X), int(Y)) for X, Y in certificate["points"]]
    admissible_points = {
        (int(X), int(Y)) for _, _, X, Y in certificate["admissible"]
    }

    # A cúbica X^3 + 36X - 108 é estritamente crescente e tem uma só
    # raiz real. A bisseção evita depender de uma escolha numérica externa.
    left, right = 0.0, 6.0
    for _ in range(100):
        midpoint = (left + right) / 2.0
        if midpoint**3 + 36.0 * midpoint - 108.0 < 0.0:
            left = midpoint
        else:
            right = midpoint
    real_root = (left + right) / 2.0

    def curve_coordinates(x_max):
        X_values = np.linspace(real_root, x_max, 4000)
        radicand = X_values**3 + 36.0 * X_values - 108.0
        Y_values = np.sqrt(np.maximum(radicand, 0.0))
        return X_values, Y_values

    def draw_panel(axis, x_limits, y_limits, title, annotate_all=False):
        X_values, Y_values = curve_coordinates(x_limits[1])
        visible = X_values >= x_limits[0]
        axis.plot(
            X_values[visible],
            Y_values[visible],
            color="#173B57",
            linewidth=2.0,
            label=r"$E: Y^2=X^3+36X-108$",
        )
        axis.plot(
            X_values[visible],
            -Y_values[visible],
            color="#173B57",
            linewidth=2.0,
        )

        visible_points = [
            point
            for point in points
            if x_limits[0] <= point[0] <= x_limits[1]
            and y_limits[0] <= point[1] <= y_limits[1]
        ]
        ordinary_points = [
            point for point in visible_points if point not in admissible_points
        ]
        highlighted_points = [
            point for point in visible_points if point in admissible_points
        ]

        if ordinary_points:
            axis.scatter(
                *zip(*ordinary_points),
                s=42,
                color="#607D8B",
                edgecolor="white",
                linewidth=0.8,
                zorder=3,
                label="pontos integrais",
            )
        if highlighted_points:
            axis.scatter(
                *zip(*highlighted_points),
                s=78,
                color="#F59E0B",
                edgecolor="#7C2D12",
                linewidth=1.0,
                zorder=4,
                label="pontos admissíveis",
            )

        if annotate_all:
            label_offsets = {
                (4, 10): (8, 7),
                (4, -10): (8, -15),
                (6, 18): (8, 7),
                (6, -18): (8, -15),
            }
            for point in visible_points:
                offset = label_offsets.get(point, (7, 7))
                suffix = "  →  (n,m)=(0,0)" if point == (6, 18) else ""
                axis.annotate(
                    f"({point[0]},{point[1]}){suffix}",
                    xy=point,
                    xytext=offset,
                    textcoords="offset points",
                    fontsize=8.5,
                    color="#263238",
                )
        else:
            axis.annotate(
                r"$(186,2538)\ \rightarrow\ (n,m)=(70,15)$",
                xy=(186, 2538),
                xytext=(112, 2150),
                arrowprops={"arrowstyle": "->", "color": "#7C2D12"},
                fontsize=9,
                color="#7C2D12",
            )

        axis.set_xlim(*x_limits)
        axis.set_ylim(*y_limits)
        axis.set_title(title, fontsize=11, fontweight="bold")
        axis.set_xlabel("X")
        axis.set_ylabel("Y")
        axis.grid(True, color="#CFD8DC", linewidth=0.6, alpha=0.75)
        axis.axhline(0, color="#90A4AE", linewidth=0.7)
        axis.axvline(0, color="#90A4AE", linewidth=0.7)
        axis.legend(loc="best", fontsize=8, frameon=True)

    figure, axes = plt.subplots(1, 2, figsize=(13.2, 5.4))
    draw_panel(
        axes[0],
        (-8, 202),
        (-2850, 2850),
        "Visão global dos pontos integrais",
    )
    draw_panel(
        axes[1],
        (2, 11),
        (-28, 28),
        "Ampliação próxima da origem",
        annotate_all=True,
    )

    figure.suptitle(
        "Interseção entre diferenças cúbicas e quárticas",
        fontsize=15,
        fontweight="bold",
    )
    figure.text(
        0.5,
        0.015,
        "O destaque dourado indica os pontos que satisfazem "
        "X ≡ 6 (mod 12), Y ≡ 18 (mod 36), X>0 e Y>0.",
        ha="center",
        fontsize=9,
        color="#37474F",
    )
    figure.tight_layout(rect=(0, 0.045, 1, 0.93))
    figure.savefig(
        output_path,
        format="svg",
        metadata={
            "Title": "Curva elíptica da interseção D3-D4",
            "Creator": "Zaqueu Ribeiro (SINGULAR) — script SageMath",
            "Date": None,
        },
    )
    plt.close(figure)

    svg_text = output_path.read_text(encoding="utf-8")
    assert "<svg" in svg_text
    return output_path


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

    svg_path = generate_curve_svg(certificate)
    print("SVG_OUTPUT", svg_path)
    print("THEOREM_CHECK", "OK")


if __name__ == "__main__":
    main()
