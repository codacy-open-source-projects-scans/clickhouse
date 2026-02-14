-- Tags: no-replicated-database
-- Test for constant PREWHERE with patch parts (lightweight updates).
-- Constant PREWHERE expressions on tables with patch parts previously caused
-- a LOGICAL_ERROR exception in `adjustLastGranule` (issue #94700) because
-- `num_read_rows` is 0 (no columns physically read for constant PREWHERE),
-- while `total_rows_per_granule` reflects the full granule sizes.
-- https://github.com/ClickHouse/ClickHouse/issues/94700

DROP TABLE IF EXISTS t_prewhere_const_patches SYNC;

SET enable_lightweight_update = 1;
SET mutations_sync = 2;

CREATE TABLE t_prewhere_const_patches (a UInt64, b UInt64, c UInt64, d UInt64)
ENGINE = MergeTree
ORDER BY tuple()
SETTINGS
    index_granularity = 8192,
    min_bytes_for_wide_part = 0,
    min_bytes_for_full_part_storage = 0,
    ratio_of_defaults_for_sparse_serialization = 1.0,
    enable_block_number_column = 1,
    enable_block_offset_column = 1;

-- Stop merges to ensure patch parts are preserved
SYSTEM STOP MERGES t_prewhere_const_patches;

INSERT INTO t_prewhere_const_patches SELECT number, 0, 0, 0 FROM numbers(10000);

-- Apply some lightweight updates to create patch parts
UPDATE t_prewhere_const_patches SET b = 1 WHERE a % 4 = 0;
UPDATE t_prewhere_const_patches SET c = 2 WHERE a % 4 = 0;

SELECT count() FROM t_prewhere_const_patches PREWHERE 18;

SELECT count() FROM t_prewhere_const_patches PREWHERE 1;

SELECT count() FROM t_prewhere_const_patches PREWHERE 0;

-- The original fuzzed query pattern from issue #94700
SELECT b, c, count() FROM t_prewhere_const_patches PREWHERE toUInt128(toUInt128(1)) = isNotNull(toLowCardinality(1)) GROUP BY b, c ORDER BY b, c;

-- Non-aligned max_block_size to exercise `adjustLastGranule` edge cases.
-- Use a non-foldable constant PREWHERE expression (simple `PREWHERE 1` gets optimized away).
SELECT count() FROM t_prewhere_const_patches PREWHERE toUInt128(1) = isNotNull(1) SETTINGS max_block_size = 100;
SELECT count() FROM t_prewhere_const_patches PREWHERE toUInt128(1) = isNotNull(1) SETTINGS max_block_size = 8482;

DROP TABLE IF EXISTS t_prewhere_const_patches SYNC;
