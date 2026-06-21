-- ==============================================================================
-- DADOS.SQL - Inserção inicial da base de dados 
-- ==============================================================================

-- A ordem de inserção dos dados segue estritamente a ordem 
-- topológica das dependências do modelo relacional para garantir 
-- a Integridade Referencial. 
--
-- Para que o SGBD não lance erros de violação de Chave Estrangeira (Foreign Key),
-- as entidades independentes são populadas primeiro. 
-- Somente após a existência dessas tuplas-pai é que as entidades dependentes, 
-- especializações e agregações (N:N) serão inseridas no banco.
-- ==============================================================================

-- ==============================================================================
-- Entidades sem chaves estrangeiras
-- ==============================================================================

-- Lote 
INSERT INTO Lote (latitude, longitude, comprimento, largura) VALUES 
(-21.98, -47.88, 1000.0, 500.0),
(-22.00, -47.90, 800.0, 600.0);

-- Insumo (Genérica - Inserindo para todos os filhos + adubo)
INSERT INTO Insumo (nome, tipo, quantidade_em_estoque) VALUES 
('Semente de Milho P30F53', 'Semente', 100.00),
('Semente de Soja M8210PRO', 'Semente', 150.00),
('Semente de Feijao Carioca Comum', 'Semente', 80.00),
('Semente de Arroz Agulhinha', 'Semente', 120.00),
('Trator John Deere 6J', 'Maquinario', 2.00),
('Colheitadeira Case IH 8250', 'Maquinario', 1.00),
('Agua de Irrigacao - Poco 1', 'Agua', 5000.00),
('Agua de Irrigacao - Rio Tietê', 'Agua', 10000.00),
('Adubo NPK 10-10-10', 'Fertilizante', 500.00);

-- Empresa Externa (Genérica)
INSERT INTO Empresa_Externa (cnpj, nome, telefone, endereco) VALUES 
('11111111111111', 'AgroTech Compradora', '16999991111', 'Rua das Lavouras, 100'),
('12121212121212', 'Celeiro do Brasil', '11999992222', 'Av Paulista, 500'),
('22222222222222', 'Sementes Fornecedora', '16888883333', 'Rodovia Washington Luis, Km 235'),
('23232323232323', 'Insumos Agricolas SP', '11888884444', 'Rua Cesar Ricomi, 456'),
('33333333333333', 'Mecanica Tratores', '16777775555', 'Av Trabalhador Sao Carlense, 400'),
('34343434343434', 'Oficina Case', '11777776666', 'Rua Dr. Delfim Moreira, 789');


-- ==============================================================================
-- Heranças nível 1 e Funcionário
-- ==============================================================================

-- Agua
INSERT INTO Agua (insumo, ph) VALUES 
('Agua de Irrigacao - Poco 1', 6.5),
('Agua de Irrigacao - Rio Tietê', 5.8);

-- Semente
INSERT INTO Semente (insumo, nome_cientifico) VALUES 
('Semente de Milho P30F53', 'Zea mays'),
('Semente de Soja M8210PRO', 'Glycine max'),
('Semente de Feijao Carioca Comum', 'Phaseolus vulgaris'),
('Semente de Arroz Agulhinha', 'Oryza sativa');

-- Maquinario
INSERT INTO Maquinario (insumo) VALUES 
('Trator John Deere 6J'),
('Colheitadeira Case IH 8250');

-- Especializações de Empresa Externa
INSERT INTO Comprador (cnpj) VALUES ('11111111111111'), ('12121212121212');
INSERT INTO Fornecedor (cnpj) VALUES ('22222222222222'), ('23232323232323');
INSERT INTO TecnicoDeManutencao (cnpj) VALUES ('33333333333333'), ('34343434343434');

