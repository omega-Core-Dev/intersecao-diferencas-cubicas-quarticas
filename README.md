# Interseção entre diferenças progressivas cúbicas e quárticas

*Classificação completa por meio de uma curva elíptica*

**Autor:** Zaqueu Ribeiro

**Identificação complementar:** SINGULAR

**Data da versão:** 17 de setembro de 2026

**Status:** pré-publicação independente

O artigo estuda as diferenças progressivas

$$D_d(n)=(n+1)^d-n^d$$

e a igualdade entre as camadas cúbica e quártica. O resultado principal apresentado no artigo é, para inteiros não negativos $n,m$,

$$D_3(n)=D_4(m) \iff (n,m)=(0,0)\ \text{ou}\ (70,15).$$

Para as camadas positivas $\mathcal{L}_d=\{D_d(n):n\in\mathbb{Z}_{\geq1}\}$, a consequência é

$$\mathcal{L}_3\cap\mathcal{L}_4=\{14911\}.$$

A completude é obtida no artigo por redução à curva elíptica

$$Y^2=X^3+36X-108,$$

com determinação dos pontos inteiros e aplicação de condições de congruência. O artigo contém um certificado computacional reproduzível em SageMath. Os problemas abertos discutidos no texto permanecem distintos do resultado principal.

O [artigo em PDF](paper/Intersecao_Diferencas_Cubicas_Quarticas_Zaqueu_Ribeiro.pdf) e o [fonte LaTeX](paper/Intersecao_Diferencas_Cubicas_Quarticas_Zaqueu_Ribeiro.tex) estão disponíveis em `paper/`.

## Compilação

Com `pdflatex` e os pacotes LaTeX utilizados pelo artigo instalados:

```bash
cd paper
pdflatex Intersecao_Diferencas_Cubicas_Quarticas_Zaqueu_Ribeiro.tex
pdflatex Intersecao_Diferencas_Cubicas_Quarticas_Zaqueu_Ribeiro.tex
```

## Integridade e citação

O arquivo `CHECKSUMS.sha256` registra os hashes SHA-256 do fonte e do PDF fornecidos pelo autor. O conteúdo desses arquivos foi preservado integralmente; apenas seus nomes foram padronizados. Os dados para citação estão em `CITATION.cff`.

Na preparação deste repositório, o PDF fornecido foi aberto e suas nove páginas foram renderizadas. Não foi realizada recompilação local, pois `pdflatex` não estava instalado no ambiente de preparação; portanto, não foi possível comparar o PDF fornecido com uma nova compilação.

Todos os direitos reservados ao autor.
