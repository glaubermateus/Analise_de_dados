# Análise RFM e Segmentação de Clientes em SQL


## 💡 Resumo do projeto

Este projeto implementa uma análise RFM (Recência, Frequência e Valor Monetário) diretamente em SQL, com o objetivo de segmentar clientes com base em seu comportamento de compra e gerar recomendações estratégicas de marketing e retenção. A solução cria uma pipeline totalmente SQL para cálculo de métricas RFM, classificação de clientes e geração de insights acionáveis.


## ❓ Problema de negócio / Contexto

Empresas com grandes volumes de transações enfrentam o desafio de entender quais clientes são mais valiosos, fiéis ou propensos a churn.
O objetivo deste projeto é identificar e classificar os clientes em diferentes segmentos comportamentais, utilizando métricas RFM, para orientar estratégias de fidelização, reativação e aumento de receita. Para isso, usei como base de dados o dataset disponibilizado pela empresa Olist.


## 📊 Dados utilizados

Os dados utilizados foram extraídos de uma tabela de pedidos (df) contendo:

* order_id — identificador do pedido
* order_purchase_timestamp — data da compra
* payment_value — valor monetário da transação
* customer_unique_id — identificador único do cliente

Um total de aproximadamente 94 mil registros foi utilizado como base para os cálculos de quartis e segmentação.


## 🛠️ Metodologia e ferramentas

A análise foi realizada exclusivamente em SQL, com as seguintes etapas:

1. Importação dos dados da base df.csv (etapa realizada manualmente)
2. Criação da tabela analise_rfm — armazena as métricas de recência, frequência e valor monetário de cada cliente.
3. Geração de tabela temporária — para cálculo da data de referência e consolidação das compras.
4. Cálculo dos indicadores RFM:

* Recência: diferença entre a data de referência e a última compra.
* Frequência: número de pedidos realizados pelo cliente.
* Valor Monetário: soma dos valores gastos.

5. Cálculo de quartis — criação da tabela quartis para definir faixas de classificação das métricas RFM.
6. Atribuição de scores R, F e M — conversão dos valores contínuos em escores de 1 a 4.
7. Geração do score_rfm e segmento_rfm — combinação dos três escores para representar o perfil do cliente.
8. Criação de clusters e decisões estratégicas.

## Ferramentas e bibliotecas utilizadas:

* PostgreSQL
* Window Functions (ROW_NUMBER, MAX, COUNT, SUM)
* CTEs e manipulação de quartis
* Atualizações condicionais via CASE WHEN

## 🔎 Principais insights e resultados

A partir do cálculo do score RFM (r + f + m) e do segmento RFM (concatenado), foi possível classificar os clientes em grupos estratégicos, como:
* Clientes VIP (score ≥ 9): altamente engajados e de alto valor — recomenda-se ofertas exclusivas e programas de fidelidade.
* Clientes leais: compram com frequência, merecem ações de retenção e cross-selling.
* Clientes quase perdidos: precisam de incentivos agressivos de preço.
* Clientes perdidos: não é recomendado investir recursos de recuperação.

Essa estrutura permite gerar decisões automatizadas de marketing, otimizando investimentos em campanhas e priorizando segmentos de maior retorno.

## 🚀 Como executar o projeto

### Pré-requisitos:

* Ambiente SQL (O projeto foi criado no Banco Postgre)
* Permissão para criação e modificação de tabelas

**Execução:**

1. Copie o script SQL completo para seu editor SQL.
2. Execute as etapas em ordem (da criação da tabela analise_rfm até a última query).
3. Verifique os resultados com:

```SELECT * FROM analise_rfm LIMIT 100;```

4. Visualize os grupos e decisões estratégicas com:

```SELECT cluster_cliente, decisao, COUNT(*) FROM analise_rfm GROUP BY cluster_cliente, decisao;```

## 🔗 Contato

Glauber Cruz

[LinkedIn](https://www.linkedin.com/in/glauber-cruz-6213281b0/)

[Portfólio](https://sites.google.com/view/glaubercruz/p%C3%A1gina-inicial)
