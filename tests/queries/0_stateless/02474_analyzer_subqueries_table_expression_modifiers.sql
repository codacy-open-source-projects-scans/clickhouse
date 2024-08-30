SET enable_analyzer = 1;

SELECT * FROM (SELECT 1) FINAL; -- { serverError UNSUPPORTED_METHOD }
SELECT * FROM (SELECT 1) SAMPLE 1/2; -- { serverError UNSUPPORTED_METHOD }
SELECT * FROM (SELECT 1) FINAL SAMPLE 1/2; -- { serverError UNSUPPORTED_METHOD }

WITH cte_subquery AS (SELECT 1) SELECT * FROM cte_subquery FINAL; -- { serverError UNSUPPORTED_METHOD }
WITH cte_subquery AS (SELECT 1) SELECT * FROM cte_subquery SAMPLE 1/2; -- { serverError UNSUPPORTED_METHOD }
WITH cte_subquery AS (SELECT 1) SELECT * FROM cte_subquery FINAL SAMPLE 1/2; -- { serverError UNSUPPORTED_METHOD }

SELECT * FROM (SELECT 1 UNION ALL SELECT 1) FINAL; -- { serverError UNSUPPORTED_METHOD }
SELECT * FROM (SELECT 1 UNION ALL SELECT 1) SAMPLE 1/2; -- { serverError UNSUPPORTED_METHOD }
SELECT * FROM (SELECT 1 UNION ALL SELECT 1) FINAL SAMPLE 1/2; -- { serverError UNSUPPORTED_METHOD }

WITH cte_subquery AS (SELECT 1 UNION ALL SELECT 1) SELECT * FROM cte_subquery FINAL; -- { serverError UNSUPPORTED_METHOD }
WITH cte_subquery AS (SELECT 1 UNION ALL SELECT 1) SELECT * FROM cte_subquery SAMPLE 1/2; -- { serverError UNSUPPORTED_METHOD }
WITH cte_subquery AS (SELECT 1 UNION ALL SELECT 1) SELECT * FROM cte_subquery FINAL SAMPLE 1/2; -- { serverError UNSUPPORTED_METHOD }