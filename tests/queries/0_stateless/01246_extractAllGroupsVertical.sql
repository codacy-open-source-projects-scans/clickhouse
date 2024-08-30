-- error cases
SELECT extractAllGroupsVertical();  --{serverError NUMBER_OF_ARGUMENTS_DOESNT_MATCH} not enough arguments
SELECT extractAllGroupsVertical('hello');  --{serverError NUMBER_OF_ARGUMENTS_DOESNT_MATCH} not enough arguments
SELECT extractAllGroupsVertical('hello', 123);  --{serverError ILLEGAL_TYPE_OF_ARGUMENT} invalid argument type
SELECT extractAllGroupsVertical(123, 'world');  --{serverError ILLEGAL_TYPE_OF_ARGUMENT}  invalid argument type
SELECT extractAllGroupsVertical('hello world', '((('); --{serverError CANNOT_COMPILE_REGEXP}  invalid re
SELECT extractAllGroupsVertical('hello world', materialize('\\w+')); --{serverError ILLEGAL_COLUMN} non-const needle
SELECT extractAllGroupsVertical('hello world', '\\w+'); -- { serverError BAD_ARGUMENTS } 0 groups

SELECT '1 group, multiple matches, String and FixedString';
SELECT extractAllGroupsVertical('hello world', '(\\w+)');
SELECT extractAllGroupsVertical('hello world', CAST('(\\w+)' as FixedString(5)));
SELECT extractAllGroupsVertical(CAST('hello world' AS FixedString(12)), '(\\w+)');
SELECT extractAllGroupsVertical(CAST('hello world' AS FixedString(12)), CAST('(\\w+)' as FixedString(5)));
SELECT extractAllGroupsVertical(materialize(CAST('hello world' AS FixedString(12))), '(\\w+)');
SELECT extractAllGroupsVertical(materialize(CAST('hello world' AS FixedString(12))), CAST('(\\w+)' as FixedString(5)));

SELECT 'mutiple groups, multiple matches';
SELECT extractAllGroupsVertical('abc=111, def=222, ghi=333 "jkl mno"="444 foo bar"', '("[^"]+"|\\w+)=("[^"]+"|\\w+)');

SELECT 'big match';
SELECT
    length(haystack), length(matches[1]), length(matches), arrayMap((x) -> length(x), arrayMap(x -> x[1], matches))
FROM (
    SELECT
        repeat('abcdefghijklmnopqrstuvwxyz', number * 10) AS haystack,
        extractAllGroupsVertical(haystack, '(abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz)') AS matches
    FROM numbers(3)
);

SELECT 'lots of matches';
SELECT
    length(haystack), length(matches[1]), length(matches), arrayReduce('sum', arrayMap((x) -> length(x), arrayMap(x -> x[1], matches)))
FROM (
    SELECT
        repeat('abcdefghijklmnopqrstuvwxyz', number * 10) AS haystack,
        extractAllGroupsVertical(haystack, '(\\w)') AS matches
    FROM numbers(3)
);

SELECT 'lots of groups';
SELECT
    length(haystack), length(matches[1]), length(matches), arrayMap((x) -> length(x), arrayMap(x -> x[1], matches))
FROM (
    SELECT
        repeat('abcdefghijklmnopqrstuvwxyz', number * 10) AS haystack,
        extractAllGroupsVertical(haystack, repeat('(\\w)', 100)) AS matches
    FROM numbers(3)
);