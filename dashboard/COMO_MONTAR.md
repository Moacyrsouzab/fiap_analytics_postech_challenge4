# Como montar o dashboard no Power BI

## Caminho rápido: abrir o dashboard pronto

O dashboard está pronto em dois formatos, na pasta `dashboard/Amazon_Insights_TechChallenge4/`:

- `Amazon_Insights_TechChallenge4.pbix`: o arquivo de entrega, com os dados já carregados.
- `Amazon_Insights_TechChallenge4.pbip`: o mesmo dashboard em formato de projeto (texto, versionável no Git).

Os dois têm as 5 consultas do Power Query, os relacionamentos, a ordenação das faixas, os formatos, as 47 medidas, o tema e as 8 páginas (6 visíveis, mais o detalhe do produto e a dica de ferramenta).

1. Abra o `.pbix` (ou o `.pbip`) no Power BI Desktop. Para o `.pbip`, se a versão for antiga e reclamar do formato, atualize o Power BI Desktop ou ative em Arquivo > Opções > Recursos de visualização: "Projeto do Power BI (.pbip)" e "Formato de metadados de relatório avançado (PBIR)".
2. Para atualizar os dados: Página Inicial > Transformar dados > **Editar parâmetros** > `PastaDados` e coloque o caminho da pasta `data\` do repositório no seu computador, com a barra no final.
3. **Atualizar**. Os CSVs de `data/processed/` já estão no repositório; só é preciso rodar o notebook de novo se quiser regerá-los.
4. Confira os números com a consulta de conferência do `medidas_dax.dax` (seção 3 abaixo).

Se algo não abrir, o roteiro manual abaixo monta o mesmo dashboard do zero.

---

## Roteiro manual

Passo a passo para montar o `.pbix` com os arquivos desta pasta. A ordem importa: dados → modelo → medidas → tema → páginas.

## 1. Dados (Power Query)

Abra o Power BI Desktop > **Transformar dados** e crie as consultas nesta ordem (Nova fonte > Consulta nula > Editor Avançado > colar o conteúdo do arquivo > renomear a consulta com o nome do arquivo, sem o número):

| Ordem | Arquivo | Nome da consulta | O que faz |
|---|---|---|---|
| 1 | `power_query/00_PastaDados.m` | `PastaDados` | Parâmetro com o caminho da pasta `data/` do repositório. **Ajuste o caminho** e mantenha a barra `\` no final |
| 2 | `power_query/01_fReviews.m` | `fReviews` | Avaliações com sentimento (vem do notebook) |
| 3 | `power_query/02_fTemas.m` | `fTemas` | Temas de cada avaliação (vem do notebook) |
| 4 | `power_query/03_fProdutos.m` | `fProdutos` | Tratamento completo a partir do `amazon.csv` bruto |
| 5 | `power_query/04_dPercentil.m` | `dPercentil` | Percentis de 1% a 100%: eixo da curva de concentração (Pareto) da página 1 |

Antes de carregar, confira no painel **Etapas aplicadas** da `fProdutos` que todas as etapas aparecem com nome em português. É isso que o avaliador vai olhar no critério "Preparação dos dados".

Os CSVs usados por `fReviews` e `fTemas` ficam em `data/processed/` e já estão no repositório (são gerados pelo notebook).

## 2. Modelo

Na **Exibição de modelo**:

- Relacionamentos (ambos de um para muitos, direção única):
  - `fProdutos[product_id]` → `fReviews[product_id]`
  - `fReviews[review_id]` → `fTemas[review_id]`
- `dPercentil` fica **sem relacionamento** (tabela desconectada, usada só como eixo).
- **Ordenar por coluna** (selecionar a coluna > Ferramentas de coluna > Classificar por coluna):

| Coluna | Ordenar por |
|---|---|
| `fProdutos[faixa_desconto]` | `ordem_faixa_desconto` |
| `fProdutos[faixa_preco]` | `ordem_faixa_preco` |
| `fProdutos[faixa_nota]` | `ordem_faixa_nota` |
| `fProdutos[quadrante]` | `ordem_quadrante` |
| `fReviews[sentimento]` | `ordem_sentimento` |

- Ocultar da exibição de relatório: as colunas `ordem_*`, `familia`, `categoria_original`, `subcategoria_original` e `product_name` (usar `nome_curto` nos visuais).
- Formatar `discounted_price`, `actual_price` e `economia` com o formato personalizado `"₹"#,0`.
- Formatar `dPercentil[Percentil]` como porcentagem sem casas (`0%`).

