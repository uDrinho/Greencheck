# ==============================================================================
# queries.py
# Repositório de Comandos SQL
# ==============================================================================
# Notas de Arquitetura e Segurança:

# 1. Prevenção contra SQL Injection:
#    A construção das queries evita intencionalmente a formatação de strings 
#    nativa do Python (como f-strings ou concatenação). Em vez disso, adota-se a 
#    parametrização através de marcadores de posição ('%s'). Dessa forma, o driver 
#    psycopg3 envia a estrutura do SQL e os dados de forma separada ao PostgreSQL, 
#    O SGBD trata as variáveis estritamente como literais proibindo injections

# 2. Delegação de Timestamp:
#    Na instrução de INSERT, optou-se por utilizar a função nativa CURRENT_TIMESTAMP 
#    do PostgreSQL. Isso transfere a responsabilidade do registro de tempo para o 
#    motor do banco de dados, prevenindo inconsistências relacionadas ao fuso 
#    horário ou relógio interno da máquina onde a aplicação Python está rodando.
# ==============================================================================


# ---------------------------------------------------------
# Funcionalidade 1: CONSULTA (SELECT)
# ---------------------------------------------------------


# Busca as informações básicas de um funcionário específico pelo CPF
BUSCAR_FUNCIONARIO_POR_CPF = """
    SELECT cpf, nome, cargo, salario, data_contratacao 
    FROM Funcionario 
    WHERE cpf = %s;
"""

# ---------------------------------------------------------
# Funcionalidade 2: INSERÇÃO (INSERT COM TRANSAÇÃO)
# ---------------------------------------------------------
# Para cadastrar um Trabalhador Rural, precisamos de duas queries.
# Elas serão executadas juntas no backend dentro de um bloco try/except.

# Query A: Insere na tabela genérica (Mãe)
INSERIR_FUNCIONARIO = """
    INSERT INTO Funcionario (cpf, salario, nome, cargo, contratado_por, data_contratacao) 
    VALUES (%s, %s, %s, %s, %s, CURRENT_TIMESTAMP);
"""

# Query B: Insere na tabela específica (Filha)
INSERIR_TRABALHADOR_RURAL = """
    INSERT INTO Trabalhador_Rural (cpf) 
    VALUES (%s);
"""

# ---------------------------------------------------------
# Consultas analíticas (Relatórios)
# ---------------------------------------------------------

SAFRAS_POR_TRABALHADOR = """
    SELECT s.id               AS safra_id,
           s.latitude,
           s.longitude,
           s.data_de_plantio,
           s.data_de_colheita,
           pa.nome            AS produto,
           s.quantidade_produzida
    FROM Trabalhador_Rural tr
    JOIN Trabalha t       ON tr.cpf = t.trabalhador_rural
    JOIN Safra s          ON t.safra = s.id
    JOIN Produto_Agricola pa ON s.produto_agricola = pa.nome
    WHERE tr.cpf = %s
    ORDER BY s.data_de_plantio DESC;
"""

ESTOQUE_E_VENDAS_PRODUTO = """
    SELECT pa.nome,
           pa.quantidade_em_estoque,
           COALESCE(SUM(vp.quantidade_vendida), 0) AS total_vendido,
           COALESCE(SUM(vp.quantidade_vendida * vp.preco), 0) AS receita_total
    FROM Produto_Agricola pa
    LEFT JOIN Venda_De_Produto vp ON pa.nome = vp.produto_agricola
    WHERE pa.nome = %s
    GROUP BY pa.nome, pa.quantidade_em_estoque;
"""

LOTES_MAIS_AVALIADOS = """
    SELECT l.latitude,
           l.longitude,
           COUNT(*) AS total_avaliacoes
    FROM Lote l
    JOIN Avaliacao a ON l.latitude = a.latitude AND l.longitude = a.longitude
    GROUP BY l.latitude, l.longitude
    HAVING COUNT(*) >= ALL (
        SELECT COUNT(*)
        FROM Avaliacao
        GROUP BY latitude, longitude
    )
    AND (SELECT COUNT(*) FROM Avaliacao) > 0;
"""

ENGENHEIROS_COBERTURA_TOTAL = """
    SELECT e.cpf, f.nome
    FROM Engenheiro_Agronomo e
    JOIN Funcionario f ON e.cpf = f.cpf
    WHERE NOT EXISTS (
        SELECT l.latitude, l.longitude
        FROM Lote l
        WHERE NOT EXISTS (
            SELECT 1
            FROM Avaliacao a
            WHERE a.latitude  = l.latitude
              AND a.longitude = l.longitude
              AND a.avaliador = e.cpf
        )
    );
"""

GERENTES_TRANSACOES_COMPLETAS = """
    SELECT g.cpf, f.nome
    FROM Gerente_Agricola g
    JOIN Funcionario f ON g.cpf = f.cpf
    WHERE NOT EXISTS (
        SELECT t.tipo FROM (VALUES ('Venda'), ('Compra'), ('Manutencao')) AS t(tipo)
        EXCEPT
        (
            SELECT 'Venda' FROM Venda v WHERE v.gerente_agricola = g.cpf
            UNION ALL
            SELECT 'Compra' FROM Compra c WHERE c.gerente_agricola = g.cpf
            UNION ALL
            SELECT 'Manutencao' FROM Manutencao m WHERE m.gerente_agricola = g.cpf
        )
    );
"""

VERIFICAR_TRABALHADOR_EXISTE = """
    SELECT 1 FROM Trabalhador_Rural WHERE cpf = %s;
"""