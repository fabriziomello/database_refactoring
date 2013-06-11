-- Tests for core functions which Epic provides.
-- To run, execute epic.sql, then this script, then test.run_module('test_core').

CREATE OR REPLACE FUNCTION test.test_statement() RETURNS VOID AS $$
-- module: test_core
DECLARE
  t    text;
BEGIN
  -- Test a passthrough
  SELECT INTO t * FROM test.statement('SELECT 1');
  PERFORM test.assert_equal(t, 'SELECT 1');
  
  -- Test missing SELECT
  SELECT INTO t * FROM test.statement('generate_series()');
  PERFORM test.assert_equal(t, 'SELECT * FROM generate_series()');
  
  -- Test leading whitespace
  SELECT INTO t * FROM test.statement('    SELECT 1');
  PERFORM test.assert_equal(t, '    SELECT 1');
  
  -- Test leading whitespace, no SELECT
  SELECT INTO t * FROM test.statement('   generate_series()   ');
  PERFORM test.assert_equal(t, 'SELECT * FROM    generate_series()   ');
  
  -- Test EXECUTE
  SELECT INTO t * FROM test.statement('EXECUTE myfoo');
  PERFORM test.assert_equal(t, 'EXECUTE myfoo');
  
  -- Test VALUES
  SELECT INTO t * FROM test.statement('VALUES (99, ''foo'')');
  PERFORM test.assert_equal(t, 'VALUES (99, ''foo'')');
  SELECT INTO t * FROM test.statement('VALUES(99, ''foo'')');
  PERFORM test.assert_equal(t, 'VALUES(99, ''foo'')');
  
  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;

