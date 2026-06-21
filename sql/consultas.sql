-- =============================================================================
-- consultas.sql - Consultas analíticas do GreenCheck
-- =============================================================================

-- 5 consultas: 
--          Vendas de produtos agrícolas não-transgênicos em um mês
--          Água utilizada nas safras que produziram o produto agrícola de maior receita
--          Lote(s) com o maior número de avaliações
--          Gerentes com transações completas
--			Trabalhadores que produziram o mesmo produto agrícola que outro específico

-- ------------------------------------------------------
-- Vendas de produtos agrícolas não-transgênicos em um mês
-- ------------------------------------------------------
-- No contexto do projeto, um produto agrícola é chamado de não-transgênico se sua semente
-- não possuir nenhuma tecnologia transgênica.
-- Objetivo: Listar o nome e a quantidade vendida em um dado mês (de um ano) de todos os produtos agrícolas não-transgênicos da base. Se um produto agrícola
-- não-transgênico não foi vendido no mês em questão, ele deve aparecer no resultado da consulta com quantidade vendida igual a zero. O resultado deve estar
-- em ordem descrescente de quantidade vendida.
-- Parâmetro: mês e ano em que se deseja consultar as vendas. No caso, foi adotado o mês de Fevereiro de 2026.
    
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



-- ----------------------------------------------------------------------------
-- Água utilizada nas safras que produziram o produto agrícola de maior receita
-- ----------------------------------------------------------------------------
-- Objetivo: Mostrar a média do volume de água utilizada nas safras que produziram os produtos agrícolas que mais
-- geraram renda em vendas. Tanto o nome do produto agrícola quanto a média do volume de água devem ser mostrados no resultado.
-- Dentre os produtos de maior receita, deve-se desconsiderar os que não possuem safras associadas e aqueles em que nenhuma safra
-- associada possui utilização de água registrada.
-- Parâmetro: Nenhum

WITH produto_receita AS (
    SELECT vdp.produto_agricola, SUM(vdp.quantidade_vendida * vdp.preco) AS receita
    FROM Venda_De_Produto vdp
    GROUP BY vdp.produto_agricola
),
produtos_maior_receita AS (
    SELECT produto_receita.produto_agricola
    FROM produto_receita
    WHERE produto_receita.receita = (
        SELECT MAX(receita)
        FROM produto_receita 
    )
)

SELECT produto_agricola, AVG(volume_agua) AS "Média do volume de água por safra"
FROM (
    SELECT s.produto_agricola, SUM(ie.quantidade) AS volume_agua
    FROM produtos_maior_receita pmr
    JOIN Safra s ON pmr.produto_agricola = s.produto_agricola
    JOIN Insumo_Estipulado ie ON ie.safra = s.id
    JOIN Agua a ON a.insumo = ie.insumo
    GROUP BY s.produto_agricola, s.id
) agua_safra
GROUP BY agua_safra.produto_agricola;



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


-- --------------------------------------------------------------------------
-- Trabalhadores que produziram o mesmo produto agrícola que outro específico
-- --------------------------------------------------------------------------

-- Objetivo: Listar o cpf e o nome de todos os trabalhadores que produziram pelo menos os mesmos
-- produtos agrícolas que um trabalhador específico
-- Parâmetro: CPF do trabalhador rural específico. No exemplo, foi utilizado o CPF 15522383000
-- Complexidade: Média (Divisão Relacional utilizando subconsultas, NOT EXISTS e EXECPT)


SELECT f.cpf, f.nome
	FROM trabalhador_rural tr 
	JOIN funcionario f ON f.cpf = tr.cpf
	WHERE NOT EXISTS(
		(SELECT DISTINCT s.produto_agricola 
			FROM trabalha t 
			JOIN safra s ON t.safra = s.id
			WHERE t.trabalhador_rural  = '15522383000')
		
		EXCEPT
		
		(SELECT DISTINCT s.produto_agricola 
			FROM trabalha t 
			JOIN safra s ON t.safra = s.id
			WHERE t.trabalhador_rural = tr.cpf)
		) 
		AND tr.cpf != '15522383000';


