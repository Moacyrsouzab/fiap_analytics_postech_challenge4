// fTemas: uma linha por avaliação e tema citado (uma avaliação pode ter vários temas).
// Origem: data/processed/reviews_temas.csv (gerado pelo notebook, Seção 6.3)
// Relacionamento: fReviews[review_id] 1 --> * fTemas[review_id]

let
    Fonte = Csv.Document(
        File.Contents(PastaDados & "processed\reviews_temas.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    CabecalhosPromovidos = Table.PromoteHeaders(Fonte, [PromoteAllScalars = true]),

    // Sentimento e produto já chegam pela fReviews através do relacionamento
    ColunasMantidas = Table.SelectColumns(CabecalhosPromovidos, {"review_id", "tema"}),
    TiposDefinidos = Table.TransformColumnTypes(ColunasMantidas, {{"review_id", type text}, {"tema", type text}})
in
    TiposDefinidos
