-- Tests for Epic's exception-raising approach, plus test.results.
-- To run, execute epic.sql, then this script, then test.run_module('test_results').

SET search_path = test, public, pg_catalog;


CREATE OR REPLACE FUNCTION test.test_pass() RETURNS VOID AS $$
-- Assert the correct operation of test.pass.
-- module: test_results
BEGIN
  BEGIN
    PERFORM test.pass();
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = '[OK]' THEN
      PERFORM test.pass();
    ELSE
      RAISE EXCEPTION 'test.pass() did not raise the ''[OK]'' exception. Got % instead.', SQLERRM;
    END IF;
  END;
  PERFORM test.fail('test.pass() did not raise the ''[OK]'' exception.');
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.test_fail() RETURNS VOID AS $$
-- Assert the correct operation of test.fail.
-- module: test_results
BEGIN
  BEGIN
    PERFORM test.fail('This is supposed to fail.');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = '[FAIL] This is supposed to fail.' THEN
      PERFORM test.pass();
    ELSE
      RAISE EXCEPTION 'test.fail() did not raise the correct exception. Got % instead.', SQLERRM;
    END IF;
  END;
  RAISE EXCEPTION '[FAIL] test.fail() did not raise an exception.';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_todo() RETURNS VOID AS $$
-- Assert the correct operation of test.todo.
-- module: test_results
BEGIN
  BEGIN
    PERFORM test.todo('This test isn''t done yet.');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = '[TODO] This test isn''t done yet.' THEN
      PERFORM test.pass();
    ELSE
      RAISE EXCEPTION 'test.todo() did not raise the correct exception. Got % instead.', SQLERRM;
    END IF;
  END;
  RAISE EXCEPTION '[FAIL] test.todo() did not raise an exception.';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_skip() RETURNS VOID AS $$
-- Assert the correct operation of test.skip.
-- module: test_results
BEGIN
  BEGIN
    PERFORM test.skip('This test is too slow.');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = '[SKIP] This test is too slow.' THEN
      PERFORM test.pass();
    ELSE
      RAISE EXCEPTION 'test.skip() did not raise the correct exception. Got % instead.', SQLERRM;
    END IF;
  END;
  RAISE EXCEPTION '[FAIL] test.skip() did not raise an exception.';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.demo_fail() RETURNS VOID AS $$
-- Demonstration function for test failure.
BEGIN
  PERFORM test.fail('This demonstrates a failed test.');
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.demo_todo() RETURNS VOID AS $$
-- Demonstration function for TODO tests.
BEGIN
  PERFORM test.todo('This demonstrates a TODO test.');
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_run_test() RETURNS VOID AS $$
-- Assert the correct operation of test.run_test.
-- module: test_results
DECLARE
  result    bool;
BEGIN
  -- Successful tests MUST insert an [OK] record into test.results.
  DELETE FROM test.results WHERE name = 'test_pass';
  PERFORM test.run_test('test_pass');
  PERFORM test.assert_rows(
    'SELECT result, errcode, errmsg FROM test.results WHERE name = ''test_pass''',
    'SELECT ''[OK]'', '''', ''''');
  
  -- Failed tests MUST insert a [FAIL] record into test.results.
  DELETE FROM test.results WHERE name = 'demo_fail';
  PERFORM test.run_test('demo_fail');
  PERFORM test.assert_rows(
    'SELECT result, errcode, errmsg FROM test.results WHERE name = ''demo_fail''',
    'SELECT ''[FAIL]'', ''P0001'', ''This demonstrates a failed test.''');
  
  -- TODO tests MUST insert a [TODO] record into test.results.
  DELETE FROM test.results WHERE name = 'demo_todo';
  PERFORM test.run_test('demo_todo');
  PERFORM test.assert_rows(
    'SELECT result, errcode, errmsg FROM test.results WHERE name = ''demo_todo''',
    'SELECT ''[TODO]'', '''', ''This demonstrates a TODO test.''');
  
  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;


