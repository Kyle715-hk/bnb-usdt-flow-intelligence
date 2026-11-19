-- BNB Chain USDT Payment Size Segmentation (Retail To-C vs. B2B / Institutional)
-- Token: 0x55d398326f99059fF775485246999027B3197955 (BNB Chain USDT, 18 decimals)
-- Window: 2026-08-15 to 2026-11-09

WITH transfers AS (
  SELECT
    date_trunc('day', evt_block_time) AS day,
    value / 1e18 AS amount_usdt
  FROM erc20_bnb.evt_Transfer
  WHERE contract_address = 0x55d398326f99059fF775485246999027B3197955
    AND evt_block_time >= TIMESTAMP '2026-08-15'
    AND evt_block_time <  TIMESTAMP '2026-11-10'
    AND value > 0
),
bucketed AS (
  SELECT
    CASE
      WHEN amount_usdt < 100 THEN '1. Micro-Retail (<$100)'
      WHEN amount_usdt < 1000 THEN '2. Standard Retail ($100–$1k)'
      WHEN amount_usdt < 10000 THEN '3. Pro-Retail / SME ($1k–$10k)'
      WHEN amount_usdt < 1000000 THEN '4. B2B / Commercial ($10k–$1M)'
      ELSE '5. Institutional / Whale (≥$1M)'
    END AS payment_tier,
    CASE
      WHEN amount_usdt < 10000 THEN 'To-C / Retail (<$10k)'
      ELSE 'B2B / Institutional (≥$10k)'
    END AS segment,
    amount_usdt
  FROM transfers
)
SELECT
  payment_tier,
  segment,
  COUNT(*) AS tx_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_tx_count,
  ROUND(SUM(amount_usdt), 2) AS total_volume_usdt,
  ROUND(100.0 * SUM(amount_usdt) / SUM(SUM(amount_usdt)) OVER (), 2) AS pct_of_volume
FROM bucketed
GROUP BY 1, 2
ORDER BY 1;
