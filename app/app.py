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
aba_consulta, aba_cadastro, aba_relatorios = st.tabs([
    " Consultar Funcionário", 
    " Cadastrar Trabalhador Rural",
    " Relatórios Gerenciais"
])

# =========================================================
# ABA 1: CONSULTA (SELECT)
# =========================================================
with aba_consulta:
    st.header("Consulta de Funcionário")
    st.write("Busque um funcionário cadastrado pelo seu CPF.")
    
    with st.form("form_consulta", clear_on_submit=False):
        cpf_busca = st.text_input(
            "CPF do Funcionário (Busca)", 
            placeholder="Ex: 123.456.789-00", 
            max_chars=14
        )
        
        submitted = st.form_submit_button("Buscar Dados", type="primary")
        
    if submitted:
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
                    
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        st.caption("NOME COMPLETO")
                        st.subheader(dados["nome"])
                        
                        st.write("")
                        
                        st.caption("CARGO")
                        st.subheader(dados["cargo"])
                        
                    with col2:
                        st.caption("SALÁRIO")
                        st.subheader(f"R$ {dados['salario']:.2f}")
                        
                        st.write("")
                        
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

# =========================================================
# ABA 3: RELATÓRIOS GERENCIAIS
# =========================================================
with aba_relatorios:
    st.header("Relatórios e Análises")
    st.write("Ferramentas de apoio à decisão para engenheiros e gerentes.")

    # ------------------------------------------------------
    # Relatório 1: Safras por Trabalhador
    # ------------------------------------------------------
    st.subheader(" Safras de um Trabalhador Rural")
    with st.form("form_safras_trabalhador", clear_on_submit=False):
        cpf_trab = st.text_input("CPF do Trabalhador", key="cpf_trab")
        submitted = st.form_submit_button("Buscar Safras")
    if submitted:
        cpf_limpo = limpar_cpf(cpf_trab)
        if len(cpf_limpo) != 11:
            st.warning("CPF deve ter 11 dígitos.")
        elif not backend.trabalhador_existe(cpf_limpo):
            st.error("Trabalhador não encontrado.")
        else:
            with st.spinner("Consultando..."):
                resposta = backend.listar_safras_trabalhador(cpf_limpo)
                if resposta["sucesso"]:
                    if resposta["dados"]:
                        st.success(f"Safras encontradas: {len(resposta['dados'])}")
                        st.dataframe(resposta["dados"])
                    else:
                        st.info("Nenhuma safra encontrada para este trabalhador.")
                else:
                    st.error(resposta["mensagem"])

    st.markdown("---")

    # ------------------------------------------------------
    # Relatório 2: Estoque e Vendas de Produto
    # ------------------------------------------------------
    st.subheader(" Estoque e Vendas de um Produto")
    with st.form("form_estoque_vendas", clear_on_submit=False):
        nome_produto = st.text_input("Nome do Produto Agrícola", key="nome_prod")
        submitted = st.form_submit_button("Consultar Produto")
    if submitted:
        if not nome_produto.strip():
            st.warning("Informe o nome do produto.")
        else:
            with st.spinner("Consultando..."):
                resposta = backend.estoque_vendas_produto(nome_produto.strip())
                if resposta["sucesso"]:
                    dados = resposta["dados"]
                    col1, col2, col3 = st.columns(3)
                    col1.metric("Estoque Atual", f"{dados['quantidade_em_estoque']} kg")
                    col2.metric("Total Vendido", f"{dados['total_vendido']} kg")
                    col3.metric("Receita Total", f"R$ {dados['receita_total']:,.2f}")
                else:
                    st.error(resposta["mensagem"])

    st.markdown("---")

    # ------------------------------------------------------
    # Relatório 3: Lotes Mais Avaliados
    # ------------------------------------------------------
    st.subheader(" Lotes com Maior Nº de Avaliações")
    with st.form("form_lotes_avaliados"):
        submitted = st.form_submit_button("Exibir Lotes Mais Monitorados")
    if submitted:
        with st.spinner("Analisando..."):
            resposta = backend.lotes_mais_avaliados()
            if resposta["sucesso"]:
                if resposta["dados"]:
                    st.dataframe(resposta["dados"])
                else:
                    st.info("Nenhum lote avaliado ainda.")
            else:
                st.error(resposta["mensagem"])

    st.markdown("---")

    # ------------------------------------------------------
    # Relatório 4: Engenheiros com Cobertura Total
    # ------------------------------------------------------
    st.subheader(" Engenheiros que Avaliaram Todos os Lotes")
    with st.form("form_engenheiros_cobertura"):
        submitted = st.form_submit_button("Listar Engenheiros Completos")
    if submitted:
        with st.spinner("Verificando cobertura..."):
            resposta = backend.engenheiros_cobertura_total()
            if resposta["sucesso"]:
                if resposta["dados"]:
                    st.dataframe(resposta["dados"])
                else:
                    st.info("Nenhum engenheiro avaliou todos os lotes.")
            else:
                st.error(resposta["mensagem"])

    st.markdown("---")

    # ------------------------------------------------------
    # Relatório 5: Gerentes com Todas as Transações
    # ------------------------------------------------------
    st.subheader(" Gerentes com Venda, Compra e Manutenção")
    with st.form("form_gerentes_transacoes"):
        submitted = st.form_submit_button("Listar Gerentes Completos")
    if submitted:
        with st.spinner("Verificando transações..."):
            resposta = backend.gerentes_transacoes_completas()
            if resposta["sucesso"]:
                if resposta["dados"]:
                    st.dataframe(resposta["dados"])
                else:
                    st.info("Nenhum gerente realizou todos os tipos de transação.")
            else:
                st.error(resposta["mensagem"])