// fProdutos: uma linha por produto, tratada a partir do amazon.csv BRUTO.
// Replica as decisões da Seção 4 do notebook; os números precisam bater com os de lá.
// Depende de: PastaDados (parâmetro) e fReviews (para o alerta de comentários).

let
    // ---------------------------------------------------------------- Leitura
    Fonte = Csv.Document(
        File.Contents(PastaDados & "amazon.csv"),
        [Delimiter = ",", Columns = 16, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    CabecalhosPromovidos = Table.PromoteHeaders(Fonte, [PromoteAllScalars = true]),

    // Guarda a ordem original das linhas: usada para desempatar duplicados
    OrdemDoArquivo = Table.AddIndexColumn(CabecalhosPromovidos, "ordem_arquivo", 1, 1, Int64.Type),

    // Links e dados de usuário não entram na análise; o texto das avaliações vem tratado pela fReviews.
    // review_id fica: identifica a família de variantes que divide as mesmas avaliações (Seção 3.1).
    ColunasMantidas = Table.SelectColumns(
        OrdemDoArquivo,
        {"ordem_arquivo", "product_id", "product_name", "category", "discounted_price", "actual_price",
         "discount_percentage", "rating", "rating_count", "review_id"}
    ),

    // ---------------------------------------------------------------- Conversão de tipos
    // Remove ₹, % e a vírgula de milhar (formato indiano: 3,13,836)
    SimbolosRemovidos = Table.TransformColumns(
        ColunasMantidas,
        {
            {"discounted_price", each Text.Remove(_, {"₹", ","}), type text},
            {"actual_price", each Text.Remove(_, {"₹", ","}), type text},
            {"discount_percentage", each Text.Remove(_, {"%"}), type text},
            {"rating_count", each Text.Remove(_, {","}), type text}
        }
    ),

    // O que não vira número (a nota "|" e os rating_count vazios) fica nulo
    TextoParaNumero = Table.TransformColumns(
        SimbolosRemovidos,
        {
            {"discounted_price", each try Number.FromText(_, "en-US") otherwise null, type number},
            {"actual_price", each try Number.FromText(_, "en-US") otherwise null, type number},
            {"discount_percentage", each try Number.FromText(_, "en-US") otherwise null, type number},
            {"rating", each try Number.FromText(_, "en-US") otherwise null, type number},
            {"rating_count", each try Number.FromText(_, "en-US") otherwise null, Int64.Type}
        }
    ),

    // ---------------------------------------------------------------- Duplicados
    // Fica a linha com mais avaliações (retrato mais recente); no empate, a primeira do arquivo.
    // O Table.Buffer fixa a ordenação antes do Table.Distinct (sem ele, a linha mantida pode variar).
    OrdenadoParaDeduplicar = Table.Buffer(
        Table.Sort(TextoParaNumero, {{"rating_count", Order.Descending}, {"ordem_arquivo", Order.Ascending}})
    ),
    DuplicadosRemovidos = Table.Distinct(OrdenadoParaDeduplicar, {"product_id"}),

    // ---------------------------------------------------------------- Categorias
    NiveisDaCategoria = Table.AddColumn(DuplicadosRemovidos, "niveis", each Text.Split([category], "|"), type list),
    CategoriaOriginal = Table.AddColumn(NiveisDaCategoria, "categoria_original", each [niveis]{0}, type text),
    SubcategoriaOriginal = Table.AddColumn(CategoriaOriginal, "subcategoria_original", each [niveis]{1}?, type text),
    CategoriaFinal = Table.AddColumn(SubcategoriaOriginal, "categoria_final", each List.Last([niveis]), type text),

    TraducaoCategoria = [
        Electronics = "Eletrônicos",
        #"Computers&Accessories" = "Computadores e Acessórios",
        #"Home&Kitchen" = "Casa e Cozinha",
        OfficeProducts = "Escritório"
    ],
    // As 5 categorias com 1 ou 2 produtos viram "Outras"
    CategoriaTraduzida = Table.AddColumn(
        CategoriaFinal, "categoria",
        each Record.FieldOrDefault(TraducaoCategoria, [categoria_original], "Outras"), type text
    ),

    TraducaoSubcategoria = [
        #"Accessories&Peripherals" = "Acessórios e periféricos",
        #"Kitchen&HomeAppliances" = "Eletroportáteis",
        #"HomeTheater,TV&Video" = "TV, vídeo e home theater",
        #"Mobiles&Accessories" = "Celulares e acessórios",
        #"Heating,Cooling&AirQuality" = "Aquecimento, ventilação e ar",
        #"Headphones,Earbuds&Accessories" = "Fones de ouvido",
        WearableTechnology = "Vestíveis (smartwatches)",
        NetworkingDevices = "Redes (roteadores, adaptadores)",
        OfficePaperProducts = "Papelaria",
        #"ExternalDevices&DataStorage" = "Armazenamento externo",
        #"HomeStorage&Organization" = "Organização da casa",
        HomeAudio = "Áudio doméstico",
        #"Cameras&Photography" = "Câmeras e fotografia",
        #"GeneralPurposeBatteries&BatteryChargers" = "Pilhas e carregadores",
        #"Printers,Inks&Accessories" = "Impressoras e tintas",
        Accessories = "Acessórios de eletrônicos",
        CraftMaterials = "Materiais de artesanato",
        Components = "Componentes de informática",
        OfficeElectronics = "Eletrônicos de escritório",
        Microphones = "Microfones",
        Electrical = "Material elétrico",
        Monitors = "Monitores",
        #"Kitchen&Dining" = "Cozinha e mesa",
        PowerAccessories = "Acessórios de energia",
        #"Arts&Crafts" = "Artes e artesanato",
        #"HomeMedicalSupplies&Equipment" = "Equipamentos de saúde",
        Tablets = "Tablets",
        CarAccessories = "Acessórios automotivos",
        Laptops = "Notebooks"
    ],
    SubcategoriaTraduzida = Table.AddColumn(
        CategoriaTraduzida, "subcategoria",
        each Record.FieldOrDefault(TraducaoSubcategoria, [subcategoria_original], [subcategoria_original]), type text
    ),

    // ---------------------------------------------------------------- Colunas derivadas
    Economia = Table.AddColumn(SubcategoriaTraduzida, "economia", each [actual_price] - [discounted_price], type number),
    DescontoPercentual = Table.AddColumn(Economia, "desconto", each [discount_percentage] / 100, Percentage.Type),
    NomeCurto = Table.AddColumn(
        DescontoPercentual, "nome_curto",
        each Text.Start(Text.Trim(Text.SplitAny([product_name], ",|("){0}), 60), type text
    ),

    FaixaDeDesconto = Table.AddColumn(
        NomeCurto, "faixa_desconto",
        each if [discount_percentage] = null then null
            else if [discount_percentage] <= 20 then "0-20%"
            else if [discount_percentage] <= 40 then "21-40%"
            else if [discount_percentage] <= 60 then "41-60%"
            else if [discount_percentage] <= 80 then "61-80%"
            else "81-94%",
        type text
    ),
    OrdemFaixaDesconto = Table.AddColumn(
        FaixaDeDesconto, "ordem_faixa_desconto",
        each List.PositionOf({"0-20%", "21-40%", "41-60%", "61-80%", "81-94%"}, [faixa_desconto]) + 1, Int64.Type
    ),

    FaixaDePreco = Table.AddColumn(
        OrdemFaixaDesconto, "faixa_preco",
        each if [discounted_price] <= 200 then "Até ₹200"
            else if [discounted_price] <= 500 then "₹201-500"
            else if [discounted_price] <= 1000 then "₹501-1.000"
            else if [discounted_price] <= 5000 then "₹1.001-5.000"
            else "Acima de ₹5.000",
        type text
    ),
    OrdemFaixaPreco = Table.AddColumn(
        FaixaDePreco, "ordem_faixa_preco",
        each List.PositionOf({"Até ₹200", "₹201-500", "₹501-1.000", "₹1.001-5.000", "Acima de ₹5.000"}, [faixa_preco]) + 1,
        Int64.Type
    ),

    FaixaDeNota = Table.AddColumn(
        OrdemFaixaPreco, "faixa_nota",
        each if [rating] = null then null
            else if [rating] < 3.8 then "Abaixo de 3,8"
            else if [rating] < 4.0 then "3,8 a 3,9"
            else if [rating] < 4.3 then "4,0 a 4,2"
            else "4,3 ou mais",
        type text
    ),
    OrdemFaixaNota = Table.AddColumn(
        FaixaDeNota, "ordem_faixa_nota",
        each if [faixa_nota] = null then null
            else List.PositionOf({"Abaixo de 3,8", "3,8 a 3,9", "4,0 a 4,2", "4,3 ou mais"}, [faixa_nota]) + 1,
        Int64.Type
    ),

    // ---------------------------------------------------------------- Estatísticas da base (Seções 5.1 e 5.3)
    // Calculadas só sobre produtos com nota válida, como no notebook
    ProdutosComNota = Table.SelectRows(OrdemFaixaNota, each [rating] <> null),
    AvaliacoesValidas = List.RemoveNulls(ProdutosComNota[rating_count]),
    NotaMediaGeral = List.Average(ProdutosComNota[rating]),
    MedianaAvaliacoes = List.Median(AvaliacoesValidas),
    Percentil25 = List.Percentile(AvaliacoesValidas, 0.25, [PercentileMode = PercentileMode.ExcelInc]),
    Percentil75 = List.Percentile(AvaliacoesValidas, 0.75, [PercentileMode = PercentileMode.ExcelInc]),

    // Média bayesiana: puxa para a média geral os produtos com poucas avaliações
    NotaPonderada = Table.AddColumn(
        OrdemFaixaNota, "nota_ponderada",
        each if [rating] = null then null
            else
                let v = if [rating_count] = null then 0 else [rating_count]
                in v / (v + Percentil25) * [rating] + Percentil25 / (v + Percentil25) * NotaMediaGeral,
        type number
    ),

    // Cortes: engajamento acima da mediana; satisfação com nota >= 4,0
    Quadrante = Table.AddColumn(
        NotaPonderada, "quadrante",
        each if [rating] = null then null
            else if [rating_count] = null then "Sem dados de engajamento"
            else if [rating_count] >= MedianaAvaliacoes and [rating] >= 4 then "Consolidados"
            else if [rating_count] >= MedianaAvaliacoes then "Atenção: alcance alto, nota baixa"
            else if [rating] >= 4 then "Oportunidade: nota alta, pouca visibilidade"
            else "Baixa prioridade",
        type text
    ),
    OrdemQuadrante = Table.AddColumn(
        Quadrante, "ordem_quadrante",
        each if [quadrante] = null then null
            else List.PositionOf({"Consolidados", "Atenção: alcance alto, nota baixa",
                "Oportunidade: nota alta, pouca visibilidade", "Baixa prioridade", "Sem dados de engajamento"},
                [quadrante]) + 1,
        Int64.Type
    ),

    // Listas da Seção 5.3, com cortes mais rígidos
    RiscoDeReputacao = Table.AddColumn(
        OrdemQuadrante, "risco_reputacao",
        each [rating] <> null and [rating_count] <> null and [rating_count] >= Percentil75 and [rating] < 4,
        type logical
    ),
    OportunidadeDeVisibilidade = Table.AddColumn(
        RiscoDeReputacao, "oportunidade_visibilidade",
        each [rating] <> null and [rating_count] <> null
            and [rating_count] >= 100 and [rating_count] <= Percentil25 and [rating] >= 4.3,
        type logical
    ),

    // ---------------------------------------------------------------- Alerta dos comentários (Seção 6.5)
    NegativasPorProduto = Table.Group(
        fReviews, {"product_id"},
        {
            {"avaliacoes_texto", each Table.RowCount(_), Int64.Type},
            {"avaliacoes_negativas", each List.Count(List.Select([sentimento], each _ = "Negativa")), Int64.Type}
        }
    ),
    MesclarNegativas = Table.NestedJoin(
        OportunidadeDeVisibilidade, {"product_id"}, NegativasPorProduto, {"product_id"}, "neg", JoinKind.LeftOuter
    ),
    ExpandirNegativas = Table.ExpandTableColumn(
        MesclarNegativas, "neg", {"avaliacoes_texto", "avaliacoes_negativas"}, {"avaliacoes_texto", "avaliacoes_negativas"}
    ),
    AlertaDosComentarios = Table.AddColumn(
        ExpandirNegativas, "alerta_comentarios",
        each [rating] <> null and [rating] >= 4 and [avaliacoes_negativas] <> null and [avaliacoes_negativas] >= 3,
        type logical
    ),

    // ---------------------------------------------------------------- Acabamento
    FamiliaRenomeada = Table.RenameColumns(AlertaDosComentarios, {{"review_id", "familia"}}),
    ColunasAuxiliaresRemovidas = Table.RemoveColumns(FamiliaRenomeada, {"ordem_arquivo", "niveis", "category"}),
    TiposFinais = Table.TransformColumnTypes(
        ColunasAuxiliaresRemovidas,
        {
            {"product_id", type text}, {"product_name", type text}, {"familia", type text},
            {"avaliacoes_texto", Int64.Type}, {"avaliacoes_negativas", Int64.Type}
        }
    )
in
    TiposFinais
