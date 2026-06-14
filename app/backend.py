# ==============================================================================
# Arquivo: backend.py
# Módulo: Regras de Negócio e Controle Transacional
# ==============================================================================
# JUSTIFICATIVAS DE ARQUITETURA E INTEGRIDADE (ACID):
#
# 1. Princípio da Atomicidade (Transação Explícita): 
#    A função 'cadastrar_trabalhador' interage com duas tabelas diferentes 
#    ('Funcionario' e 'Trabalhador_Rural') devido à modelagem de herança. 
#    O uso explícito de 'conn.commit()' e 'conn.rollback()' garante que a 
#    transação seja atômica: ou os dados são inseridos em ambas as tabelas 
#    simultaneamente, ou, em caso de qualquer falha na segunda etapa, a primeira 
#    inserção é totalmente desfeita (rollback), impedindo a existência de 
#    dados inconsistentes no SGBD.
#
# 2. Tratamento de Exceções Específicas:
#    Ao invés de deixar a aplicação "quebrar" quando o banco recusa uma 
#    operação, capturamos erros específicos como 'psycopg.IntegrityError'. Isso 
#    permite que violações de restrição (como Chave Primária duplicada ou Chave 
#    Estrangeira inválida) sejam traduzidas do dialeto técnico do banco de dados 
#    para dicionários Python mais user-friendly, que o frontend exibe ao usuário.
#
# 3. Formatação de Dados:
#    Na função de busca, a utilização do 'psycopg.rows.dict_row' converte as tuplas 
#    nativas do PostgreSQL diretamente em dicionários Python. Isso reduz o acoplamento, 
#    pois o frontend pode acessar os dados por chaves (ex: dados['nome']) ao invés de 
#    índices numéricos fixos (ex: dados[1]), facilitando a manutenção futura do esquema.
# ==============================================================================



import psycopg
from database import get_connection
import queries

def buscar_funcionario(cpf):
    """
    Executa a funcionalidade de CONSULTA.
    Retorna um dicionário com os dados do funcionário ou None se não encontrar.
    """
    conn = get_connection()
    if not conn:
        return {"sucesso": False, "mensagem": "Sem conexão com o banco."}

    try:
        # Cria um cursor para executar o comando
        # Row-factory de dicionário facilita a exibição no Streamlit depois
        with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
            # O psycopg3 faz a substituição segura do '%s' pelo 'cpf'
            cur.execute(queries.BUSCAR_FUNCIONARIO_POR_CPF, (cpf,))
            resultado = cur.fetchone()
            
            if resultado:
                return {"sucesso": True, "dados": resultado}
            else:
                return {"sucesso": False, "mensagem": "Funcionário não encontrado."}
                
    except Exception as e:
        return {"sucesso": False, "mensagem": f"Erro na consulta: {e}"}


def cadastrar_trabalhador(cpf, nome, salario, contratado_por):
    """
    Executa a funcionalidade de INSERÇÃO utilizando TRANSAÇÃO EXPLÍCITA.
    Garante que os dados vão para as duas tabelas ou para nenhuma.
    """
    conn = get_connection()
    if not conn:
        return {"sucesso": False, "mensagem": "Sem conexão com o banco."}

    try:
        # Iniciamos o cursor. O psycopg3 por padrão não faz autocommit, 
        # o que é contribui para o controle transacional.
        with conn.cursor() as cur:
            # PASSO 1: Insere na tabela genérica (Funcionario)
            # O cargo é fixo nesta função: 'Trabalhador Rural'
            cur.execute(
                queries.INSERIR_FUNCIONARIO, 
                (cpf, salario, nome, 'Trabalhador Rural', contratado_por)
            )

            # PASSO 2: Insere na tabela específica (Trabalhador_Rural)
            cur.execute(
                queries.INSERIR_TRABALHADOR_RURAL, 
                (cpf,)
            )

            # PASSO 3: Confirmação (COMMIT)
            # Se chegamos até aqui sem erros, consolidamos no banco de dados.
            conn.commit()
            return {"sucesso": True, "mensagem": "Trabalhador Rural cadastrado com sucesso!"}

    except psycopg.IntegrityError as e:
        # Se der erro de chave (ex: CPF já existe, ou gerente não encontrado)
        # PASSO 4: Reversão (ROLLBACK) - Garante que o banco não fique inconsistente
        conn.rollback()
        return {"sucesso": False, "mensagem": f"Erro de Integridade: Verifique se o CPF já existe ou se o CPF do Gerente é válido. Detalhes: {e}"}
        
    except Exception as e:
        # Qualquer outro erro inesperado (ex: banco caiu no meio do processo)
        conn.rollback()
        return {"sucesso": False, "mensagem": f"Erro Crítico: Operação desfeita (Rollback executado). Detalhes: {e}"}