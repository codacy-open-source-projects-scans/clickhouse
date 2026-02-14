-- Tags: no-replicated-database
-- Regression test for https://github.com/ClickHouse/ClickHouse/issues/94700
-- Constant PREWHERE expressions with non-aligned `max_block_size`
-- caused a LOGICAL_ERROR exception in `adjustLastGranule` because `num_read_rows` was 0
-- (no physical columns read) while `total_rows_per_granule` reflected the full granule sizes.
-- Without the fix, this test produces either a LOGICAL_ERROR or incorrect results
-- (missing rows / wrong counts).
--
-- Note: Simple `PREWHERE 1` is optimized away by the query planner and doesn't exercise
-- the constant PREWHERE code path. We use `PREWHERE toUInt128(1) = isNotNull(1)` which
-- evaluates to a constant at runtime but isn't folded during planning.

DROP TABLE IF EXISTS t_no_zero_rows SYNC;

SET enable_lightweight_update = 1;
SET mutations_sync = 2;

CREATE TABLE t_no_zero_rows (d Date, a UInt64, b UInt64)
ENGINE = MergeTree
ORDER BY a
SETTINGS
    index_granularity = 100,
    min_bytes_for_wide_part = 0,
    min_bytes_for_full_part_storage = 0,
    ratio_of_defaults_for_sparse_serialization = 1.0,
    enable_block_number_column = 1,
    enable_block_offset_column = 1;

SYSTEM STOP MERGES t_no_zero_rows;

-- Insert 250 rows with dates starting from 2024-01-01 (never 1970-01-01).
-- With index_granularity = 100, this creates 3 granules: 100, 100, 50.
INSERT INTO t_no_zero_rows SELECT toDate('2024-01-01') + (number % 30), number, 0 FROM numbers(250);

-- Create patch parts via lightweight updates
UPDATE t_no_zero_rows SET b = 1 WHERE a % 5 = 0;

-- Use a constant PREWHERE expression that is NOT folded by the optimizer.
-- Without the fix, these queries trigger LOGICAL_ERROR in `adjustLastGranule`.
SELECT d, count() FROM t_no_zero_rows
    PREWHERE toUInt128(1) = isNotNull(1)
    GROUP BY d ORDER BY d
    SETTINGS max_block_size = 120, merge_tree_read_split_ranges_into_intersecting_and_non_intersecting_injection_probability = 0;

-- Verify no 1970-01-01 (zero-date) rows appear
SELECT count() FROM t_no_zero_rows
    PREWHERE toUInt128(1) = isNotNull(1)
    WHERE d = '1970-01-01'
    SETTINGS merge_tree_read_split_ranges_into_intersecting_and_non_intersecting_injection_probability = 0;

-- Additional edge cases: different non-aligned block sizes
SELECT count() FROM t_no_zero_rows
    PREWHERE toUInt128(1) = isNotNull(1)
    SETTINGS max_block_size = 77, merge_tree_read_split_ranges_into_intersecting_and_non_intersecting_injection_probability = 0;
SELECT count() FROM t_no_zero_rows
    PREWHERE toUInt128(1) = isNotNull(1)
    SETTINGS max_block_size = 250, merge_tree_read_split_ranges_into_intersecting_and_non_intersecting_injection_probability = 0;
SELECT count() FROM t_no_zero_rows
    PREWHERE toUInt128(1) = isNotNull(1)
    SETTINGS max_block_size = 1000, merge_tree_read_split_ranges_into_intersecting_and_non_intersecting_injection_probability = 0;

DROP TABLE IF EXISTS t_no_zero_rows SYNC;
