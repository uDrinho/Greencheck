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
    
    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Lote PRIMARY KEY (latitude, longitude),

    -- Verificação de consistência dos atributos
    -- As verificações de latitude e longitude feitas aqui não precisam ser
    -- repetidas nas tabelas "Safra", "Lote", "Avaliação" e "TeorDeNutrientes", uma vez que
    -- elas obtém estes valores direta ou indiretamente (via chaves estrangeiras) da tabela "Lote".
    CONSTRAINT CK_Lote_latitude CHECK (latitude BETWEEN -90 AND 90), -- Latitude varia de -90° até 90°
    CONSTRAINT CK_Lote_longitude CHECK (longitude BETWEEN -180 AND 180), -- Longitude varia de -90° até 90°
    CONSTRAINT CK_Lote_comprimento CHECK (comprimento >= 0),
    CONSTRAINT CK_Lote_largura CHECK (largura >= 0) 
);

-- Tabela Insumo
-- Entidade genérica forte. 
-- Garantindo que o estoque nunca seja nulo para não quebrar a lógica de triggers 
-- ou de controle manual que o Gerente Agrícola fará depois.
CREATE TABLE Insumo (
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50),
    quantidade_em_estoque DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Insumo PRIMARY KEY (nome),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Insumo_quantidadeEmEstoque CHECK (quantidade_em_estoque >= 0)
);

-- Tabela EmpresaExterna (Genérica)
-- CNPJ mapeado como CHAR(14) para não truncar zeros à esquerda. Telefone como VARCHAR 
-- para suportar formatação, caso necessário na aplicação.
CREATE TABLE Empresa_Externa (
    cnpj CHAR(14) NOT NULL,
    nome VARCHAR(60) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    endereco VARCHAR(255) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Empresa_Externa PRIMARY KEY (cnpj)
);


-- ==============================================================================
-- Heranças nível 1 e Funcionário
-- ==============================================================================

-- Especializações de Insumo
-- A chave primária é, ao mesmo tempo, chave estrangeira.
-- A regra de exclusividade (disjunção da Nota N7) será tratada no backend

CREATE TABLE Agua (
    insumo VARCHAR(100) NOT NULL,
    ph DECIMAL(4, 2) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Agua PRIMARY KEY (insumo),
    CONSTRAINT FK_Agua_insumo FOREIGN KEY (insumo) REFERENCES Insumo(nome) ON DELETE CASCADE,

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Agua_ph CHECK (ph BETWEEN 0 AND 14) -- Escala de PH varia de 0 a 14    
);

CREATE TABLE Semente (
    insumo VARCHAR(100) NOT NULL,
    nome_cientifico VARCHAR(100) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Semente PRIMARY KEY (insumo),
    CONSTRAINT FK_Semente_insumo FOREIGN KEY (insumo) REFERENCES Insumo(nome) ON DELETE CASCADE
);

CREATE TABLE Maquinario (
    insumo VARCHAR(100) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Maquinario PRIMARY KEY (insumo),
    CONSTRAINT FK_Maquinario_insumo FOREIGN KEY (insumo) REFERENCES Insumo(nome) ON DELETE CASCADE
);


-- Especializações de Empresa_Externa

CREATE TABLE Comprador (
    cnpj CHAR(14) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Comprador PRIMARY KEY (cnpj),
    CONSTRAINT FK_Comprador_cnpj FOREIGN KEY (cnpj) REFERENCES Empresa_Externa(cnpj) ON DELETE CASCADE
);

CREATE TABLE Fornecedor (
    cnpj CHAR(14) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Fornecedor PRIMARY KEY (cnpj),
    CONSTRAINT FK_Fornecedor_cnpj FOREIGN KEY (cnpj) REFERENCES Empresa_Externa(cnpj) ON DELETE CASCADE
);

CREATE TABLE TecnicoDeManutencao (
    cnpj CHAR(14) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_TecnicoDeManutencao PRIMARY KEY (cnpj),
    CONSTRAINT FK_TecnicoDeManutencao_cnpj FOREIGN KEY (cnpj) REFERENCES Empresa_Externa(cnpj) ON DELETE CASCADE
);


-- Produto Agrícola
-- Semente recebe NOT NULL devido à participação total.

