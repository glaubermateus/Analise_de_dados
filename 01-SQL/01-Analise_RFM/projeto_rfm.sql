-- ***** ETAPA 1: Criar e alimentar a tabela analise_rfm *****

-- Passo 1: Cria a tabela analise_rfm

CREATE TABLE IF NOT EXISTS analise_rfm (
  id INTEGER PRIMARY KEY,
  id_cliente VARCHAR(255),
  recencia INTEGER,
  frequencia INTEGER,
  valor_monetario DECIMAL(10,2)
);

-- Passo 2: Cria uma tabela temporaria que vai receber dados da tabela principal

CREATE TEMP TABLE tabela_temp AS
SELECT
  order_id AS id_ordem,
  CAST(order_purchase_timestamp AS DATE) AS data,
  (SELECT MAX(CAST(order_purchase_timestamp AS DATE)) + 1 AS data_ref FROM df),
  payment_value AS valor_monetario,
  customer_unique_id AS id_cliente
FROM df;

-- Passo 3: Inserir os dados na tabela analise_rfm

INSERT INTO analise_rfm(id, id_cliente, recencia, frequencia, valor_monetario)
SELECT
      ROW_NUMBER () OVER() as id,
      id_cliente,
      (MAX(data_ref) - MAX(data)) AS recencia,
      COUNT(id_ordem) AS frequencia,
      SUM(valor_monetario) AS valor_monetario
FROM
       tabela_temp
GROUP BY
       id_cliente
ORDER BY 
       id_cliente ASC;

-- Passo 4: Dropar a tabela temporaria

 DROP TABLE tabela_temp;
 
 -- Passo 5: Visualizando os primeiros registros da tabela analise_rfm
 
 SELECT * FROM analise_rfm ORDER BY id ASC LIMIT 20;
 
 -- Analise da coluna frequencia na tabela analise_rfm
 
 SELECT 
 CASE WHEN frequencia = 1 THEN 'Unica' ELSE 'Multipla' END AS grupos,
 COUNT(*) AS qtd,
 ROUND(COUNT(*) * 100 / (SELECT COUNT(*) AS total FROM analise_rfm),2) AS percentual
 FROM analise_rfm
 GROUP BY grupos;
 
 */
 Decisão sobre a coluna de frequência:
 
 A maioria dos clientes comprou só uma vez. Desse modo, os quartis um, dois e três recebem o valor um, não sendo coerente usar como métrica para segmentação.
 Desse modo, dividiremos a frequência em dois grupos: clientes que compraram uma só vez (f = 1), clientes que compraram mais de uma vez (f = 2)
 */
 
 -- ***** ETAPA 2: Criar uma tabela com quartis *****
 
 -- Criar uma tabela com os valores dos quartis de recencia, frequencia e valor_monetari
 
CREATE TABLE quartis (variavel VARCHAR(255), quartil INT, valor DECIMAL(10,2), ordem INT);

-- Inserir dados de quartil da variável recencia

INSERT INTO quartis(variavel, quartil, valor, ordem)
WITH CTE AS
(
SELECT recencia, ROW_NUMBER() OVER (ORDER BY recencia ASC) AS ordem FROM analise_rfm
)
SELECT 'recencia' AS variavel, ROW_NUMBER() OVER() AS quartil, recencia AS valor, ordem
FROM CTE WHERE ordem IN (ROUND(0.25*94087,0), ROUND(0.50*94087,0), ROUND(0.75*94087,0));

-- Inserir dados de quartil da variável frequencia

INSERT INTO quartis(variavel, quartil, valor, ordem)
WITH CTE AS
(
SELECT frequencia, ROW_NUMBER() OVER (ORDER BY frequencia ASC) AS ordem FROM analise_rfm
)
SELECT 'frequencia' AS variavel, ROW_NUMBER() OVER() AS quartil, frequencia AS valor, ordem
FROM CTE WHERE ordem IN (ROUND(0.25*94087,0), ROUND(0.50*94087,0), ROUND(0.75*94087,0));

-- Inserir dados de quartil da variável valor_monetario

INSERT INTO quartis(variavel, quartil, valor, ordem)
WITH CTE AS
(
SELECT valor_monetario, ROW_NUMBER() OVER (ORDER BY valor_monetario ASC) AS ordem FROM analise_rfm
)
SELECT 'valor_monetario' AS variavel, ROW_NUMBER() OVER() AS quartil, valor_monetario AS valor, ordem
FROM CTE WHERE ordem IN (ROUND(0.25*94087,0), ROUND(0.50*94087,0), ROUND(0.75*94087,0));