-- Produto Agricola (Mínimo 2)
INSERT INTO Produto_Agricola (nome, quantidade_em_estoque, semente) VALUES 
('Milho em Grão', 5000, 'Semente de Milho P30F53'),
('Soja em Grão', 3000, 'Semente de Soja M8210PRO'),
('Feijao Carioca', 2000, 'Semente de Feijao Carioca Comum'),
('Arroz Agulhinha', 1500, 'Semente de Arroz Agulhinha');


-- ==============================================================================
-- Especializações de RH
-- ==============================================================================

-- 1. Inserimos o Gerente SEM o "contratado_por" para não dar erro
INSERT INTO Funcionario (cpf, salario, nome, cargo, contratado_por, data_contratacao) VALUES 
('15483776000', 15000.00, 'Pedro Henrique Barbosa Oliveira', 'Gerente Agrícola', NULL, '2024-01-10 08:00:00'),
('15511001000', 15000.00, 'Marcos Vinicius Cota Rodrigues', 'Gerente Agrícola', NULL, '2024-01-15 08:00:00');

-- 2. Colocamos eles na tabela específica
INSERT INTO Gerente_Agricola (cpf) VALUES ('15483776000'), ('15511001000');

-- 3. Agora inserimos o resto da equipe já apontando para o Gerente Pedro ('15483776000')
INSERT INTO Funcionario (cpf, salario, nome, cargo, contratado_por, data_contratacao) VALUES 
('15471518000', 9000.00, 'Lucas Dúckur Nunes Andreolli', 'Engenheiro Agrônomo', '15483776000', '2025-02-01 09:00:00'),
('15573731000', 9000.00, 'Caio Draco Araújo Albuquerque', 'Engenheiro Agrônomo', '15483776000', '2025-02-02 09:00:00'),
('15522383000', 3500.00, 'Kattryel Henrique Santos', 'Trabalhador Rural', '15483776000', '2025-03-01 07:00:00'),
('99999999999', 3500.00, 'José da Silva', 'Trabalhador Rural', '15483776000', '2025-03-02 07:00:00'),
('88888888888', 3500.00, 'Maria Sousa', 'Trabalhador Rural', '15483776000', '2025-02-01 10:00:00');
-- 4. Povoamos as tabelas específicas restantes
INSERT INTO Engenheiro_Agronomo (cpf) VALUES ('15471518000'), ('15573731000');
INSERT INTO Trabalhador_Rural (cpf) VALUES ('15522383000'), ('99999999999'), ('88888888888');


-- ==============================================================================
-- Safra 
-- ==============================================================================

-- Safra (sem inserir o id, que é SERIAL)
INSERT INTO Safra (latitude, longitude, data_de_plantio, planejador, data_hora_planejamento, data_de_colheita_esperada, quantidade_produzida_esperada, data_de_colheita, produto_agricola, quantidade_produzida) VALUES 
(-21.98, -47.88, '2025-10-01', '15471518000', '2025-09-20 10:00:00', '2026-03-01', 25000, '2026-03-05', 'Milho em Grão', 24500),
(-22.00, -47.90, '2025-11-15', '15573731000', '2025-11-01 14:00:00', '2026-04-10', 30000, '2026-04-12', 'Soja em Grão', 31000);

-- Tecnologia Transgênica
INSERT INTO Tecnologia_Transgenica (semente, tecnologia) VALUES 
('Semente de Milho P30F53', 'Bt YieldGard'),
('Semente de Soja M8210PRO', 'RR2 PRO');

-- Avaliação de Lote
INSERT INTO Avaliacao (latitude, longitude, avaliador, data_hora, umidade_do_solo, ph_do_solo, permeabilidade) VALUES 
(-21.98, -47.88, '15471518000', '2025-09-15 08:30:00', 0.45, 6.2, 5.50),
(-21.98, -47.88, '15573731000', '2025-10-20 09:30:00', 0.45, 6.3, 5.50),
(-22.00, -47.90, '15573731000', '2025-10-20 09:15:00', 0.50, 5.8, 4.80);


-- ==============================================================================
-- ASSOCIAÇÕES (N:N)
-- ==============================================================================

