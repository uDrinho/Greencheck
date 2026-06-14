## Green Check
Lucas Dúckur Nunes Andreolli - 15471518
Caio Draco Araújo Albuquerque Galvão - 15573731
Pedro Henrique Barbosa Oliveira - 15483776
Marcos Vinicius Cota Rodrigues da Trindade - 15511001
Kattryel Henrique Santos Rezende - 15522383

---

### Descrição do problema e dos requisitos de dados
A Revolução Verde aumentou consideravelmente a produtividade do setor agrícola com inovações tecnológicas e mecanização, contudo, trouxe também desafios logísticos e organizacionais para as grandes lavouras. Atualmente, o gerenciamento do processo produtivo exige a coordenação de profissionais qualificados e um controle rigoroso de recursos tecnológicos, ambientais e financeiros. Registros tradicionais, baseados apenas nos resultados finais das safras, não são mais suficientes para produtores rurais de grande porte. 

O sistema proposto, Green Check, atende a essa demanda oferecendo uma plataforma digital completa para o registro e controle de todas as operações de uma lavoura. Nele, trabalhadores rurais, gerentes agrícolas e engenheiros agrônomos podem documentar detalhes sobre produção, uso de insumos, qualidade do solo e transações financeiras. Para mitigar o erro humano e maximizar a eficiência, o sistema realiza a gestão automática dos estoques de insumos e produtos agrícolas, com base no uso diário e nas operações de compra e venda cadastradas. O cruzamento dessas informações garante a rastreabilidade da produção e otimiza a alocação de recursos do negócio.

---

### Relacionamento entre entidades do 'mundo real'
O sistema possui diferentes tipos de Funcionários (identificados por CPF, com salário, nome e cargo), que se dividem obrigatoriamente entre Gerentes Agrícolas, Engenheiros Agrônomos e Trabalhadores Rurais. Gerentes são os únicos responsáveis por contratar outros funcionários. As terras são divididas em Lotes, identificados por sua localização exata (latitude e longitude) e com dimensões definidas. 

O fluxo produtivo gira em torno da Safra, que é plantada em um Lote específico em uma data determinada. Toda Safra produz exatamente um Produto Agrícola e exige a utilização de Insumos. Os Insumos são categorizados em diferentes subtipos, como Água (que exige medição de pH), Sementes (identificadas por tecnologias transgênicas específicas), Máquinas, Fertilizantes e Defensivos. É obrigatório indicar qual semente específica originou cada produto agrícola armazenado.

A plataforma também monitora o estado físico dos Lotes através de Avaliações contínuas, onde são documentados a umidade, permeabilidade, pH e teores de nutrientes do solo. Com base nisso, o uso de insumos é estipulado e o planejamento de novas safras é definido. 

Para a integração comercial, o sistema registra Empresas Externas, identificadas por CNPJ, que assumem papéis de Compradores, Fornecedores ou Técnicos de Manutenção. Todas as transações com essas entidades, como Vendas de produtos, Compras de insumos e Manutenção de maquinário, geram notas fiscais e atualizam automaticamente os estoques e o fluxo de caixa.

---

### Principais funcionalidades
O acesso e as funcionalidades do sistema são segmentados de acordo com o cargo do funcionário na lavoura:

**Trabalhador Rural**
* Consulta do histórico de todas as safras nas quais participou.
* Cadastro e registro de participação ativa em novas safras vigentes.

**Gerente Agrícola**
* Consulta e cadastro de informações sobre os Lotes da propriedade.
* Pesquisa de perfil de funcionários via CPF e cadastro de novos contratados no sistema.
* Gerenciamento de estoque, com consulta de quantidades e cadastro de novos Produtos Agrícolas e Insumos, possuindo privilégio para alteração manual em casos de exceção.
* Consulta via CNPJ e cadastro de Empresas Externas parceiras (Compradores, Fornecedores e Manutenção).
* Registro e consulta de transações comerciais ativas, como Vendas, Compras e Agendamentos de Manutenção, incluindo a emissão de notas fiscais.
* Consulta gerencial sobre o andamento das Safras e a alocação dos trabalhadores rurais vinculados a elas.

