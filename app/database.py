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

import psycopg
import streamlit as st

@st.cache_resource
def get_connection():
    """
    Estabelece a conexão com o banco de dados PostgreSQL usando psycopg3.
    Retorna o objeto de conexão se for bem-sucedido, ou None se falhar.
    """
    try:
        # Credenciais atualizadas com base no docker-compose.yml
        conn = psycopg.connect(
            dbname="greencheck",        # Nome do banco (sem o underline)
            user="admin",               # Usuário definido no Docker
            password="adminpassword",   # Senha definida no Docker
            host="localhost",
            port="5433"
        )
        return conn
    except Exception as e:
        st.error(f"Erro Crítico: Não foi possível conectar ao banco de dados. Detalhes: {e}")
        return None