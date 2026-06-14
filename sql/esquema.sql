-- ==============================================================================
-- Entidades sem chaves estrangeiras
-- ==============================================================================

-- Tabela Lote
-- Identificadora base para as terras. Usando DECIMAL para as coordenadas geográficas.
CREATE TABLE Lote (
    latitude DECIMAL NOT NULL,
    longitude DECIMAL NOT NULL,
    comprimento DECIMAL NOT NULL,
    largura DECIMAL NOT NULL,
    
    PRIMARY KEY (latitude, longitude)
);

-- Tabela Insumo
-- Entidade genérica forte. 
-- Garantindo que o estoque nunca seja nulo para não quebrar a lógica de triggers 
-- ou de controle manual que o Gerente Agrícola fará depois.
CREATE TABLE Insumo (
    nome VARCHAR(100) PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL,
    quantidade_em_estoque DECIMAL(10, 2) NOT NULL DEFAULT 0.00
);

-- Tabela EmpresaExterna (Genérica)
-- CNPJ mapeado como CHAR(14) para não truncar zeros à esquerda. Telefone como VARCHAR 
-- para suportar formatação, caso necessário na aplicação.
CREATE TABLE Empresa_Externa (
    cnpj CHAR(14) PRIMARY KEY,
    nome VARCHAR(60) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    endereco VARCHAR(255) NOT NULL
);


-- ==============================================================================
-- Heranças nível 1 e Funcionário
-- ==============================================================================

-- Especializações de Insumo
-- A chave primária é, ao mesmo tempo, chave estrangeira.
-- A regra de exclusividade (disjunção da Nota N7) será tratada no backend

CREATE TABLE Agua (
    insumo VARCHAR(100) PRIMARY KEY,
    ph DECIMAL(4, 2) NOT NULL,
    FOREIGN KEY (insumo) REFERENCES Insumo(nome) ON DELETE CASCADE
);

CREATE TABLE Semente (
    insumo VARCHAR(100) PRIMARY KEY,
    nome_cientifico VARCHAR(100) NOT NULL,
    FOREIGN KEY (insumo) REFERENCES Insumo(nome) ON DELETE CASCADE
);

CREATE TABLE Maquinario (
    insumo VARCHAR(100) PRIMARY KEY,
    FOREIGN KEY (insumo) REFERENCES Insumo(nome) ON DELETE CASCADE
);


-- Especializações de Empresa_Externa

CREATE TABLE Comprador (
    cnpj CHAR(14) PRIMARY KEY,
    FOREIGN KEY (cnpj) REFERENCES Empresa_Externa(cnpj) ON DELETE CASCADE
);

CREATE TABLE Fornecedor (
    cnpj CHAR(14) PRIMARY KEY,
    FOREIGN KEY (cnpj) REFERENCES Empresa_Externa(cnpj) ON DELETE CASCADE
);

CREATE TABLE TecnicoDeManutencao (
    cnpj CHAR(14) PRIMARY KEY,
    FOREIGN KEY (cnpj) REFERENCES Empresa_Externa(cnpj) ON DELETE CASCADE
);


-- Produto Agrícola
-- Semente recebe NOT NULL devido à participação total.

CREATE TABLE Produto_Agricola (
    nome VARCHAR(100) PRIMARY KEY,
    quantidade_em_estoque INT NOT NULL DEFAULT 0,
    semente VARCHAR(100) NOT NULL,
    FOREIGN KEY (semente) REFERENCES Semente(insumo)
);



-- Nota N5:Como gerente ainda não foi criado, não será colocada 
-- a restrição de chave estrangeira em contradado_por ainda;
-- será feito um ALTER TABLE depois de GerenteAgrícola ser criado.

CREATE TABLE Funcionario (
    cpf CHAR(11) PRIMARY KEY,
    salario DECIMAL(10, 2) NOT NULL,
    nome VARCHAR(60) NOT NULL,
    cargo VARCHAR(30) NOT NULL,
    
    contratado_por CHAR(11), 
    data_contratacao TIMESTAMP
);


-- ==============================================================================
--  Especializações de RH
-- ==============================================================================

-- ---------------------------------------------------------
-- Especializações de Funcionário
-- A chave primária (CPF) também atua como chave estrangeira, garantindo a herança.
-- O ON DELETE CASCADE garante que, se um funcionário for deletado da tabela genérica,
-- o registro dele no cargo específico também some 
-- ---------------------------------------------------------

CREATE TABLE Trabalhador_Rural (
    cpf CHAR(11) PRIMARY KEY,
    FOREIGN KEY (cpf) REFERENCES Funcionario(cpf) ON DELETE CASCADE
);

CREATE TABLE Engenheiro_Agronomo (
    cpf CHAR(11) PRIMARY KEY,
    FOREIGN KEY (cpf) REFERENCES Funcionario(cpf) ON DELETE CASCADE
);

