let
    // Percentis de 1% a 100%, usados no eixo da curva de concentração (Pareto)
    Fonte = Table.FromColumns ( { List.Transform ( { 1 .. 100 }, each _ / 100 ) }, type table [ Percentil = number ] )
in
    Fonte