## 3. Medidas

Siga as instruções do cabeçalho de `medidas_dax.dax`: o arquivo cria as 47 medidas de uma vez pela Exibição de consulta DAX. O resultado da consulta de conferência precisa bater com a tabela "Valores esperados" do fim do arquivo. **Se algum número não bater, pare e investigue antes de montar as páginas.**

O fim do arquivo também traz o formato de cada medida e as pastas de exibição: `1. Visão Executiva`, `2. Produtos e Categorias`, `3. Preços`, `4. Customer Insights`, `5. Títulos`.

## 4. Tema e tela

- Exibição > Temas > **Procurar temas** > `tema_amazon_insights.json`.
- Tela: Formatar página > Configurações da tela > 16:9 (1280 x 720).
- Fundo de cada página (opcional): Formatar página > Plano de fundo da tela > Imagem, com transparência 0% e ajuste "Ajustar". As imagens `fundo_*.png` estão em `Amazon_Insights_TechChallenge4/Amazon_Insights_TC4.Report/StaticResources/RegisteredResources/`.

## 5. Páginas

Estrutura comum às páginas 1 a 6:
- **Navegação lateral:** 6 botões, um para cada página visível (Inserir > Botões > Em branco > Ação: Navegação de página).
- **Título da página:** caixa de texto com a conclusão da página, não o tema.
- **Filtros à esquerda** (páginas 1 a 4): Categoria, Subcategoria e Faixa de preço, sincronizados (Exibição > Sincronizar segmentações).
- Todo visual com título que diga a conclusão. Os títulos que mudam com o filtro usam as medidas da pasta `5. Títulos` (Título > fx > Valor do campo).

### Página 1 — Visão Executiva
Título: *Portfólio bem avaliado, mas o risco está concentrado em poucos produtos*

| Visual | Campos |
|---|---|
| 6 cartões | Produtos · Nota média · % nota ≥ 4,0 · Avaliações · Desconto médio · % avaliações negativas |
| Barras agrupadas horizontais | Eixo: `categoria` · Valores: % do portfólio e % das avaliações |
| Colunas | Eixo: `faixa_nota` · Valor: Produtos |
| Linhas (curva de concentração) | Eixo: `dPercentil[Percentil]` · Valores: Concentração acumulada e Linha de igualdade · Linha de referência Y = 60% ("60% das avaliações") · Título dinâmico: `Título Pareto` |
| Barras agrupadas horizontais | Eixo: `quadrante` · Valores: % dos produtos no grupo e % das avaliações no grupo · Título dinâmico: `Título Quadrantes` |
| 3 cartões de alerta | Famílias em risco de reputação (40) · Famílias com oportunidade de visibilidade (58) · Produtos com alerta nos comentários (14) |
| Caixa de texto | Onde encontrar as listas: páginas 2 e 4 |

### Página 2 — Produtos e Categorias
Título: *40 famílias muito avaliadas com nota abaixo de 4,0 concentram o risco de reputação*

| Visual | Campos |
|---|---|
| Dispersão | X: `rating_count` (escala logarítmica) · Y: `rating` · Legenda: `quadrante` · Detalhes: `product_id` · Linhas de referência: X = 4.740 ("Mediana") e Y = 4,0 · Dica de ferramenta: página "Dica do produto" |
| Barras horizontais (ranking de subcategorias) | Eixo: `subcategoria` · Valor: % nota ≥ 4,0 (subcategorias com 15+ produtos) · Dicas: Produtos com nota, Nota média, Desconto médio · Linha de referência = 74,8% ("Média") · Ordenar do menor para o maior |
| Tabela "Risco de reputação" | Filtro: `risco_reputacao` = Verdadeiro · `nome_curto`, `subcategoria`, `rating`, `rating_count`, `desconto` · Ordenar por `rating_count` |
| Tabela "Oportunidade de visibilidade" | Filtro: `oportunidade_visibilidade` = Verdadeiro · `nome_curto`, `subcategoria`, `rating`, `rating_count`, `desconto`, `nota_ponderada` · Ordenar por `nota_ponderada` |

### Página 3 — Preços
Título: *Desconto alto vem com nota menor e não traz mais engajamento*