CREATE TABLE Gerente_Agricola (
    cpf CHAR(11) PRIMARY KEY,
    FOREIGN KEY (cpf) REFERENCES Funcionario(cpf) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- Resolução da Nota N5
-- ---------------------------------------------------------
-- Agora que a tabela Gerente_Agricola finalmente existe no banco, 
-- podemos amarrar aquela coluna 'contratado_por' que deixamos solta na Fase 2.
-- ********A aplicação  ainda terá que verificar se o gerente não está 
-- contratando a si mesmo, o SQL relacional não impede isso nativamente.

ALTER TABLE Funcionario
ADD CONSTRAINT fk_funcionario_contratado_por
FOREIGN KEY (contratado_por) REFERENCES Gerente_Agricola(cpf);



-- ==============================================================================
-- Safra 
-- Justificativa J14: Substituição da PK semântica por um ID artificial (SERIAL).
-- Justificativa J5: produto_agricola e quantidade_produzida recebem NOT NULL.
-- Justificativa J6: Os campos de planejamento (planejador, quantidade_esperada, etc) 
-- podem ser NULOS, pois nem toda safra é planejada.
CREATE TABLE Safra (

    id SERIAL PRIMARY KEY,
    
    -- Chaves estrangeiras e identificadores naturais (Não podem ser nulos)
    latitude DECIMAL NOT NULL,
    longitude DECIMAL NOT NULL,
    data_de_plantio DATE NOT NULL,
    
    -- Dados do relacionamento "Planeja" (Podem ser nulos)
    planejador CHAR(11),
    data_hora_planejamento TIMESTAMP,
    data_de_colheita_esperada DATE,
    quantidade_produzida_esperada INT,
    
    -- Dados do relacionamento "Produz" e "Plantada" (Participação total = NOT NULL)
    data_de_colheita DATE NOT NULL,
    produto_agricola VARCHAR(100) NOT NULL,
    quantidade_produzida INT NOT NULL,
    
    FOREIGN KEY (latitude, longitude) REFERENCES Lote(latitude, longitude),
    FOREIGN KEY (planejador) REFERENCES Engenheiro_Agronomo(cpf),
    FOREIGN KEY (produto_agricola) REFERENCES Produto_Agricola(nome)
);


-- Tecnologia Transgênica
-- Mapeamento de atributo multivalorado da entidade Semente (J16).
-- PK é a combinação da semente com a tecnologia.
CREATE TABLE Tecnologia_Transgenica (
    semente VARCHAR(100),
    tecnologia VARCHAR(100),
    
    PRIMARY KEY (semente, tecnologia),
    FOREIGN KEY (semente) REFERENCES Semente(insumo) ON DELETE CASCADE
);


-- Avaliação de Lote
-- Agregação N:N entre Engenheiro e Lote (J9).
-- A PK compõe a identificação do lote, quem avaliou e exatamente QUANDO (data_hora).
CREATE TABLE Avaliacao (
    latitude DECIMAL,
    longitude DECIMAL,
    avaliador CHAR(11),
    data_hora TIMESTAMP,
    
    umidade_do_solo DECIMAL(5, 2) NOT NULL,
    ph_do_solo DECIMAL(4, 2) NOT NULL,
    permeabilidade DECIMAL(5, 2) NOT NULL,
    
    PRIMARY KEY (latitude, longitude, avaliador, data_hora),
    FOREIGN KEY (latitude, longitude) REFERENCES Lote(latitude, longitude),
    FOREIGN KEY (avaliador) REFERENCES Engenheiro_Agronomo(cpf)
);

-- ==============================================================================
-- ASSOCIAÇÕES (N:N)
-- ==============================================================================

-- Trabalha (Associação N:N entre Trabalhador Rural e Safra)
-- A PK é composta pelo ID sintético da Safra e o CPF do Trabalhador.
CREATE TABLE Trabalha (
    trabalhador_rural CHAR(11),
    safra INT,
    
    PRIMARY KEY (trabalhador_rural, safra),
    FOREIGN KEY (trabalhador_rural) REFERENCES Trabalhador_Rural(cpf),
    FOREIGN KEY (safra) REFERENCES Safra(id)
);


-- Uso (Agregação de uso de insumos na safra - J10)
-- A PK é composta pelo ID da Safra, CPF do Engenheiro e a DataHora.
CREATE TABLE Uso (
    safra INT,
    estipulador CHAR(11),
    data_hora TIMESTAMP,
    
    PRIMARY KEY (safra, estipulador, data_hora),
    FOREIGN KEY (safra) REFERENCES Safra(id),
    FOREIGN KEY (estipulador) REFERENCES Engenheiro_Agronomo(cpf)
);

-- Teor de Nutrientes
-- Mapeamento de atributo multivalorado da entidade Avaliação (J15).
CREATE TABLE Teor_De_Nutrientes (
    latitude DECIMAL,
    longitude DECIMAL,
    avaliador CHAR(11),
    data_hora TIMESTAMP,
    nutriente VARCHAR(50),
    teor VARCHAR(50) NOT NULL, 
    
    PRIMARY KEY (latitude, longitude, avaliador, data_hora, nutriente),
    -- O ON DELETE CASCADE limpa os nutrientes automaticamente se a avaliação for apagada
    FOREIGN KEY (latitude, longitude, avaliador, data_hora) 
        REFERENCES Avaliacao(latitude, longitude, avaliador, data_hora) ON DELETE CASCADE
);

-- ==============================================================================
-- Agregações Comerciais / Financeiras
-- ==============================================================================

-- Problema de unicidade: se Venda.NF != Compra.NF != Manutencao.NF.
-- salvando nota fiscal como string, podemos tratar como V-001, C-001, M-001    *** ATENCAO NA APLICAÇÂO
-- para garantir unicidade sem criar uma tabela de Notas Fiscais separada.

CREATE TABLE Venda (
    nota_fiscal VARCHAR(50) PRIMARY KEY,
    gerente_agricola CHAR(11) NOT NULL,
    comprador CHAR(14) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    preco_total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    
    FOREIGN KEY (gerente_agricola) REFERENCES Gerente_Agricola(cpf),
    FOREIGN KEY (comprador) REFERENCES Comprador(cnpj)
);

CREATE TABLE Compra (
    nota_fiscal VARCHAR(50) PRIMARY KEY,
    gerente_agricola CHAR(11) NOT NULL,
    fornecedor CHAR(14) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    preco_total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    
    FOREIGN KEY (gerente_agricola) REFERENCES Gerente_Agricola(cpf),
    FOREIGN KEY (fornecedor) REFERENCES Fornecedor(cnpj)
);

CREATE TABLE Manutencao (
    nota_fiscal VARCHAR(50) PRIMARY KEY,
    gerente_agricola CHAR(11) NOT NULL,
    tecnico_de_manutencao CHAR(14) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    preco_total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    
    FOREIGN KEY (gerente_agricola) REFERENCES Gerente_Agricola(cpf),
    FOREIGN KEY (tecnico_de_manutencao) REFERENCES TecnicoDeManutencao(cnpj)
);

-- ==============================================================================
-- Detalhes das Agregações (Itens de Uso, Compra, Venda e Manutenção)
-- ==============================================================================

-- Insumo Estipulado (Detalhe da agregação Uso - J13)
-- FK tripla apontando para a agregação 'Uso'.
CREATE TABLE Insumo_Estipulado (
    safra INT,
    estipulador CHAR(11),
    data_hora TIMESTAMP,
    insumo VARCHAR(100),
    quantidade DECIMAL(10, 2) NOT NULL,
    
    PRIMARY KEY (safra, estipulador, data_hora, insumo),
    
    -- O ON DELETE CASCADE garante que se o "Uso" for cancelado, os itens somem junto
    FOREIGN KEY (safra, estipulador, data_hora) 
        REFERENCES Uso(safra, estipulador, data_hora) ON DELETE CASCADE,
    FOREIGN KEY (insumo) REFERENCES Insumo(nome)
);

-- Venda De Produto (Detalhe da Venda - J13)
CREATE TABLE Venda_De_Produto (
    nota_fiscal VARCHAR(50),
    produto_agricola VARCHAR(100),
    quantidade_vendida INT NOT NULL,
    preco DECIMAL(12, 2) NOT NULL,
    
    PRIMARY KEY (nota_fiscal, produto_agricola),
    FOREIGN KEY (nota_fiscal) REFERENCES Venda(nota_fiscal) ON DELETE CASCADE,
    FOREIGN KEY (produto_agricola) REFERENCES Produto_Agricola(nome)
);

-- Compra De Insumo (Detalhe da Compra - J13)
CREATE TABLE Compra_De_Insumo (
    nota_fiscal VARCHAR(50),
    insumo VARCHAR(100),
    quantidade_comprada DECIMAL(10, 2) NOT NULL,
    preco DECIMAL(12, 2) NOT NULL,
    
    PRIMARY KEY (nota_fiscal, insumo),
    FOREIGN KEY (nota_fiscal) REFERENCES Compra(nota_fiscal) ON DELETE CASCADE,
    FOREIGN KEY (insumo) REFERENCES Insumo(nome)
);

-- Maquinário Manutenção (Detalhe da Manutenção - J13)
CREATE TABLE Maquinario_Manutencao (
    nota_fiscal VARCHAR(50),
    maquinario VARCHAR(100),
    data_agendada TIMESTAMP NOT NULL,
    preco DECIMAL(12, 2) NOT NULL,
    
    PRIMARY KEY (nota_fiscal, maquinario),
    FOREIGN KEY (nota_fiscal) REFERENCES Manutencao(nota_fiscal) ON DELETE CASCADE,
    FOREIGN KEY (maquinario) REFERENCES Maquinario(insumo)
);