// fReviews: uma linha por avaliação, com o sentimento calculado no notebook (Seção 6).
// Origem: data/processed/reviews_sentimento.csv (gerado pelo notebook)
// Relacionamento: fProdutos[product_id] 1 --> * fReviews[product_id]

let
    Fonte = Csv.Document(
        File.Contents(PastaDados & "processed\reviews_sentimento.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    CabecalhosPromovidos = Table.PromoteHeaders(Fonte, [PromoteAllScalars = true]),

    // Os temas ficam na fTemas (formato longo); aqui mantemos só o necessário
    ColunasMantidas = Table.SelectColumns(
        CabecalhosPromovidos,
        {"review_id", "product_id", "titulo", "texto", "score_sentimento", "sentimento"}
    ),

    // O score vem com ponto decimal, por isso a cultura en-US
    TiposDefinidos = Table.TransformColumnTypes(
        ColunasMantidas,
        {
            {"review_id", type text},
            {"product_id", type text},
            {"titulo", type text},
            {"texto", type text},
            {"score_sentimento", type number},
            {"sentimento", type text}
        },
        "en-US"
    ),

    // Para ordenar Positiva > Neutra > Negativa nos visuais (Ordenar por coluna)
    OrdemDoSentimento = Table.AddColumn(
        TiposDefinidos,
        "ordem_sentimento",
        each if [sentimento] = "Positiva" then 1 else if [sentimento] = "Neutra" then 2 else 3,
        Int64.Type
    )
in
    OrdemDoSentimento
