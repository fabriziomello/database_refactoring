-- Tests for the various assert_* functions which Epic provides.
-- To run, execute epic.sql, then this script, then test.run_module('test_asserts').

SET search_path = test, public, pg_catalog;


CREATE OR REPLACE FUNCTION test.test_assert_test_schema() RETURNS VOID AS $$
-- Assert the correct operation of epic.assert_test_schema
-- module: test_asserts
DECLARE
  nsoid           oid;
  objname         text;
BEGIN
  -- assert_test_schema MUST create a 'test' schema.
  -- Of course, if it didn't, this proc wouldn't compile, but what the hey.
  SELECT pg_namespace.oid INTO nsoid FROM pg_namespace WHERE nspname = 'test';
  IF nsoid IS NULL THEN
    RAISE EXCEPTION 'assert_test_schema did not create a ''test'' schema.';
  END IF;
  
  -- assert_test_schema MUST create a 'test.results' table
  SELECT tablename INTO objname FROM pg_tables 
    WHERE schemaname = 'test' AND tablename = 'results';
  IF objname IS NULL THEN
    RAISE EXCEPTION 'assert_test_schema did not create a test.results table.';
  END IF;
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_raises() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_raises
-- module: test_asserts
DECLARE
  retval    text;
  failed    bool;
BEGIN
  -- assert_raises() MUST return VOID if an error is raised.
  SELECT INTO retval * FROM test.assert_raises('unknown', 'relation "unknown" does not exist', '42P01');
  IF retval != '' THEN
    RAISE EXCEPTION 'test.assert_raises() did not return void.';
  END IF;
  
  -- assert_raises() MUST raise an exception if no error is raised.
  failed := false;
  BEGIN
    SELECT INTO retval * FROM test.assert_raises('pg_namespace', '', '');
  EXCEPTION WHEN OTHERS THEN
    failed := true;
    IF SQLERRM = 'Call: ''pg_namespace'' did not raise an error.' THEN
      NULL;
    ELSE
      RAISE EXCEPTION 'test.assert_raises() did not raise the given message on falsehood. Raised: %', SQLERRM;
    END IF;
  END;
  IF NOT failed THEN
    RAISE EXCEPTION 'test.assert_raises() did not fail.';
  END IF;
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert() RETURNS VOID AS $$
-- Assert the correct operation of test.assert
-- module: test_asserts
DECLARE
  retval    text;
BEGIN
  -- assert() MUST return VOID if the given assertion holds.
  SELECT INTO retval * FROM test.assert(true, 'truth is falsehood!');
  IF retval != '' THEN
    RAISE EXCEPTION 'test.assert() did not return void.';
  END IF;
  
  -- assert() MUST raise an exception if the given assertion does not hold.
  PERFORM test.assert_raises('test.assert(false, ''falsehood is truth'')',
                             'falsehood is truth', 'P0001');
  
  -- assert() MUST raise an exception if the given assertion is NULL.
  PERFORM test.assert_raises('test.assert(null, ''null should choke'')',
                             'Assertion test may not be NULL.', 'P0001');
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test._return_void() RETURNS VOID AS $$
BEGIN
  RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_assert_void() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_void
-- module: test_asserts
DECLARE
  retval    text;
BEGIN
  -- assert_void() MUST return VOID if the given call returns VOID.
  SELECT INTO retval * FROM test.assert_void('test._return_void()');
  IF retval != '' THEN
    RAISE EXCEPTION 'assert_void did not itself return void. Got ''%'' instead.', retval;
  END IF;
  
  -- assert_void() MUST raise an exception if the given call does not return void.
  PERFORM test.assert_raises('test.assert_void(''pg_namespace WHERE nspname = ''''pg_catalog'''''')', 
    'Call: ''pg_namespace WHERE nspname = ''pg_catalog'''' did not return void. Got ''pg_catalog'' instead.',
    'P0001');
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_equal() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_equal
-- module: test_asserts
DECLARE
  retval    text;
