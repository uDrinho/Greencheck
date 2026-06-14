# ==============================================================================
# Arquivo: app.py
# Módulo: Interface do Usuário (Frontend em Streamlit)
# ==============================================================================

# JUSTIFICATIVAS DE ARQUITETURA E SEGURANÇA:

# 1. Primeira Linha de Defesa (Sanitização via Expressões Regulares): 
#    A função 'limpar_cpf' utiliza Regex (re.sub) para remover qualquer caractere 
#    não numérico antes de enviar o dado ao backend. Isso cria uma segurança na camada   
#    de apresentação, eliminando aspas, espaços e ponto e vírgula, mitigando 
#    potenciais payloads de SQL Injection antes mesmo de chegarem ao driver.

# 2. Resolução de Inconsistência Semântica na Aplicação: 
#    O modelo relacional puro não impede nativamente que um gerente contrate a si mesmo. 
#    Esta regra de negócio essencial foi blindada diretamente no frontend através da 
#    validação lógica (cpf_limpo == gerente_limpo)

# 3. Desacoplamento Estrito (MVC Simplificado): 
#    A interface é agnóstica em relação ao banco de dados. Ela não conhece tabelas, 
#    portas ou comandos SQL; ela apenas consome as funções do módulo 'backend', 
#    tratando os dicionários retornados para exibir mensagens amigáveis (st.success/st.error).
# ==============================================================================

import streamlit as st
import re
import backend

# ---------------------------------------------------------
# 1. Configuração Inicial da Página
# ---------------------------------------------------------
st.set_page_config(
    page_title="Green Check", 
    page_icon="🌱", 
    layout="centered"
)

st.title("🌱 Green Check")
st.subheader("Sistema de Gerenciamento de Lavoura")
st.markdown("---")

# ---------------------------------------------------------
# 2. Funções Auxiliares
# ---------------------------------------------------------
def limpar_cpf(cpf_digitado):
    """Remove pontos, traços e espaços, mantendo apenas os números."""
    return re.sub(r'\D', '', cpf_digitado)

# ---------------------------------------------------------
# 3. Estrutura de Navegação (Abas)
# ---------------------------------------------------------
# Nomes de variáveis mais claros para as abas
aba_consulta, aba_cadastro = st.tabs([
    " Consultar Funcionário", 
    " Cadastrar Trabalhador Rural"
])

# =========================================================
# ABA 1: CONSULTA (SELECT)
# =========================================================
with aba_consulta:
    st.header("Consulta de Funcionário")
    st.write("Busque um funcionário cadastrado pelo seu CPF.")
    
    cpf_busca = st.text_input(
        "CPF do Funcionário (Busca)", 
        placeholder="Ex: 123.456.789-00", 
        max_chars=14
    )
    
    if st.button("Buscar Dados", type="primary"):
        cpf_limpo = limpar_cpf(cpf_busca)
        
        if len(cpf_limpo) != 11:
            st.warning(" O CPF deve conter exatamente 11 números.")
        else:
            with st.spinner("Consultando banco de dados..."):
                resposta = backend.buscar_funcionario(cpf_limpo)
                
                if resposta["sucesso"]:
                    st.success("Funcionário localizado com sucesso!")
                    st.markdown("---")
                    
                    dados = resposta["dados"]
                    
                    # Layout original de 2 colunas, mas com tipografia focada em UX (sem cortes)
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        st.caption("NOME COMPLETO")
                        st.subheader(dados["nome"])
                        
                        st.write("") # Espaço em branco sutil
                        
                        st.caption("CARGO")
                        st.subheader(dados["cargo"])
                        
                    with col2:
                        st.caption("SALÁRIO")
                        st.subheader(f"R$ {dados['salario']:.2f}")
                        
                        st.write("") # Espaço em branco sutil
                        
                        st.caption("DATA DE CONTRATAÇÃO")
                        st.subheader(dados["data_contratacao"].strftime("%d/%m/%Y"))
                else:
                    st.error(resposta["mensagem"])

# =========================================================
# ABA 2: INSERÇÃO (INSERT)
# =========================================================
with aba_cadastro:
    st.header("Novo Trabalhador Rural")
    st.write("Preencha os dados abaixo para registrar um novo trabalhador na lavoura.")
    
    # Usamos st.form para agrupar os campos e validar tudo junto
    with st.form("form_cadastro", clear_on_submit=True):
        colA, colB = st.columns(2)
        
        with colA:
            nome_input = st.text_input("Nome Completo*", max_chars=60)
            cpf_input = st.text_input("CPF do Trabalhador*", placeholder="Somente números", max_chars=14)
            
        with colB:
            salario_input = st.number_input("Salário (R$)*", min_value=0.0, step=100.0, format="%.2f")
            gerente_input = st.text_input("CPF do Gerente Contratante*", placeholder="Apenas números", max_chars=14)
            
        st.caption("* Campos obrigatórios")
        
        # type="primary" deixa o botão de cadastro com mais destaque
        submit_button = st.form_submit_button("Cadastrar Trabalhador", type="primary")
        
        # Lógica de validação e envio ao clicar no botão
        if submit_button:
            cpf_limpo = limpar_cpf(cpf_input)
            gerente_limpo = limpar_cpf(gerente_input)
            
            # Validação 1: Campos em branco ou com tamanho errado
            if not nome_input or len(cpf_limpo) != 11 or len(gerente_limpo) != 11 or salario_input <= 0:
                st.warning(" Preencha todos os campos corretamente. Os CPFs devem ter 11 dígitos.")
            
            # Validação 2: Regra de Negócio (Paradoxo do Gerente)
            elif cpf_limpo == gerente_limpo:
                st.error(" Operação Bloqueada: Um funcionário não pode ser contratado por si mesmo.")
            
            # Sucesso nas validações de interface: Envia para o backend (banco)
            else:
                with st.spinner("Registrando no banco de dados..."):
                    resposta = backend.cadastrar_trabalhador(
                        cpf=cpf_limpo, 
                        nome=nome_input, 
                        salario=salario_input, 
                        contratado_por=gerente_limpo
                    )
                    
                    if resposta["sucesso"]:
                        st.success(resposta["mensagem"])
                        st.balloons()
                    else:
                        st.error(resposta["mensagem"])