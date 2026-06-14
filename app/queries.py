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