# Amazon Product Performance & Customer Insights

**Tech Challenge — Fase 4 | Data Analytics | Pós Tech FIAP**

Dar mais desconto deixa o cliente mais satisfeito? Analisamos 1.351 produtos e 6.718 avaliações escritas por clientes da Amazon para entender a relação entre **Preço → Desconto → Engajamento → Satisfação** e apontar quais produtos, categorias e estratégias comerciais merecem atenção.

**Grupo**
- Emerson Henrique de Lima e Sousa — RM 373751
- Moacyr Souza Barros — RM 373412

**Vídeo executivo:** [https://youtu.be/qqOUBZu-Lg0]

---

## Principais resultados

| Indicador | Resultado |
|---|---|
| Produtos analisados | 1.351 (1.188 famílias de anúncio) |
| Nota média | 4,09, com 74,8% dos produtos com nota 4,0 ou mais |
| Desconto médio | 46,7% (27,9% dos produtos com mais de 60%) |
| Concentração do engajamento | 10% dos produtos reúnem 60% das avaliações |
| Avaliações escritas analisadas | 6.718: 84,1% positivas e 9,8% negativas |

**O que encontramos**

1. **Desconto alto vem com nota menor, sem ganho de engajamento.** Com mais de 80% de desconto, só 56,9% dos produtos têm nota 4,0 ou mais, contra 83,4% dos que descontam até 20%, e eles não recebem mais avaliações. Controlando preço e categoria numa regressão logística, cada 10 pontos a mais de desconto reduzem em cerca de 13% a chance de nota 4,0 ou mais. A diferença é maior nos itens de até ₹200.
2. **Os comentários explicam o motivo.** Quanto maior o desconto, mais os clientes falam de defeitos: a menção a durabilidade sobe de 5,9% para 10,1% das avaliações.
3. **O que mais gera reclamação é o produto parar de funcionar.** Quando o tema durabilidade aparece, 27,4% das avaliações são negativas, quase três vezes a média de 9,8%; em Casa e Cozinha, 35,1%. Entrega e embalagem aparecem em só 5% das avaliações.
4. **Poucos produtos concentram o risco.** 40 famílias de produtos entre os 25% mais avaliados têm nota abaixo de 4,0, principalmente fones de ouvido e eletroportáteis. Juntas, somam 1,93 milhão de avaliações (11,5% da base).
5. **Há oportunidades e alertas que a nota não mostra.** 58 produtos com nota 4,3 ou mais têm pouca visibilidade, e 14 produtos com nota 4,0 ou mais já acumulam 3 ou mais avaliações negativas.

## Estrutura do repositório

```
fiap_analytics_postech_challenge4/
├── README.md
├── requirements.txt
├── .gitignore
├── data/
│   ├── amazon.csv                      ← baixar do Kaggle (não versionado)
│   ├── validacao/
│   │   ├── amostra_sentimento_rotulada.csv  ← 100 avaliações rotuladas à mão (validação do sentimento)
│   │   └── amostra_temas_rotulada.csv       ← 80 avaliações conferidas por tema
│   └── processed/
│       ├── produtos_tratados.csv       ← base tratada (conferência com o Power BI)
│       ├── reviews_sentimento.csv      ← uma linha por avaliação, com sentimento e temas
│       └── reviews_temas.csv           ← uma linha por avaliação e tema (formato longo)
├── notebooks/
│   └── Amazon_Product_Insights_TechChallenge4.ipynb
├── results/                            ← 13 gráficos gerados pelo notebook (01_ a 13_)
├── dashboard/
│   ├── Amazon_Insights_TechChallenge4/ 
│       ├── Amazon_Insights_TechChallenge4.pbix
│       └── Amazon_Insights_TechChallenge4.pbip
│   ├── COMO_MONTAR.md                  ← passo a passo do modelo e das páginas
│   ├── medidas_dax.dax                 ← medidas DAX + consulta de conferência
│   ├── tema_amazon_insights.json       ← tema do Power BI (paleta do projeto)
│   └── power_query/
│       ├── 00_PastaDados.m
│       ├── 01_fReviews.m
│       ├── 02_fTemas.m
│       └── 03_fProdutos.m              ← tratamento completo a partir do CSV bruto
└── docs/
    └── Relatorio_Executivo_TechChallenge4.pdf
```

## Dataset

[Amazon Sales Dataset](https://www.kaggle.com/datasets/karkavelrajaj/amazon-sales-dataset) (Kaggle), com 1.465 linhas e 16 colunas de produtos da Amazon Índia: categoria, preços, desconto, nota, número de avaliações, descrição e até 8 avaliações por produto.

O arquivo não é versionado. Baixe-o do Kaggle e salve como `data/amazon.csv`.

## Como reproduzir

```bash
git clone https://github.com/Moacyrsouzab/fiap_analytics_postech_challenge4.git
cd fiap_analytics_postech_challenge4
pip install -r requirements.txt
# salve o amazon.csv do Kaggle em data/amazon.csv
cd notebooks
jupyter nbconvert --to notebook --execute --inplace Amazon_Product_Insights_TechChallenge4.ipynb
```

O notebook gera os gráficos em `results/` e as bases em `data/processed/`. Para o dashboard, abra o `.pbix` no Power BI Desktop e ajuste o parâmetro `PastaDados` para o caminho da pasta `data/` no seu computador. Para montar do zero, siga `dashboard/COMO_MONTAR.md`.

## Metodologia

- **Tratamento:** conversão de preços em rúpias (₹) e do formato indiano de milhar, tratamento de 1 nota inválida e 2 contagens ausentes, remoção de 114 linhas duplicadas e separação da categoria em níveis traduzidos.
- **Famílias de anúncio:** 255 produtos (19%) são variantes que dividem as mesmas avaliações. Os totais de avaliações contam cada família uma vez, para não inflar o engajamento.
- **Análise:** faixas de desconto, preço e nota; correlação de Spearman; regressão logística para separar o efeito do desconto do efeito do preço e da categoria; grupos de engajamento × satisfação (mediana de avaliações e nota 4,0); alcance de cada recomendação medido em avaliações.
- **Customer Insights:** separação das avaliações (só as famílias com texto perfeitamente alinhado), sentimento com VADER, dicionário de 15 temas e comparação entre o que as descrições prometem e o que os clientes dizem. O método foi validado lendo amostras à mão: o sentimento acerta cerca de 83% e os temas principais, de 75% a 78%.
- **Dashboard:** Power Query refaz todo o tratamento a partir do arquivo bruto; as medidas DAX trazem uma consulta de conferência com os valores esperados do notebook.

## Limitações

- A base não tem vendas nem receita. O número de avaliações é usado como indicador de popularidade.
- Os preços estão em rúpias e refletem a Amazon Índia.
- Há até 8 avaliações por produto (as exibidas na página), e o sentimento é calculado sobre o texto, sem nota individual. Pela validação manual, o método tende a subestimar as avaliações negativas (cerca de 11% reais, contra 9,8% medidos).
- As relações encontradas são associações, não causa e efeito.

## Ferramentas

Python (pandas, NumPy, SciPy, statsmodels, Matplotlib, vaderSentiment) · Jupyter · Power BI Desktop (Power Query e DAX)