CREATE TABLE Produto_Agricola (
    nome VARCHAR(100) NOT NULL,
    quantidade_em_estoque INT NOT NULL DEFAULT 0,
    semente VARCHAR(100) NOT NULL,

    -- Chaves primárias, secundárias e estrangeiras
    CONSTRAINT PK_Produto_Agricola PRIMARY KEY (nome),
    CONSTRAINT FK_Produto_Agricola_semente FOREIGN KEY (semente) REFERENCES Semente(insumo),
    CONSTRAINT UNIQUE_Produto_Agricola_semente UNIQUE (semente)
);


-- Nota N5:Como gerente ainda não foi criado, não será colocada 
-- a restrição de chave estrangeira em contradado_por ainda;
-- será feito um ALTER TABLE depois de GerenteAgrícola ser criado.

CREATE TABLE Funcionario (
    cpf CHAR(11) NOT NULL,
    salario DECIMAL(10, 2) NOT NULL,
    nome VARCHAR(60) NOT NULL,
    cargo VARCHAR(30),
    
    contratado_por CHAR(11), 
    data_contratacao TIMESTAMP,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Funcionario PRIMARY KEY (cpf),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Funcionario_salario CHECK (salario >= 0)
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
    cpf CHAR(11) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Trabalhador_Rural PRIMARY KEY (cpf),
    CONSTRAINT FK_Trabalhador_Rural_cpf FOREIGN KEY (cpf) REFERENCES Funcionario(cpf) ON DELETE CASCADE
);

CREATE TABLE Engenheiro_Agronomo (
    cpf CHAR(11) NOT NULL,

    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Engenheiro_Agronomo PRIMARY KEY (cpf),
    CONSTRAINT FK_Engenheiro_Agronomo_cpf FOREIGN KEY (cpf) REFERENCES Funcionario(cpf) ON DELETE CASCADE
);

