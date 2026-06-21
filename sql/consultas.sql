-- =============================================================================
-- consultas.sql - Consultas analíticas do GreenCheck
-- =============================================================================

-- 5 consultas: 
--          Vendas de produtos agrícolas não-transgênicos em um mês
--          Estoque e vendas de um produto agrícola
--          Lote(s) com o maior número de avaliações
--          Engenheiros que avaliaram TODOS os lotes
--          Gerentes com transações completas

-- ------------------------------------------------------
-- Histórico de safras de um trabalhador rural
-- ------------------------------------------------------

-- No contexto do projeto, um produto agrícola é chamado de não-transgênico se sua semente
-- não possuir nenhuma tecnologia transgênica.
-- Objetivo: Listar o nome e a quantidade vendida em um dado mês (de um ano) de todos os produtos agrícolas não-transgênicos da base. Se um produto agrícola
-- não-transgênico não foi vendido em um mês, ele deve aparecer no resultado da consulta com quantidade vendida igual a zero. O resultado deve estar
-- em ordem descrescente de quantidade vendida.
-- Parâmetro: mês e ano em que se deseja consultar as vendas. No caso, foi adotado mês de Fevereiro de 2026.
-- Complexidade: Média (LEFT JOIN, Agregação, subsconsulta aninhada não-correlacional)
    
    SELECT pa.nome AS Nome, COALESCE(vendas_fevereiro.quantidade_total_vendida, 0) AS "Quantidade Vendida (kg)"
    FROM Produto_Agricola pa
    LEFT JOIN (
        SELECT vdp.produto_agricola, SUM(vdp.quantidade_vendida) AS quantidade_total_vendida
        FROM Venda_De_Produto vdp
        JOIN Venda v ON vdp.nota_fiscal = v.nota_fiscal
        WHERE (v.data_hora >= '2026-02-01 00:00:00') AND (v.data_hora < '2026-03-01 00:00:00')
        GROUP BY vdp.produto_agricola
    ) vendas_fevereiro
    ON pa.nome = vendas_fevereiro.produto_agricola
    WHERE pa.nome NOT IN (
        SELECT pa1.nome
        FROM Produto_Agricola pa1
        JOIN Tecnologia_Transgenica tt ON tt.semente = pa1.semente
    )
    ORDER BY "Quantidade Vendida (kg)" DESC;



    
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