| Visual | Campos |
|---|---|
| 3 cartões | Desconto médio · % com desconto acima de 60% · Economia média |
| Colunas (destaque) | Eixo: `faixa_desconto` · Valor: % nota ≥ 4,0 · Título dinâmico: `Título Desconto` |
| Colunas | Eixo: `faixa_desconto` · Valor: Avaliações por produto (mediana) |
| Colunas | Eixo: `faixa_preco` · Valor: Desconto médio |
| Linhas | Eixo: `faixa_desconto` · Valor: % nota ≥ 4,0 · Legenda: `categoria` (filtrar as 3 principais) |
| Matriz (mapa de calor) | Linhas: `faixa_preco` · Colunas: `faixa_desconto` · Valor: % nota ≥ 4,0 (células com 8+ produtos) · Formatação condicional: cor de fundo em escala de 3 cores |

### Página 4 — Customer Insights
Título: *O cliente reclama quando o produto para de funcionar, não da entrega*

| Visual | Campos |
|---|---|
| Segmentações extras | `fTemas[tema]` e `fReviews[sentimento]` |
| 3 cartões | Avaliações de texto · % avaliações positivas · % avaliações negativas |
| Barras horizontais | Eixo: `fTemas[tema]` · Valor: % das avaliações que citam o tema |
| Barras horizontais | Eixo: `fTemas[tema]` · Valor: % negativas quando cita o tema · Linha de referência = 9,8% ("Média") · Título dinâmico: `Título Temas` |
| Colunas | Eixo: `categoria` · Valor: % negativas sobre durabilidade |
| Linhas | Eixo: `faixa_desconto` · Valor: % cita durabilidade |
| Tabela | `fProdutos[nome_curto]`, `fReviews[sentimento]`, `fReviews[titulo]`, `fReviews[texto]` · Filtro do visual: `Filtro tema da avaliação` = 1 (faz a tabela responder à segmentação de tema) |

### Página 5 — Recomendações
Título: *Seis ações, do maior para o menor alcance*

Seis caixas de texto no formato **Achado → Ação → Onde → Como acompanhar** (Seção 8 do notebook), cada uma com o número que sustenta a recomendação:
1. Revisar a política de descontos
2. Plano de qualidade para os itens em risco
3. Cobrar durabilidade dos fornecedores
4. Monitorar os comentários
5. Dar visibilidade a quem já é bem avaliado
6. Descrever o que o cliente valoriza

No fim, o bloco **Para a liderança**, com as 3 mensagens principais, e uma nota de limitações.

### Página 6 — Metodologia e dados
Título: *Como chegamos aos números: tratamento, validação e definições*

Caixas de texto com:
- **Da base bruta ao dashboard:** linhas do arquivo, duplicadas removidas, produtos únicos e famílias de anúncio.
- **Texto das avaliações:** quantas avaliações e de quantos produtos.
- **Validação manual:** acerto do sentimento e dos temas.
- **Regressão logística:** efeito de +10 p.p. de desconto na chance de nota ≥ 4,0, controlando preço e categoria.
- **Definições usadas no dashboard:** engajamento alto (avaliações acima da mediana de 4.740), satisfação alta (nota ≥ 4,0), quadrantes, risco e oportunidade.
- **Limitações e próximos passos.**

### Páginas ocultas (interatividade)
- **Detalhe do produto (drill-through):** campo de drill-through `fProdutos[nome_curto]`. Cartão de várias linhas com nome, categoria, subcategoria e quadrante; cartões de Nota média, Avaliações e Desconto médio; tabela com as avaliações do produto (sentimento, título e texto). Incluir um cartão com a medida `Aviso sem avaliações de texto`: 493 produtos não têm avaliações de texto ligadas, e sem o aviso a página parece quebrada. O drill-through fica disponível em qualquer visual que use `nome_curto` (tabelas das páginas 2 e 4).
- **Dica do produto (tooltip):** página com tamanho "Dica de ferramenta" (Informações da página > Permitir uso como dica de ferramenta), com nome, categoria, Nota média, Avaliações, Desconto médio e quadrante. Usar na dispersão da página 2.

## 6. Conferência antes de entregar

- [ ] Os valores da consulta DAX de conferência batem com o notebook
- [ ] Os filtros funcionam em todas as páginas e nenhum visual fica vazio ao filtrar uma categoria
- [ ] Os rótulos de dados estão com o formato certo (%, ₹, separador de milhar), sem nenhum "0" ou "1" arredondado
- [ ] Os botões de navegação funcionam (Ctrl + clique no Desktop)
- [ ] O drill-through abre a partir das tabelas
- [ ] A curva de concentração da página 1 chega a 100% e cruza a linha de referência de 60% perto de 10% dos produtos
- [ ] O arquivo foi salvo, fechado, reaberto e atualizado sem erro
