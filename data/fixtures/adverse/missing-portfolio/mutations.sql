-- Preserve dependent records so their missing portfolio relationship remains
-- observable through enriched API responses.
DELETE FROM portfolios
WHERE portfolio_id = 'PORT-1002';