BEGIN
  -- assert_equal() MUST return VOID if the given assertion holds.
  PERFORM test.assert_void('test.assert_equal(1, 1)');
  PERFORM test.assert_void('test.assert_equal(''abc''::text, ''abc'');');
  
  -- assert_equal() MUST return VOID if both args are null.
  PERFORM test.assert_void('test.assert_equal(NULL::int, NULL);');
  
  -- assert_equal() MUST raise an exception if the given assertion does not hold.
  PERFORM test.assert_raises('test.assert_equal(1, 2)', '1 != 2', 'P0001');
  PERFORM test.assert_raises('test.assert_equal(''abc''::text, ''xyz'')', 'abc != xyz', 'P0001');
  
  -- assert_equal() MUST raise an exception if only one arg is NULL.
  PERFORM test.assert_raises('test.assert_equal(8, NULL::int)', '8 != <NULL>', 'P0001');
  PERFORM test.assert_raises('test.assert_equal(NULL::int, 7)', '<NULL> != 7', 'P0001');
  
  -- assert_equal() will raise an undefined_function exception if the args have different types.
  -- It would be nice to find a way around this (without writing M x N overloaded funcs).
  PERFORM test.assert_raises('test.assert_equal(8, ''abc''::text)',
    'function test.assert_equal(integer, text) does not exist', '42883');
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_not_equal() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_not_equal
-- module: test_asserts
DECLARE
  retval    text;
BEGIN
  -- assert_not_equal() MUST return VOID if the given assertion does not hold.
  PERFORM test.assert_void('test.assert_not_equal(1, 2);');
  PERFORM test.assert_void('test.assert_not_equal(''abc''::text, ''xyz'');');
  
  -- assert_not_equal() MUST return VOID if only one arg is NULL.
  PERFORM test.assert_void('test.assert_not_equal(8, NULL);');
  PERFORM test.assert_void('test.assert_not_equal(NULL, 7);');
  
  -- assert_not_equal() MUST raise an exception if the given assertion holds.
  PERFORM test.assert_raises('test.assert_not_equal(1, 1)', '1 = 1', 'P0001');
  PERFORM test.assert_raises('test.assert_not_equal(''abc''::text, ''abc'')', 'abc = abc', 'P0001');
  
  -- assert_not_equal() MUST raise an exception if both args are NULL.
  PERFORM test.assert_raises('test.assert_not_equal(NULL::int, NULL)', '<NULL> = <NULL>', 'P0001');
  
  -- assert_not_equal() will raise an undefined_function exception if the args have different types.
  -- It would be nice to find a way around this (without writing M x N overloaded funcs).
  PERFORM test.assert_raises('test.assert_not_equal(8, ''abc''::text)', 
    'function test.assert_not_equal(integer, text) does not exist', '42883');
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_less_than() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_less_than
-- module: test_asserts
DECLARE
  retval    text;
BEGIN
  -- assert_less_than() MUST return VOID if a < b.
  PERFORM test.assert_void('test.assert_less_than(1, 2);');
  PERFORM test.assert_void('test.assert_less_than(''abc''::text, ''xyz'');');
  
  -- assert_less_than() MUST raise an exception if a >= b.
  PERFORM test.assert_raises('test.assert_less_than(2, 1)', '2 not < 1', 'P0001');
  PERFORM test.assert_raises('test.assert_less_than(1, 1)', '1 not < 1', 'P0001');
  PERFORM test.assert_raises('test.assert_less_than(''abc''::text, ''abc'')', 
    'abc not < abc', 'P0001');
  PERFORM test.assert_raises('test.assert_less_than(''xyz''::text, ''abc'')', 
    'xyz not < abc', 'P0001');
  
  -- assert_less_than() MUST raise an exception if either arg is NULL.
  PERFORM test.assert_raises('test.assert_less_than(NULL::int, NULL)', 
    'Assertion arguments may not be NULL.', 'P0001');
  
  -- assert_less_than() will raise an undefined_function exception if the args have different types.
  -- It would be nice to find a way around this (without writing M x N overloaded funcs).
  PERFORM test.assert_raises('test.assert_less_than(8, ''abc''::text)', 
    'function test.assert_less_than(integer, text) does not exist', '42883');
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_less_than_or_equal() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_less_than_or_equal
-- module: test_asserts
DECLARE
  retval    text;