-- Visualizar a tabela

SELECT * FROM quartis;

-- ***** ETAPA 3: Inserir as colunas r, f, m, score_rfm, segmento_rfm, cluster_cliente e decisao *****

-- Inserção das colunas na tabela

ALTER TABLE analise_rfm
ADD COLUMN r INTEGER,
ADD COLUMN f INTEGER,
ADD COLUMN m INTEGER,
ADD COLUMN score_rfm INTEGER,
ADD COLUMN segmento_rfm VARCHAR(3),
ADD COLUMN cluster_cliente VARCHAR(100),
ADD COLUMN decisao VARCHAR(100);

-- Inserção dos dados nas colunas r, f e m

UPDATE analise_rfm
SET
r = CASE WHEN recencia <=
(SELECT valor FROM quartis WHERE variavel = 'recencia' and quartil = 1)
THEN 1
WHEN recencia >
(SELECT valor FROM quartis WHERE variavel = 'recencia' and quartil = 1)
AND recencia <=
(SELECT valor FROM quartis WHERE variavel = 'recencia' and quartil = 2)
THEN 2
WHEN recencia >
(SELECT valor FROM quartis WHERE variavel = 'recencia' and quartil = 2)
AND recencia <=
(SELECT valor FROM quartis WHERE variavel = 'recencia' and quartil = 3)
THEN 3
ELSE 4
END,
f = CASE WHEN frequencia = 1 THEN 1 ELSE 2 END,
m = CASE WHEN valor_monetario <=
(SELECT valor FROM quartis WHERE variavel = 'valor_monetario' and quartil = 1)
THEN 1
WHEN valor_monetario >
(SELECT valor FROM quartis WHERE variavel = 'valor_monetario' and quartil = 1)
AND valor_monetario <=
(SELECT valor FROM quartis WHERE variavel = 'valor_monetario' and quartil = 2)
THEN 2
WHEN valor_monetario >
(SELECT valor FROM quartis WHERE variavel = 'valor_monetario' and quartil = 2)
AND valor_monetario <=
(SELECT valor FROM quartis WHERE variavel = 'valor_monetario' and quartil = 3)
THEN 3
ELSE 4
END;

-- Inserção dos dados nas colunas score_rfm e segmento_rfm

UPDATE analise_rfm
SET score_rfm = r+f+m,
segmento_rfm = CONCAT(r::TEXT, f::TEXT, m::TEXT);

-- Inserção dos dados nas colunas cluster_cliente e decisao

UPDATE analise_rfm
SET
cluster_cliente = CASE WHEN ((CAST(segmento_rfm AS INTEGER) >= 424) OR (score_rfm >= 9)) THEN 'Clientes Vip'
WHEN ((score_rfm >= 8) AND (m = 4)) THEN 'Clientes Leais que compram com frequência'
WHEN ((score_rfm >= 6) AND (f >= 2)) THEN 'Clientes leais'
WHEN ((score_rfm <= 4) AND (r = 1)) THEN 'Clientes quase perdidos'
WHEN ((CAST(segmento_rfm AS INTEGER) >= 221) OR (score_rfm >= 6)) THEN 'Potenciais clientes leais'
WHEN ((CAST(segmento_rfm AS INTEGER) >= 121) AND (r = 1) OR (score_rfm = 5)) THEN 'Clientes que precisam de atenção'
ELSE 'Clientes perdidos' END,
decisao = CASE WHEN (CAST(segmento_rfm AS INTEGER) >= 424) OR (score_rfm >= 9) THEN 'Incentivos não relacionados a preços; Oferecer edição limitada e programas de fidelidade'
WHEN (score_rfm >= 8) AND (m = 4) THEN 'Oferecer itens mais caros'
WHEN (score_rfm >= 6) AND (f >= 2) THEN 'Oferecer programas de fidelidade e venda cruzada'
WHEN (score_rfm <= 4) AND (r = 1) THEN 'Ofrecer incentivos de preços agressivos'
WHEN (CAST(segmento_rfm AS INTEGER) >= 221) OR (score_rfm >= 6) THEN 'Recomendações de venda cruzada e cupons de desconto'
WHEN (CAST(segmento_rfm AS INTEGER) >= 121) AND (r = 1) OR (score_rfm = 5) THEN 'Incentivos de preços e ofertas por tempo limitado'
ELSE 'Não gaste muito tentando readquirir esse cliente' END;

-- Visualizando os registros

SELECT * FROM analise_rfm LIMIT 20;