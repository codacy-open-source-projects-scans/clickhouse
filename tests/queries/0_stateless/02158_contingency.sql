SELECT round(cramersV(a, b), 2), round(cramersVBiasCorrected(a, b), 2), round(theilsU(a, b), 2), round(theilsU(b, a), 2), round(contingency(a, b), 2) FROM (SELECT number % 3 AS a, number % 5 AS b FROM numbers(150));
SELECT round(cramersV(a, b), 2), round(cramersVBiasCorrected(a, b), 2), round(theilsU(a, b), 2), round(theilsU(b, a), 2), round(contingency(a, b), 2) FROM (SELECT number AS a, number + 1 AS b FROM numbers(150));
SELECT round(cramersV(a, b), 2), round(cramersVBiasCorrected(a, b), 2), round(theilsU(a, b), 2), round(theilsU(b, a), 2), round(contingency(a, b), 2) FROM (SELECT number % 10 AS a, number % 10 AS b FROM numbers(150));
SELECT round(cramersV(a, b), 2), round(cramersVBiasCorrected(a, b), 2), round(theilsU(a, b), 2), round(theilsU(b, a), 2), round(contingency(a, b), 2) FROM (SELECT number % 10 AS a, number % 5 AS b FROM numbers(150));
SELECT round(cramersV(a, b), 2), round(cramersVBiasCorrected(a, b), 2), round(theilsU(a, b), 2), round(theilsU(b, a), 2), round(contingency(a, b), 2) FROM (SELECT number % 10 AS a, number % 10 = 0 ? number : a AS b FROM numbers(150));
