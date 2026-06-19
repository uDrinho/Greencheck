-- =============================================================================
-- consultas.sql - Consultas analíticas do GreenCheck
-- =============================================================================

-- 5 consultas: 
--          Histórico de safras de um trabalhador rural
--          Estoque e vendas de um produto agrícola
--          Lote(s) com o maior número de avaliações
--          Engenheiros que avaliaram TODOS os lotes
--          Gerentes com transações completas

-- ------------------------------------------------------
-- Histórico de safras de um trabalhador rural
-- ------------------------------------------------------
-- Objetivo: Listar todas as safras em que o trabalhador participou.
-- Parâmetro: CPF do trabalhador rural.
-- Complexidade: Média (junções múltiplas).


SELECT s.id               AS safra_id,
       s.latitude,
       s.longitude,
       s.data_de_plantio,
       s.data_de_colheita,
       pa.nome            AS produto,
       s.quantidade_produzida
FROM Trabalhador_Rural tr
JOIN Trabalha t       ON tr.cpf = t.trabalhador_rural
JOIN Safra s          ON t.safra = s.id
JOIN Produto_Agricola pa ON s.produto_agricola = pa.nome
WHERE tr.cpf = %s
ORDER BY s.data_de_plantio DESC;


-- ------------------------------------------------------
-- Estoque e vendas de um produto agrícola
-- ------------------------------------------------------
-- Objetivo: Mostrar estoque atual, total vendido e receita de um produto.
-- Parâmetro: nome do produto agrícola.
-- Complexidade: Média (LEFT JOIN, agregação, COALESCE).

SELECT pa.nome,
       pa.quantidade_em_estoque,
       COALESCE(SUM(vp.quantidade_vendida), 0) AS total_vendido,
       COALESCE(SUM(vp.quantidade_vendida * vp.preco), 0) AS receita_total
FROM Produto_Agricola pa
LEFT JOIN Venda_De_Produto vp ON pa.nome = vp.produto_agricola
WHERE pa.nome = %s
GROUP BY pa.nome, pa.quantidade_em_estoque;


-- ------------------------------------------------------
-- Lote(s) com o maior número de avaliações
-- ------------------------------------------------------
-- Objetivo: Identificar o(s) lote(s) mais monitorado(s).
-- Sem parâmetros; usa HAVING + subconsulta correlacionada.
-- Complexidade: Alta (agrupamento, subconsulta, ALL).
-- Se a tabela Avaliacao estiver vazia, não retorna nenhuma linha.

SELECT l.latitude,
       l.longitude,
       COUNT(*) AS total_avaliacoes
FROM Lote l
JOIN Avaliacao a ON l.latitude = a.latitude AND l.longitude = a.longitude
GROUP BY l.latitude, l.longitude
HAVING COUNT(*) >= ALL (
    SELECT COUNT(*)
    FROM Avaliacao
    GROUP BY latitude, longitude
)
AND (SELECT COUNT(*) FROM Avaliacao) > 0;


-- ------------------------------------------------------
-- Engenheiros que avaliaram TODOS os lotes
-- ------------------------------------------------------
-- Objetivo: Divisão relacional – engenheiros com cobertura total.
-- Complexidade: Alta (NOT EXISTS aninhado = divisão relacional).

SELECT e.cpf, f.nome
FROM Engenheiro_Agronomo e
JOIN Funcionario f ON e.cpf = f.cpf
WHERE NOT EXISTS (
    SELECT l.latitude, l.longitude
    FROM Lote l
    WHERE NOT EXISTS (
        SELECT 1
        FROM Avaliacao a
        WHERE a.latitude  = l.latitude
          AND a.longitude = l.longitude
          AND a.avaliador = e.cpf
    )
);


-- ------------------------------------------------------
-- Gerentes com transações completas
-- ------------------------------------------------------
-- Objetivo: Gerentes que fizeram pelo menos uma venda, uma compra e uma manutenção.
-- Técnica: NOT EXISTS ( conjunto_requerido EXCEPT conjunto_do_gerente )
-- Complexidade: Alta (divisão relacional com EXCEPT).

SELECT g.cpf, f.nome
FROM Gerente_Agricola g
JOIN Funcionario f ON g.cpf = f.cpf
WHERE NOT EXISTS (
    SELECT t.tipo FROM (VALUES ('Venda'), ('Compra'), ('Manutencao')) AS t(tipo)
    EXCEPT
    (
        SELECT 'Venda' FROM Venda v WHERE v.gerente_agricola = g.cpf
        UNION ALL
        SELECT 'Compra' FROM Compra c WHERE c.gerente_agricola = g.cpf
        UNION ALL
        SELECT 'Manutencao' FROM Manutencao m WHERE m.gerente_agricola = g.cpf
    )
);