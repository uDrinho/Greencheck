# ==============================================================================
# Arquivo: database.py
# Módulo: Gerenciamento de Conexão com o Banco de Dados
# ==============================================================================
# JUSTIFICATIVAS DE ARQUITETURA E SEGURANÇA:
# 
# 1. Escolha do Driver (psycopg3): Adotamos a versão mais moderna do adaptador 
#    PostgreSQL para Python. Ele utiliza formatação de queries no lado do servidor 
#    (Server-side binding), o que estabelece a fundação tecnológica necessária 
#    para a nossa blindagem contra SQL Injection.
#
# 2. Otimização de Recursos (@st.cache_resource): Como o framework Streamlit 
#    reexecuta o script inteiro a cada clique do usuário, abrir uma nova conexão 
#    TCP com o banco a cada iteração esgotaria os recursos do servidor rapidamente. 
#    Este decorador funciona como um padrão Singleton (Connection Pooling simplificado),
#    abrindo a conexão apenas uma vez e mantendo-a em cache na memória.
#
# 3. Isolamento de Responsabilidade: Centralizar a conexão neste arquivo garante 
#    que o restante do sistema não precise conhecer credenciais, facilitando a 
#    futura injeção de variáveis de ambiente (.env) para esconder senhas.
# ==============================================================================

import time
import psycopg
import streamlit as st


@st.cache_resource
def _criar_conexao():
    """
    Cria uma nova conexão com o banco de dados PostgreSQL usando psycopg3.
    Retorna o objeto de conexão ou None em caso de falha.
    """
    try:
        conn = psycopg.connect(
            dbname="greencheck",
            user="admin",
            password="adminpassword",
            host="localhost",
            port="5433"
        )
        return conn
    except Exception:
        return None


def reset_connection():
    """Força a limpeza do cache de conexão, permitindo uma nova tentativa."""
    _criar_conexao.clear()


def get_connection():
    """
    Estabelece a conexão com o banco de dados PostgreSQL usando psycopg3.
    Retorna o objeto de conexão se for bem-sucedido, ou None se falhar.
    
    Tenta reconectar automaticamente até 3 vezes com intervalo de 2 segundos,
    caso a conexão esteja perdida ou ainda não esteja disponível.
    """
    tentativas = 3
    for i in range(tentativas):
        conn = _criar_conexao()
        if conn is not None and not conn.closed:
            return conn
        # Se a conexão falhou ou está fechada, limpa o cache e tenta novamente
        _criar_conexao.clear()
        if i < tentativas - 1:
            time.sleep(2)
    return None