-- Trabalha (Assumindo que os IDs das safras gerados foram 1 e 2)
INSERT INTO Trabalha (trabalhador_rural, safra) VALUES 
('15522383000', 1),
('15522383000', 2),
('99999999999', 1),
('88888888888', 1),
('88888888888', 2);

-- Uso
INSERT INTO Uso (safra, estipulador, data_hora) VALUES 
(1, '15471518000', '2025-10-05 07:00:00'),
(2, '15573731000', '2025-11-20 07:30:00');

-- Teor de Nutrientes
INSERT INTO Teor_De_Nutrientes (latitude, longitude, avaliador, data_hora, nutriente, teor) VALUES 
(-21.98, -47.88, '15471518000', '2025-09-15 08:30:00', 'Nitrogênio', 'Alto'),
(-22.00, -47.90, '15573731000', '2025-10-20 09:15:00', 'Fósforo', 'Médio');


-- ==============================================================================
-- Agregações Comerciais / Financeiras
-- ==============================================================================

-- Venda (Prefixos V-)
INSERT INTO Venda (nota_fiscal, gerente_agricola, comprador, data_hora, preco_total) VALUES 
('V-1001', '15483776000', '11111111111111', '2026-03-10 14:00:00', 122500.00),
('V-1002', '15511001000', '12121212121212', '2026-04-15 10:00:00', 155000.00),
('V-9001', '15483776000', '11111111111111', '2026-02-14 10:30:00', 4000.00),
('V-9002', '15483776000', '11111111111111', '2026-01-20 16:00:00', 2400.00);


-- Compra (Prefixos C-)
INSERT INTO Compra (nota_fiscal, gerente_agricola, fornecedor, data_hora, preco_total) VALUES 
('C-2001', '15483776000', '22222222222222', '2025-08-10 09:00:00', 15000.00),
('C-2002', '15511001000', '23232323232323', '2025-09-05 11:00:00', 8000.00);

-- Manutenção (Prefixos M-)
INSERT INTO Manutencao (nota_fiscal, gerente_agricola, tecnico_de_manutencao, data_hora, preco_total) VALUES 
('M-3001', '15483776000', '33333333333333', '2026-01-15 15:00:00', 4500.00),
('M-3002', '15511001000', '34343434343434', '2026-02-20 16:00:00', 6000.00);


-- ==============================================================================
-- Detalhes das Agregações (Itens de Uso, Compra, Venda e Manutenção)
-- ==============================================================================

-- Insumo Estipulado
INSERT INTO Insumo_Estipulado (safra, estipulador, data_hora, insumo, quantidade) VALUES 
(1, '15471518000', '2025-10-05 07:00:00', 'Adubo NPK 10-10-10', 50.00),
(2, '15573731000', '2025-11-20 07:30:00', 'Agua de Irrigacao - Poco 1', 1000.00);

-- Venda De Produto
INSERT INTO Venda_De_Produto (nota_fiscal, produto_agricola, quantidade_vendida, preco) VALUES 
('V-1001', 'Milho em Grão', 24500, 5.00),
('V-1002', 'Soja em Grão', 31000, 5.00),
('V-9001', 'Feijao Carioca', 500, 8.00),
('V-9002', 'Arroz Agulhinha', 300, 8.00);

-- Compra De Insumo
INSERT INTO Compra_De_Insumo (nota_fiscal, insumo, quantidade_comprada, preco) VALUES 
('C-2001', 'Semente de Milho P30F53', 100.00, 150.00),
('C-2002', 'Adubo NPK 10-10-10', 500.00, 16.00);

-- Maquinario Manutencao
INSERT INTO Maquinario_Manutencao (nota_fiscal, maquinario, data_agendada, preco) VALUES 
('M-3001', 'Trator John Deere 6J', '2026-01-20 08:00:00', 4500.00),
('M-3002', 'Colheitadeira Case IH 8250', '2026-02-25 08:00:00', 6000.00);