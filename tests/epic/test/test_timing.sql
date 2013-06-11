-- Tests for the timing functions which Epic provides.
-- To run, execute epic.sql, then this script, then test.run_module('test_timing').

CREATE OR REPLACE FUNCTION test._sleep(s double precision) RETURNS VOID AS $$
-- sleep function for Postgres 8.1
DECLARE
  start    timestamp with time zone;
BEGIN
  start := timeofday()::timestamp;
  LOOP
    EXIT WHEN (timeofday()::timestamp - start) > (s || ' second')::interval;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_timing() RETURNS VOID AS $$
-- module: test_timing
DECLARE
  t           interval;
BEGIN
  -- Shame we have to use 0.01 but some platforms don't have finer resolution.
  t := test.timing('SELECT test._sleep(0.01)', 100);
  
  -- Let's assume that sleep(0.01) * 100 should never run *under* 1s
  PERFORM test.assert_greater_than_or_equal(t, '1.0');
  -- ...but it does have overhead, up to 56% in my simple tests.
  -- We'll assert < 2x.
  PERFORM test.assert_less_than(t, '2.0');
  
  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;