**Engenheiro Agrônomo**
* Consulta direta das disponibilidades de Insumos no estoque antes de realizar estipulações.
* Cadastro estrutural de novas Safras.
* Registro final da data de colheita e das quantidades exatas produzidas pela Safra.
* Cadastro e consulta do histórico de Avaliações detalhadas do solo de um respectivo Lote.
* Registro de Planejamento prospectivo de safras, estipulando expectativas de colheita e datas-alvo.
* Estipulação técnica de quais Insumos (e suas quantidades) serão utilizados em uma dada Safra.

---

### Discussões sobre ciclos
O projeto conceitual lida de forma consciente com alguns ciclos semânticos necessários à cadeia produtiva:
* Existe um ciclo onde um Gerente Agrícola (que também é um Funcionário) contrata um Funcionário. Este ciclo é vitalício no negócio, cabendo à aplicação garantir que um gerente não contrate a si próprio.
* O ciclo envolvendo o Engenheiro Agrônomo, o Lote e a Safra ocorre simultaneamente através dos relacionamentos de Avaliação do solo e Planejamento de plantio. Ele não representa redundância, pois o engenheiro pode planejar uma safra baseando-se em avaliações históricas feitas por outros colegas.
* O mesmo ocorre no ciclo de Estipulação de Uso e Planejamento, onde o planejamento estratégico de uma cultura e a alocação prática de defensivos agrícolas/água são operações independentes, porém conectadas à mesma Safra.

### Estrutura do Projeto

GreenCheck/
│
├── docker-compose.yml       # Orquestração do contêiner PostgreSQL local
├── README.md                # Documentação e referências do projeto
│
├── sql/                     # Artefatos de Banco de Dados (SGBD)
│   ├── esquema.sql          # DDL: Criação das tabelas (com tipagem otimizada)
│   ├── dados.sql            # DML: População inicial (respeitando a Ordem Topológica)
│   └── consultas.sql        # DQL: Consultas analíticas e Divisão Relacional
│
└── app/                     # Aplicação Web (Frontend e Backend)
    ├── requirements.txt     # Dependências do ambiente Python (Streamlit e Psycopg3)
    ├── database.py          # Gerenciamento de recursos e cache da conexão (Singleton)
    ├── queries.py           # Repositório de SQL parametrizado (Proteção contra SQL Injection)
    ├── backend.py           # Lógica de negócio e controle de transações explícitas (ACID)
    └── app.py               # Interface de usuário construída em Streamlit 

##  Requisitos de Infraestrutura e Dependências

Para a perfeita reprodução do ambiente deste projeto, certifique-se de possuir as seguintes ferramentas instaladas:

* **Engine de Conteinerização:** `Docker` e plugin `Docker Compose` (versão 2.x ou superior).
* **Interpretador Python:** `Python 3.12` (ou superior).
* **Cliente SQL / SGBD (Opcional):** `DBeaver` ou `pgAdmin 4` para inspeção e manipulação visual do banco.

---

##  Como Executar o Projeto Localmente

**1. Provisionamento do Banco de Dados (Docker)**
Na raiz do projeto, execute o comando abaixo para levantar o contêiner do PostgreSQL em segundo plano:
```bash
docker compose up -d
```
---

##  Configuração do Ambiente Virtual Python
Ainda na raiz do projeto, isole as dependências criando e ativando um ambiente virtual (venv):
```bash

python3 -m venv venv
```
# Ativação nativa (Linux/macOS):
```bash

source venv/bin/activate
```

# Ativação via PowerShell (Windows):
```bash

.\venv\Scripts\Activate.ps1
```
## Instalação das Bibliotecas
Com o venv ativado, instale os pacotes requeridos:
```bash
pip install --upgrade pip
pip install -r app/requirements.txt
```

## Inicialização da Aplicação
Rode o framework Streamlit para subir o servidor local e abrir a interface no navegador:
```bash
streamlit run app/app.py
```
