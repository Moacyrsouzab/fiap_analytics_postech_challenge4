# Como montar o dashboard no Power BI

## Caminho rápido: abrir o projeto pronto

A pasta `Amazon_Insights_TechChallenge4/` é um projeto do Power BI (`.pbip`) com tudo o que está descrito abaixo já montado: as 5 consultas do Power Query, os relacionamentos, a ordenação das faixas, os formatos, as 39 medidas, o tema e as 8 páginas (6 visíveis, o detalhe do produto e a dica de ferramenta).

1. Rode o notebook uma vez, para gerar os CSVs em `data/processed/`.
2. Abra `Amazon_Insights_TechChallenge4/Amazon_Insights_TechChallenge4.pbip` no Power BI Desktop. Se a versão for antiga e reclamar do formato, atualize o Power BI Desktop ou ative em Arquivo > Opções > Recursos de visualização: "Projeto do Power BI (.pbip)" e "Formato de metadados de relatório avançado (PBIR)".
3. Página Inicial > Transformar dados > **Editar parâmetros** > `PastaDados`: coloque o caminho da pasta `data\` do repositório, com a barra no final.
4. **Atualizar**. Depois, confira os números com a consulta de conferência do `medidas_dax.dax` (passo 3 abaixo).
5. Passe página por página e ajuste o que ficar desalinhado. As linhas de referência da dispersão (X = 4.740 e Y = 4,0) e a escala logarítmica estão configuradas, mas vale conferir no painel de formatação.
6. Arquivo > Salvar como > `Amazon_Insights_TechChallenge4.pbix` nesta pasta `dashboard/Amazon_Insights_TechChallenge4/`, que é o arquivo citado no README.

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

Antes de carregar, confira no painel **Etapas aplicadas** da `fProdutos` que todas as etapas aparecem com nome em português. É isso que o avaliador vai olhar no critério "Preparação dos dados".

Pré-requisito: rodar o notebook uma vez, para gerar os dois CSVs em `data/processed/`.

## 2. Modelo

Na **Exibição de modelo**:

- Relacionamentos (ambos de um para muitos, direção única):
  - `fProdutos[product_id]` → `fReviews[product_id]`
  - `fReviews[review_id]` → `fTemas[review_id]`
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

## 3. Medidas

Siga as instruções do cabeçalho de `medidas_dax.dax`. O resultado da consulta de conferência precisa bater com a tabela "Valores esperados" do fim do arquivo. **Se algum número não bater, pare e investigue antes de montar as páginas.**

Pastas de exibição sugeridas: `1. Visão Executiva`, `2. Produtos e Categorias`, `3. Preços`, `4. Customer Insights`, `5. Títulos`.

## 4. Tema

Exibição > Temas > **Procurar temas** > `tema_amazon_insights.json`.

Tela: Formatar página > Configurações da tela > 16:9 (1280 x 720).

## 5. Páginas

Estrutura comum às 5 páginas:
- **Faixa superior:** título da página (frase com a conclusão) e 5 botões de navegação (Inserir > Botões > Navegador > Navegador de páginas).
- **Filtros à esquerda:** Categoria, Subcategoria e Faixa de preço, sincronizados nas páginas 1 a 4 (Exibição > Sincronizar segmentações).
- Todo visual com título que diga a conclusão, não o tema.

### Página 1 — Visão Executiva
| Visual | Campos |
|---|---|
| 6 cartões | Produtos · Nota média · % nota ≥ 4,0 · Avaliações · Desconto médio · % avaliações negativas |
| Barras agrupadas horizontais | Eixo: `categoria` · Valores: % do portfólio e % das avaliações |
| Colunas | Eixo: `faixa_nota` · Valor: Produtos |
| 4 cartões de quadrante | Produtos por `quadrante` (Consolidados 563, Atenção 112, Oportunidade 446, Baixa prioridade 227) |
| 3 cartões de alerta | Famílias em risco (40) · Famílias com oportunidade (58) · Produtos com alerta nos comentários (14), com botão para a página 2 |

### Página 2 — Produtos e Categorias
| Visual | Campos |
|---|---|
| Dispersão | X: `rating_count` (escala logarítmica) · Y: `rating` · Legenda: `quadrante` · Detalhes: `product_id` · Linhas de referência: X = 4.740 e Y = 4,0 |
| Matriz | Linhas: `categoria` > `subcategoria` · Valores: Produtos, Nota média, % nota ≥ 4,0, Desconto médio, Avaliações · Formatação condicional (barras de dados) em % nota ≥ 4,0 |
| Tabela "Risco de reputação" | Filtro: `risco_reputacao` = Verdadeiro · `nome_curto`, `subcategoria`, `rating`, `rating_count`, `discount_percentage` · Ordenar por `rating_count` |
| Tabela "Oportunidade de visibilidade" | Filtro: `oportunidade_visibilidade` = Verdadeiro · mesmas colunas · Ordenar por `nota_ponderada` |

### Página 3 — Preços e Estratégia Comercial
| Visual | Campos |
|---|---|
| 3 cartões | Desconto médio · % com desconto acima de 60% · Economia média |
| Colunas (destaque) | Eixo: `faixa_desconto` · Valor: % nota ≥ 4,0 · Título dinâmico: medida `Título Desconto` |
| Colunas | Eixo: `faixa_desconto` · Valor: Avaliações por produto (mediana) |
| Colunas | Eixo: `faixa_preco` · Valor: Desconto médio |
| Linhas | Eixo: `faixa_desconto` · Valor: % nota ≥ 4,0 · Legenda: `categoria` (filtrar as 3 principais) |

### Página 4 — Customer Insights
| Visual | Campos |
|---|---|
| 3 cartões | Avaliações de texto · % avaliações positivas · % avaliações negativas |
| Barras horizontais | Eixo: `fTemas[tema]` · Valor: % das avaliações que citam o tema |
| Barras horizontais | Eixo: `fTemas[tema]` · Valor: % negativas quando cita o tema · Linha constante = 9,8% · Cor condicional: vermelho quando "Vezes a média negativa" ≥ 2 |
| Barras | Eixo: `categoria` · Valor: % negativas sobre durabilidade |
| Linhas | Eixo: `faixa_desconto` · Valor: % cita durabilidade |
| Segmentações | `fTemas[tema]` e `fReviews[sentimento]` |
| Tabela | `fReviews[titulo]`, `fReviews[texto]`, `fProdutos[nome_curto]`: mostra as avaliações do tema e sentimento escolhidos |

### Página 5 — Recomendações
Caixas de texto no formato **Achado → Ação → Onde → Como acompanhar** (Seção 8 do notebook), cada uma com um cartão do número que sustenta a recomendação. No fim, as **3 mensagens para a liderança** e uma nota de limitações.

### Páginas ocultas (interatividade)
- **Detalhe do produto (drill-through):** Campo de drill-through `fProdutos[nome_curto]`. Cartões de nota, avaliações, desconto e quadrante, mais a tabela de avaliações do produto com o sentimento. Ativar nas tabelas das páginas 2 e 4. Incluir um cartão com a medida `Aviso sem avaliações de texto`: 493 produtos não têm avaliações de texto ligadas, e sem o aviso a página parece quebrada.
- **Tooltip do produto:** página com tamanho "Dica de ferramenta" (Informações da página > Permitir uso como dica de ferramenta), com nome, categoria, nota, avaliações, desconto e quadrante. Usar na dispersão da página 2.

## 6. Conferência antes de entregar

- [ ] Os valores da consulta DAX de conferência batem com o notebook
- [ ] Os filtros funcionam em todas as páginas e nenhum visual fica vazio ao filtrar uma categoria
- [ ] Os rótulos de dados estão com o formato certo (%, ₹, separador de milhar), sem nenhum "0" ou "1" arredondado
- [ ] Os botões de navegação funcionam (Ctrl + clique no Desktop)
- [ ] O drill-through abre a partir das tabelas
- [ ] O arquivo foi salvo, fechado, reaberto e atualizado sem erro