CREATE TABLE Gerente_Agricola (
    cpf CHAR(11) NOT NULL,

    -- Chaves primárias e estrangeiras 
    CONSTRAINT PK_Gerente_Agricola PRIMARY KEY (cpf),
    CONSTRAINT FK_Gerente_Agricola_cpf FOREIGN KEY (cpf) REFERENCES Funcionario(cpf) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- Resolução da Nota N5
-- ---------------------------------------------------------
-- Agora que a tabela Gerente_Agricola finalmente existe no banco, 
-- podemos resolver o atributo 'contratado_por'.
-- ********A aplicação  ainda terá que verificar se o gerente não está 
-- contratando a si mesmo, já que o SQL relacional não impede isso nativamente.

ALTER TABLE Funcionario ADD CONSTRAINT FK_Funcionario_contratadoPor FOREIGN KEY (contratado_por) REFERENCES Gerente_Agricola(cpf);



-- ==============================================================================
-- Safra 
-- Justificativa J14: Substituição da PK semântica por um ID artificial (SERIAL).
-- Justificativa J5: produto_agricola e quantidade_produzida recebem NOT NULL.
-- Justificativa J6: Os campos de planejamento (planejador, quantidade_esperada, etc) 
-- podem ser NULOS, pois nem toda safra é planejada.
CREATE TABLE Safra (
    id SERIAL NOT NULL,
    
    -- Chaves estrangeiras e identificadores naturais (Não podem ser nulos)
    latitude DECIMAL NOT NULL,
    longitude DECIMAL NOT NULL,
    data_de_plantio DATE NOT NULL,

    -- Atributo da agregação "Safra"
    data_de_colheita DATE,
    
    -- Dados do relacionamento "Planeja" (Podem ser nulos)
    planejador CHAR(11),
    data_hora_planejamento TIMESTAMP,
    data_de_colheita_esperada DATE,
    quantidade_produzida_esperada INT,
    
    -- Dados do relacionamento "Produz"
    produto_agricola VARCHAR(100) NOT NULL,
    quantidade_produzida INT NOT NULL,

    -- Chaves primárias, secundárias e estrangeiras 
    CONSTRAINT PK_Safra PRIMARY KEY (id),
    CONSTRAINT FK_Safra_latitudeLongitude FOREIGN KEY (latitude, longitude) REFERENCES Lote(latitude, longitude),
    CONSTRAINT FK_Safra_planejador FOREIGN KEY (planejador) REFERENCES Engenheiro_Agronomo(cpf),
    CONSTRAINT FK_Safra_produtoAgricola FOREIGN KEY (produto_agricola) REFERENCES Produto_Agricola(nome),
    CONSTRAINT UNIQUE_Safra_latitudeLongitudeDataDePlantio UNIQUE (latitude, longitude, data_de_plantio),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Safra_quantidadeProduzidaEsperada CHECK (quantidade_produzida_esperada >= 0),
    CONSTRAINT CK_Safra_quantidadeProduzida CHECK (quantidade_produzida >= 0),
    CONSTRAINT CK_Safra_dataDeColheitaDataDePlantio CHECK (data_de_colheita >= data_de_plantio),
    CONSTRAINT CK_Safra_dataDeColheitaEsperadaDataDePlantio CHECK (data_de_colheita_esperada >= data_de_plantio)
);


-- Tecnologia Transgênica
-- Mapeamento de atributo multivalorado da entidade Semente (J16).
-- PK é a combinação da semente com a tecnologia.
CREATE TABLE Tecnologia_Transgenica (
    semente VARCHAR(100) NOT NULL,
    tecnologia VARCHAR(100) NOT NULL,
    
    -- Chaves primárias e estrangeiras 
    CONSTRAINT PK_Tecnologia_Transgenica PRIMARY KEY (semente, tecnologia),
    CONSTRAINT FK_Tecnologia_Transgenica_semente FOREIGN KEY (semente) REFERENCES Semente(insumo) ON DELETE CASCADE
);


-- Avaliação de Lote
-- Agregação N:N entre Engenheiro e Lote (J9).
-- A PK compõe a identificação do lote, quem avaliou e exatamente QUANDO (data_hora).
CREATE TABLE Avaliacao (
    latitude DECIMAL NOT NULL,
    longitude DECIMAL NOT NULL,
    avaliador CHAR(11) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    
    umidade_do_solo DECIMAL(5, 2),
    ph_do_solo DECIMAL(4, 2),
    permeabilidade DECIMAL(5, 2),
    
    -- Chaves primárias e estrangeiras 
    CONSTRAINT PK_Avaliacao PRIMARY KEY (latitude, longitude, avaliador, data_hora),
    CONSTRAINT FK_Avaliacao_latitudeLongitude FOREIGN KEY (latitude, longitude) REFERENCES Lote(latitude, longitude),
    CONSTRAINT FK_Avaliacao_avaliador FOREIGN KEY (avaliador) REFERENCES Engenheiro_Agronomo(cpf),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Avaliacao_umidadeDoSolo CHECK (umidade_do_solo >= 0),
    CONSTRAINT CK_Avaliacao_phDoSolo CHECK (ph_do_solo BETWEEN 0 AND 14), -- Escala de PH varia de 0 a 14
    CONSTRAINT CK_Avaliacao_permeabilidade CHECK (permeabilidade >= 0)
);

-- ==============================================================================
-- ASSOCIAÇÕES (N:N)
-- ==============================================================================

-- Trabalha (Associação N:N entre Trabalhador Rural e Safra)
-- A PK é composta pelo ID sintético da Safra e o CPF do Trabalhador.
CREATE TABLE Trabalha (
    trabalhador_rural CHAR(11) NOT NULL,
    safra INT NOT NULL,
    
    -- Chaves primárias e estrangeiras 
    CONSTRAINT PK_Trabalha PRIMARY KEY (trabalhador_rural, safra),
    CONSTRAINT FK_Trabalha_trabalhadorRural FOREIGN KEY (trabalhador_rural) REFERENCES Trabalhador_Rural(cpf),
    CONSTRAINT FK_Trabalha_safra FOREIGN KEY (safra) REFERENCES Safra(id)
);


-- Uso (Agregação de uso de insumos na safra - J10)
-- A PK é composta pelo ID da Safra, CPF do Engenheiro e a DataHora.
CREATE TABLE Uso (
    safra INT NOT NULL,
    estipulador CHAR(11) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    
    -- Chaves primárias e estrangeiras 
    CONSTRAINT PK_Uso PRIMARY KEY (safra, estipulador, data_hora),
    CONSTRAINT FK_Uso_safra FOREIGN KEY (safra) REFERENCES Safra(id),
    CONSTRAINT FK_Uso_estipulador FOREIGN KEY (estipulador) REFERENCES Engenheiro_Agronomo(cpf)
);

-- Teor de Nutrientes
-- Mapeamento de atributo multivalorado da entidade Avaliação (J15).
CREATE TABLE Teor_De_Nutrientes (
    latitude DECIMAL NOT NULL,
    longitude DECIMAL NOT NULL,
    avaliador CHAR(11) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    nutriente VARCHAR(50) NOT NULL,
    teor VARCHAR(50) NOT NULL, 
    
    -- Chaves primárias e estrangeiras 
    CONSTRAINT PK_Teor_De_Nutrientes PRIMARY KEY (latitude, longitude, avaliador, data_hora, nutriente),
    CONSTRAINT FK_Teor_De_Nutrientes_latitudeLongitudeAvaliadorDataHora FOREIGN KEY (latitude, longitude, avaliador, data_hora) 
        REFERENCES Avaliacao(latitude, longitude, avaliador, data_hora) ON DELETE CASCADE
);

-- ==============================================================================
-- Agregações Comerciais / Financeiras
-- ==============================================================================

-- Problema de unicidade: se Venda.NF != Compra.NF != Manutencao.NF.
-- salvando nota fiscal como string, podemos tratar como V-001, C-001, M-001    *** ATENCAO NA APLICAÇÂO
-- para garantir unicidade sem criar uma tabela de Notas Fiscais separada.

CREATE TABLE Venda (
    nota_fiscal VARCHAR(50) NOT NULL,
    gerente_agricola CHAR(11) NOT NULL,
    comprador CHAR(14) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    preco_total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    
    -- Chaves primárias, secundárias e estrangeiras 
    CONSTRAINT PK_Venda PRIMARY KEY (nota_fiscal),
    CONSTRAINT FK_Venda_gerenteAgricola FOREIGN KEY (gerente_agricola) REFERENCES Gerente_Agricola(cpf),
    CONSTRAINT FK_Venda_comprador FOREIGN KEY (comprador) REFERENCES Comprador(cnpj),
    CONSTRAINT UNIQUE_Venda_gerenteAgricolaCompradorDataHora UNIQUE (gerente_agricola, comprador, data_hora),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Venda_precoTotal CHECK (preco_total >= 0)
);

CREATE TABLE Compra (
    nota_fiscal VARCHAR(50) NOT NULL,
    gerente_agricola CHAR(11) NOT NULL,
    fornecedor CHAR(14) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    preco_total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    
    -- Chaves primárias, secundárias e estrangeiras 
    CONSTRAINT PK_Compra PRIMARY KEY (nota_fiscal),
    CONSTRAINT FK_Compra_gerenteAgricola FOREIGN KEY (gerente_agricola) REFERENCES Gerente_Agricola(cpf),
    CONSTRAINT FK_Compra_fornecedor FOREIGN KEY (fornecedor) REFERENCES Fornecedor(cnpj),
    CONSTRAINT UNIQUE_Compra_gerenteAgricolaFornecedorDataHora UNIQUE (gerente_agricola, fornecedor, data_hora),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Compra_precoTotal CHECK (preco_total >= 0)
);

CREATE TABLE Manutencao (
    nota_fiscal VARCHAR(50) NOT NULL,
    gerente_agricola CHAR(11) NOT NULL,
    tecnico_de_manutencao CHAR(14) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    preco_total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    
    -- Chaves primárias, secundárias e estrangeiras 
    CONSTRAINT PK_Manutencao PRIMARY KEY (nota_fiscal),
    CONSTRAINT FK_Manutencao_gerenteAgricola FOREIGN KEY (gerente_agricola) REFERENCES Gerente_Agricola(cpf),
    CONSTRAINT FK_Manutencao_tecnicoDeManutencao FOREIGN KEY (tecnico_de_manutencao) REFERENCES TecnicoDeManutencao(cnpj),
    CONSTRAINT UNIQUE_Manutencao_gerenteAgricolaTecnicoDeManutencaoDataHora UNIQUE (gerente_agricola, tecnico_de_manutencao, data_hora),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Manutencao_precoTotal CHECK (preco_total >= 0)
);

-- ==============================================================================
-- Detalhes das Agregações (Itens de Uso, Compra, Venda e Manutenção)
-- ==============================================================================

-- Insumo Estipulado (Detalhe da agregação Uso - J13)
-- FK tripla apontando para a agregação 'Uso'.
CREATE TABLE Insumo_Estipulado (
    safra INT NOT NULL,
    estipulador CHAR(11) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    insumo VARCHAR(100) NOT NULL,
    quantidade DECIMAL(10, 2) NOT NULL,
    
    -- Chaves primárias e estrangeiras 
    CONSTRAINT PK_Insumo_Estipulado PRIMARY KEY (safra, estipulador, data_hora, insumo),
    CONSTRAINT FK_Insumo_Estipulado_safraEstipuladorDataHora FOREIGN KEY (safra, estipulador, data_hora) 
        REFERENCES Uso(safra, estipulador, data_hora) ON DELETE CASCADE,
    CONSTRAINT FK_Insumo_Estipulado_insumo FOREIGN KEY (insumo) REFERENCES Insumo(nome),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Insumo_Estipulado_quantidade CHECK (quantidade >= 0)
);

-- Venda De Produto (Detalhe da Venda - J13)
CREATE TABLE Venda_De_Produto (
    nota_fiscal VARCHAR(50) NOT NULL,
    produto_agricola VARCHAR(100) NOT NULL,
    quantidade_vendida INT NOT NULL,
    preco DECIMAL(12, 2) NOT NULL,
    
    -- Chaves primárias e estrangeiras 
    CONSTRAINT PK_Venda_De_Produto PRIMARY KEY (nota_fiscal, produto_agricola),
    CONSTRAINT FK_Venda_De_Produto_notaFiscal FOREIGN KEY (nota_fiscal) REFERENCES Venda(nota_fiscal) ON DELETE CASCADE,
    CONSTRAINT FK_Venda_De_Produto_produtoAgricola FOREIGN KEY (produto_agricola) REFERENCES Produto_Agricola(nome),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Venda_De_Produto_preco CHECK (preco >= 0),
    CONSTRAINT CK_Venda_De_Produto_quantidadeVendida CHECK (quantidade_vendida >= 0)    
);

-- Compra De Insumo (Detalhe da Compra - J13)
CREATE TABLE Compra_De_Insumo (
    nota_fiscal VARCHAR(50) NOT NULL,
    insumo VARCHAR(100) NOT NULL,
    quantidade_comprada DECIMAL(10, 2) NOT NULL,
    preco DECIMAL(12, 2) NOT NULL,
    
    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Compra_De_Insumo PRIMARY KEY (nota_fiscal, insumo),
    CONSTRAINT FK_Compra_De_Insumo_notaFiscal FOREIGN KEY (nota_fiscal) REFERENCES Compra(nota_fiscal) ON DELETE CASCADE,
    CONSTRAINT FK_Compra_De_Insumo_insumo FOREIGN KEY (insumo) REFERENCES Insumo(nome),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Compra_De_Insumo_preco CHECK (preco >= 0),
    CONSTRAINT CK_Compra_De_Insumo_quantidadeComprada CHECK (quantidade_comprada >= 0)
);

-- Maquinário Manutenção (Detalhe da Manutenção - J13)
CREATE TABLE Maquinario_Manutencao (
    nota_fiscal VARCHAR(50) NOT NULL,
    maquinario VARCHAR(100) NOT NULL,
    data_agendada TIMESTAMP NOT NULL,
    preco DECIMAL(12, 2) NOT NULL,
    
    -- Chaves primárias e estrangeiras
    CONSTRAINT PK_Maquinario_Manutencao PRIMARY KEY (nota_fiscal, maquinario),
    CONSTRAINT FK_Maquinario_Manutencao_notaFiscal FOREIGN KEY (nota_fiscal) REFERENCES Manutencao(nota_fiscal) ON DELETE CASCADE,
    CONSTRAINT FK_Maquinario_Manutencao_maquinario FOREIGN KEY (maquinario) REFERENCES Maquinario(insumo),

    -- Verificação de consistência dos atributos
    CONSTRAINT CK_Maquinario_Manutencao_preco CHECK (preco >= 0)
);