BEGIN
  -- assert_less_than_or_equal() MUST return VOID if a <= b.
  PERFORM test.assert_void('test.assert_less_than_or_equal(1, 2);');
  PERFORM test.assert_void('test.assert_less_than_or_equal(1, 1);');
  PERFORM test.assert_void('test.assert_less_than_or_equal(''abc''::text, ''xyz'');');
  PERFORM test.assert_void('test.assert_less_than_or_equal(''abc''::text, ''abc'');');
  
  -- assert_less_than_or_equal() MUST raise an exception if a > b.
  PERFORM test.assert_raises('test.assert_less_than_or_equal(2, 1)', '2 not <= 1', 'P0001');
  PERFORM test.assert_raises('test.assert_less_than_or_equal(''xyz''::text, ''abc'')', 
    'xyz not <= abc', 'P0001');
  
  -- assert_less_than_or_equal() MUST raise an exception if either arg is NULL.
  PERFORM test.assert_raises('test.assert_less_than_or_equal(NULL::int, NULL)', 
    'Assertion arguments may not be NULL.', 'P0001');
  
  -- assert_less_than_or_equal() will raise an undefined_function exception if the args have different types.
  -- It would be nice to find a way around this (without writing M x N overloaded funcs).
  PERFORM test.assert_raises('test.assert_less_than_or_equal(8, ''abc''::text)', 
    'function test.assert_less_than_or_equal(integer, text) does not exist', '42883');
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_greater_than() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_greater_than
-- module: test_asserts
DECLARE
  retval    text;
BEGIN
  -- assert_greater_than() MUST return VOID if a > b.
  PERFORM test.assert_void('test.assert_greater_than(2, 1);');
  PERFORM test.assert_void('test.assert_greater_than(''xyz''::text, ''abc'');');
  
  -- assert_greater_than() MUST raise an exception if a <= b.
  PERFORM test.assert_raises('test.assert_greater_than(1, 2)', '1 not > 2', 'P0001');
  PERFORM test.assert_raises('test.assert_greater_than(1, 1)', '1 not > 1', 'P0001');
  PERFORM test.assert_raises('test.assert_greater_than(''abc''::text, ''abc'')', 
    'abc not > abc', 'P0001');
  PERFORM test.assert_raises('test.assert_greater_than(''abc''::text, ''xyz'')', 
    'abc not > xyz', 'P0001');
  
  -- assert_greater_than() MUST raise an exception if either arg is NULL.
  PERFORM test.assert_raises('test.assert_greater_than(NULL::int, NULL)', 
    'Assertion arguments may not be NULL.', 'P0001');
  
  -- assert_greater_than() will raise an undefined_function exception if the args have different types.
  -- It would be nice to find a way around this (without writing M x N overloaded funcs).
  PERFORM test.assert_raises('test.assert_greater_than(8, ''abc''::text)', 
    'function test.assert_greater_than(integer, text) does not exist', '42883');
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_greater_than_or_equal() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_greater_than_or_equal
-- module: test_asserts
DECLARE
  retval    text;
BEGIN
  -- assert_greater_than_or_equal() MUST return VOID if a >= b.
  PERFORM test.assert_void('test.assert_greater_than_or_equal(2, 1);');
  PERFORM test.assert_void('test.assert_greater_than_or_equal(1, 1);');
  PERFORM test.assert_void('test.assert_greater_than_or_equal(''xyz''::text, ''abc'');');
  PERFORM test.assert_void('test.assert_greater_than_or_equal(''abc''::text, ''abc'');');
  
  -- assert_greater_than_or_equal() MUST raise an exception if a < b.
  PERFORM test.assert_raises('test.assert_greater_than_or_equal(1, 2)', '1 not >= 2', 'P0001');
  PERFORM test.assert_raises('test.assert_greater_than_or_equal(''abc''::text, ''xyz'')', 
    'abc not >= xyz', 'P0001');
  
  -- assert_greater_than_or_equal() MUST raise an exception if either arg is NULL.
  PERFORM test.assert_raises('test.assert_greater_than_or_equal(NULL::int, NULL)', 
    'Assertion arguments may not be NULL.', 'P0001');
  
  -- assert_greater_than_or_equal() will raise an undefined_function exception if the args have different types.
  -- It would be nice to find a way around this (without writing M x N overloaded funcs).
  PERFORM test.assert_raises('test.assert_greater_than_or_equal(8, ''abc''::text)', 
    'function test.assert_greater_than_or_equal(integer, text) does not exist', '42883');
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_rows() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_rows
-- module: test_asserts
DECLARE
  failed     bool;
BEGIN
  -- Tautology
  PERFORM test.assert_rows(
    'SELECT oid, proname FROM pg_proc',
    'SELECT oid, proname FROM pg_proc');
  -- Almost a tautology ;)
  -- Note the trailing semicolon in the first arg.
  PERFORM test.assert_rows(
    'SELECT tablename FROM pg_tables;',
    'SELECT relname FROM pg_class where relkind = ''r''');
  -- SELECT-less argument
  PERFORM test.assert_rows(
    'SELECT adrelid, adnum, adbin, adsrc FROM pg_attrdef',
    'pg_attrdef');
  
  -- ...and an assertion that should fail
  failed := false;
  BEGIN
    PERFORM test.assert_rows(
      'generate_series(1, 10)', 
      'SELECT * FROM generate_series(1, 5)');
  EXCEPTION WHEN OTHERS THEN
    failed := true;
    IF SQLERRM = 'Record: (6) from: generate_series(1, 10) not found in: SELECT * FROM generate_series(1, 5)' THEN
      NULL;
    ELSE
      RAISE EXCEPTION 'test.assert_rows() did not raise the correct error. Raised: %', SQLERRM;
    END IF;
  END;
  IF NOT failed THEN
    PERFORM test.fail('test.assert_rows() did not fail.');
  END IF;
  
  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_column() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_column
-- module: test_asserts
DECLARE
  failed     bool;
BEGIN
  -- Test an assertion that should pass
  PERFORM test.assert_column(
    'generate_series(1, 10);',
    ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  -- explicit colname version
  PERFORM test.assert_column(
    'generate_series(1, 10);',
    ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'generate_series');
  -- text fields
  PERFORM test.assert_column(
    'pg_namespace WHERE nspname IN (''public'', ''test'') ORDER BY nspname',
    ARRAY['public', 'test'],
    'nspname');
  -- timestamp fields. This also tests omitted colname
  PERFORM test.assert_column(
    'SELECT ''2007-04-13 09:28:54.132132''::timestamptz',
    ARRAY['2007-04-13 09:28:54.132132'::timestamptz]);
  
  -- ...and an assertion that should fail
  failed := false;
  BEGIN
    PERFORM test.assert_column('generate_series(1, 10);', ARRAY[1, 2]);
  EXCEPTION WHEN OTHERS THEN
    failed := true;
    IF SQLERRM = '[FAIL] record: 3 not found in array: 1, 2' THEN
      NULL;
    ELSE
      RAISE EXCEPTION 'test.assert_column() did not raise the correct error. Raised: %', SQLERRM;
    END IF;
  END;
  IF NOT failed THEN
    PERFORM test.fail('test.assert_column() did not fail.');
  END IF;
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_empty() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_empty
-- module: test_asserts
DECLARE
  failed     bool;
BEGIN
  -- Test an assertion that should pass
  CREATE TEMP TABLE testtemp (a int);
  PERFORM test.assert_empty('testtemp');
  -- array version
  CREATE TEMP TABLE testtemp2 (a int);
  PERFORM test.assert_empty('{testtemp, testtemp2}'::text[]);
  PERFORM test.assert_empty(ARRAY['testtemp', 'testtemp2']);
  
  -- ...and an assertion that should fail
  failed := false;
  BEGIN
    PERFORM test.assert_empty('{pg_type,pg_proc}'::text[]);
  EXCEPTION WHEN OTHERS THEN
    failed := true;
    IF SQLERRM = '[FAIL] The calls "pg_type", "pg_proc" are not empty.' THEN
      NULL;
    ELSE
      RAISE EXCEPTION 'test.assert_empty() did not raise the correct error. Raised: %', SQLERRM;
    END IF;
  END;
  IF NOT failed THEN
    PERFORM test.fail('test.assert_empty() did not fail.');
  END IF;
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_assert_not_empty() RETURNS VOID AS $$
-- Assert the correct operation of test.assert_not_empty
-- module: test_asserts
DECLARE
  failed     bool;
BEGIN
  -- Test an assertion that should pass
  CREATE TEMP TABLE testtemp AS SELECT * FROM generate_series(1, 10);
  PERFORM test.assert_not_empty('testtemp');
  -- array version
  CREATE TEMP TABLE testtemp2 AS SELECT * FROM generate_series(1, 5);
  PERFORM test.assert_not_empty('{testtemp, testtemp2}'::text[]);
  PERFORM test.assert_not_empty(ARRAY['testtemp', 'testtemp2']);
  
  -- ...and an assertion that should fail
  CREATE TEMP TABLE testtemp3 (a int);
  failed := false;
  BEGIN
    PERFORM test.assert_not_empty('testtemp3');
  EXCEPTION WHEN OTHERS THEN
    failed := true;
    IF SQLERRM = '[FAIL] The call "testtemp3" is empty.' THEN
      NULL;
    ELSE
      RAISE EXCEPTION 'test.assert_not_empty() did not raise the correct error. Raised: %', SQLERRM;
    END IF;
  END;
  IF NOT failed THEN
    PERFORM test.fail('test.assert_not_empty() did not fail.');
  END IF;
  
  RAISE EXCEPTION '[OK]';
END;
$$ LANGUAGE plpgsql;
