/*

Epic.sql -- A framework for unit testing Postgres, especially PL/pgSQL.

The framework consists of functions to both help write tests and help run them.

Installing epic.sql
===================

Simply execute/import the epic.sql file (this file) into the database you'd
like to test:

    psql testdb
    testdb=# \i 'C:\\Python24\\Lib\\site-packages\\sql\\pgtest\\epic.sql'
    CREATE FUNCTION
     assert_test_schema
    --------------------
     t
    (1 row)

    DROP FUNCTION
    CREATE FUNCTION
    CREATE VIEW
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION

Then, execute/import any tests you've written (see below):

    testdb=# \i 'C:\\Python24\\Lib\\site-packages\\sql\\pgtest\\test_users.sql'
    SET
    CREATE FUNCTION
    testdb=# \i 'C:\\Python24\\Lib\\site-packages\\sql\\pgtest\\test_transactions.sql'
    SET
    CREATE FUNCTION
    CREATE FUNCTION


Writing tests
=============

Write tests as PL/pgSQL procedures. There are only a couple of things to do
to ensure they work well with the framework:
    
    1. ALWAYS RAISE EXCEPTION at the end of test procs to rollback! Even if
        the test passes, RAISE EXCEPTION '[OK]'. You may instead PERFORM the
        Epic functions test.pass(), test.fail(msg), test.todo(msg) and
        test.skip(msg).
    2. Put your test in the "test" schema.
    3. Start the name of your test with "test_".
        I like "test_[schema]_[target proc]" but do what you like.
    4. Include a comment of the form "-- module: [module_name]", replacing
        [module_name] with the (arbitrary) name of the "module". This can
        then be used with test.run_module().


Example test
------------

CREATE OR REPLACE FUNCTION test.test_inner_set_user_state() RETURNS VOID AS $$
-- module: test_users
DECLARE
  user_id   integer;
  user_rec  users%ROWTYPE;
BEGIN
  <<MAIN>>
  BEGIN
    -- Create dummy records
    INSERT INTO users (login_name) VALUES ('test1') RETURNING user_id INTO user_id;
    
    -- Run the proc
    PERFORM "inner".set_user_state(user_id);
    
    -- The proc MUST set users.state to 'active';
    SELECT INTO user_rec * FROM users WHERE user_id = user_id;
    PERFORM test.assert_equal(user_rec.state, 'active');
  END MAIN;

  -- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;


Assertion functions
-------------------

Epic.sql includes some functions to make tests easier to write (and shorter).
The following functions all return void, raising an exception if the assertion
doesn't hold:

    * test.assert(assertion boolean, msg text): this is the 'catch-all'
        to assert anything that can be evaluated to a boolean. For example,
        PERFORM test.assert(substring(a from b), b||" not found in "||a);
    * test.assert_void(call text)
    * test.assert_equal(elem_1 anyelement, elem_2 anyelement)
    * test.assert_not_equal(elem_1 anyelement, elem_2 anyelement)
    * test.assert_greater_than(elem_1 anyelement, elem_2 anyelement)
    * test.assert_greater_than_or_equal(elem_1 anyelement, elem_2 anyelement)
    * test.assert_less_than(elem_1 anyelement, elem_2 anyelement)
    * test.assert_less_than_or_equal(elem_1 anyelement, elem_2 anyelement)
    
    * test.assert_rows(row_1 text, row_2 text):
        Raises an exception if the SELECT statement row_1 != the SELECT statement row_2.
    * test.assert_column(call text, expected anyarray[, colname text]):
        Raises an exception if SELECT colname FROM call != expected (in order).
    
    * test.assert_raises(call text, errm text, state text): 
        Raises an exception if call does not raise errm
        (if provided) or state (if provided).


Running tests
=============

Epic includes a VIEW to manage known tests:

    testdb=# SELECT * FROM test.testnames;
                         name          |      module
    -----------------------------------+-------------------
     test_inner_trans_set_active       | test_transactions
     test_inner_trans_set_create       | test_transactions
     test_inner_count_users_by_login   | test_users
    (3 rows)

Because you made the effort to RAISE EXCEPTION even if the test passes,
it's safe to run any of these tests directly:

    testdb=# SELECT * FROM test.test_inner_trans_set_create();
    ERROR:  [OK]

However, if you'd like to run multiple tests together, use the module names
you created to group them:

    testdb=# SELECT * FROM test.run_module('test_transactions');
                         name    |      module       | result | errcode | errmsg
    -----------------------------+-------------------+--------+---------+--------
     test_inner_trans_set_active | test_transactions | [OK]   |         |
     test_inner_trans_set_create | test_transactions | [OK]   |         |
    (2 rows)

As you can see, when you use the test.run_* functions, the results are stored
in a table (called 'test.results'). If you get busy doing other things, you
can always read directly from that table to see which tests passed. Note also
that the test.run_* functions trap the [OK] and other exceptions from each test.

If you want to run all tests without regard to module:

    testdb=# SELECT * FROM test.run_all();
                         name        |      module       | result | errcode |                             errmsg
    ---------------------------------+-------------------+--------+---------+---------------------------------------------------------------
     test_inner_trans_set_active     | test_transactions | [OK]   |         |
     test_inner_trans_set_create     | test_transactions | [OK]   |         |
     test_inner_count_users_by_login | test_users        | [FAIL] | 42883   | function inner.count_users_by_login("unknown") does not exist
    (3 rows)

If you want the complete CONTEXT, etc. for the [FAIL] above, run the test
directly and you'll get the normal traceback, etc. from PL/pgSQL.

Finally, you can run any test individually via:

    testdb=# SELECT * FROM test.run_test('test_inner_trans_set_create');
                         name        |      module       | result | errcode |                             errmsg
    ---------------------------------+-------------------+--------+---------+---------------------------------------------------------------
     test_inner_trans_set_create     | test_transactions | [OK]   |         |
    (1 row)

By using run_test instead of running the test function directly, you get 
an [OK] or [FAIL] response instead of an exception. You also get an entry 
in test.results, so if you fix a single test, you can update its success 
without having to run a whole set of tests you didn't modify.

*/

CREATE OR REPLACE FUNCTION _epic_init() RETURNS boolean AS $$
DECLARE
  t        text;
BEGIN
  SET client_min_messages = warning;
  
/*  BEGIN
    RAISE EXCEPTION 'ignore me';
  EXCEPTION WHEN OTHERS THEN
    BEGIN
      t := SQLSTATE;
      t := SQLERRM;
    EXCEPTION WHEN undefined_column THEN
      -- PG 8.0 did not have SQLSTATE, SQLERRM available. Epic relies
      -- on the ability to distinguish one error from another.
      RAISE EXCEPTION 'Epic requires at least PostgreSQL version 8.1';
    END;
  END;
*/

  BEGIN
    CREATE SCHEMA test;
  EXCEPTION WHEN duplicate_schema THEN
    NULL;
  END;
  
  BEGIN
    CREATE TABLE test.results (name text PRIMARY KEY, module text,
                               result text, errcode text, errmsg text,
                               runtime timestamp with time zone default now());
  EXCEPTION WHEN duplicate_table THEN
    NULL;
  END;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM _epic_init();
DROP FUNCTION _epic_init();


CREATE OR REPLACE VIEW test.testnames AS
  SELECT pg_proc.proname AS name,
    substring(pg_proc.prosrc from E'--\\s+module[:]\\s+(\\S+)') AS module
  FROM pg_namespace LEFT JOIN pg_proc
  ON pg_proc.pronamespace::oid = pg_namespace.oid::oid
  WHERE pg_namespace.nspname = 'test'
    AND pg_proc.proname LIKE 'test_%';


CREATE OR REPLACE FUNCTION test.statement(call text) RETURNS text AS $$
-- Returns the given SQL string, prepending "SELECT * FROM " if missing.
DECLARE
  result    text;
BEGIN
  result := rtrim(call, ';');
  IF result ~* E'^[[:space:]]*(SELECT|EXECUTE)[[:space:]]' THEN
    return result;
  ELSIF result ~* E'^[[:space:]]*(VALUES)[[:space:]]*\\(' THEN
    return result;
  ELSE
    return 'SELECT * FROM ' || result;
  END IF;
END;
$$ LANGUAGE plpgsql;


-------------------------------- global records --------------------------------


CREATE OR REPLACE FUNCTION test._ensure_globals() RETURNS boolean AS $$
-- Creates the global id sequence if it does not already exist.
BEGIN
  SET client_min_messages = warning;
  
  BEGIN
    CREATE SEQUENCE test._global_ids;
  EXCEPTION WHEN duplicate_table THEN
    NULL;
  END;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM test._ensure_globals();
DROP FUNCTION test._ensure_globals();


CREATE OR REPLACE FUNCTION test.global(call text, name text) RETURNS text AS $$
-- Stores the given call's output in a TEMP table, and returns the TEMP table name.
-- 
-- 'call' can be any SELECT, table, view, or procedure that returns records.
DECLARE
  tablename      text;
  creator        text;
BEGIN
  IF name IS NULL THEN
    tablename := '_global_' || nextval('test._global_ids');
  ELSE
    tablename := name;
  END IF;
  
  BEGIN
    EXECUTE 'DROP TABLE ' || tablename;
  EXCEPTION WHEN undefined_table THEN
    NULL;
  END;
  
  creator := test.statement(call);
  EXECUTE 'CREATE TEMP TABLE ' || tablename || ' WITHOUT OIDS AS ' || creator;
  EXECUTE 'COMMENT ON TABLE ' || tablename || ' IS ' || quote_literal(creator);
  RETURN tablename;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.global(call text) RETURNS text AS $$
  SELECT global FROM test.global($1, NULL);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION test.get(p_tablename text, p_offset int) RETURNS record AS $$
-- Returns a record (the first one, by default) from the given global table.
-- 
-- The returned record includes the following additional attributes:
--   * __name__ (text): The complete name of the TEMP table. This allows you
--       to pass g.__name__ to functions that take a 'call text' argument,
--       such as assert_column, assert_values, and assert_empty (since no
--       procedural languages support passing records as args).
DECLARE
  result         record;
  rownum         int;
BEGIN
  IF p_offset IS NULL OR p_offset < 0 THEN
    rownum := 0;
  ELSE
    rownum := p_offset;
  END IF;
  
  EXECUTE 'SELECT *, NULL::text AS __name__ FROM ' || p_tablename || ' LIMIT 1 OFFSET ' || rownum INTO result;
  
  -- We add these values outside the EXECUTE in case the SELECT returned no rows.
  result.__name__ := p_tablename;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.get(p_tablename text) RETURNS record AS $$
DECLARE
  result         record;
BEGIN
  EXECUTE 'SELECT *, NULL::text AS __name__ FROM ' || p_tablename || ' LIMIT 1' INTO result;
  
  -- We add these values outside the EXECUTE in case the SELECT returned no rows.
  result.__name__ := p_tablename;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.constructor(tablename text) RETURNS text AS $$
-- Return the SQL statement used to construct the given global table.
  SELECT obj_description(pgc.oid, 'pg_class') FROM pg_class pgc WHERE relname = $1;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION test.len(tablename text) RETURNS int AS $$
-- Return the number of rows in the given table.
DECLARE
  num    int;
BEGIN
  EXECUTE 'SELECT COUNT(*) FROM ' || tablename INTO num;
  RETURN num;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.iter(tablename text) RETURNS text AS $$
-- Return SQL to retrieve all rows in the given table.
  SELECT 'SELECT * FROM ' || $1
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION test.attributes(tablename text) RETURNS SETOF pg_attribute AS $$
DECLARE
  rec      record;
  seen     int := 0;
  msg      text;
BEGIN
  FOR rec IN
    SELECT * FROM pg_attribute
    WHERE attrelid = (SELECT oid FROM pg_class WHERE relname = tablename)
    -- Exclude system columns
    AND attnum >= 1
  LOOP
    seen := seen + 1;
    RETURN NEXT rec;
  END LOOP;
  
  IF seen = 0 THEN
    msg := quote_literal(tablename);
    RAISE EXCEPTION '% has no attributes.', msg;
  END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.typename(elem anyelement) RETURNS text AS $$
-- Return the typename of the given element.
DECLARE
  name    text;
BEGIN
  CREATE TEMP TABLE _elem_type AS SELECT elem;
  SELECT INTO name pgt.typname
    FROM pg_attribute pga LEFT JOIN pg_type pgt ON pga.atttypid = pgt.oid
    WHERE pga.attrelid = (SELECT oid FROM pg_class WHERE relname = '_elem_type')
    AND pga.attnum = 1;
  DROP TABLE _elem_type;
  RETURN name;
END;
$$ LANGUAGE plpgsql;


------------------------------ Runners ------------------------------


CREATE OR REPLACE FUNCTION test.run_test(testname text) RETURNS test.results AS $$
-- Runs the named test, stores in test.results, and returns success.
DECLARE
  modulename      text;
  output_record   test.results%ROWTYPE;
  splitpoint      int;
BEGIN
  SELECT module INTO modulename FROM test.testnames WHERE name = testname;
  DELETE FROM test.results WHERE name = testname;
  
  BEGIN
    -- Allow test.* functions to be referenced without a schema name during this transaction.
    PERFORM set_config('search_path', 'test, ' || current_setting('search_path'), true);
    EXECUTE 'SELECT * FROM test.' || testname || '();' INTO output_record;
    RETURN output_record;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'P0001' AND SQLERRM LIKE '[%]%' THEN
      splitpoint := position(']' in SQLERRM);
      INSERT INTO test.results (name, module, result, errcode, errmsg)
        VALUES (testname, modulename, substr(SQLERRM, 1, splitpoint),
                CASE WHEN SQLERRM LIKE '[FAIL]%' THEN SQLSTATE ELSE '' END,
                btrim(substr(SQLERRM, splitpoint + 1)));
      SELECT INTO output_record * FROM test.results WHERE name = testname;
      RETURN output_record;
    ELSE
      INSERT INTO test.results (name, module, result, errcode, errmsg)
        VALUES (testname, modulename, '[FAIL]', SQLSTATE, SQLERRM);
      SELECT INTO output_record * FROM test.results WHERE name = testname;
      RETURN output_record;
    END IF;
  END;
  
  RAISE EXCEPTION 'Test % did not raise an exception as it should have. Exceptions must ALWAYS be raised in test procedures for rollback.', testname;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.run_module(modulename text) RETURNS SETOF test.results AS $$
-- Runs all tests in the given module, stores in test.results, and returns results.
DECLARE
  testname        record;
  output_record   test.results%ROWTYPE;
BEGIN
  FOR testname IN SELECT name FROM test.testnames WHERE module = modulename ORDER BY name ASC
  LOOP
    SELECT INTO output_record * FROM test.run_test(testname.name);
    RETURN NEXT output_record;
  END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.run_all() RETURNS SETOF test.results AS $$
-- Runs all known test functions, stores in test.results, and returns results.
DECLARE
  testname record;
  modulename record;
  output_record test.results%ROWTYPE;
BEGIN
  FOR modulename in SELECT DISTINCT module FROM test.testnames ORDER BY module ASC
  LOOP
    FOR testname IN SELECT name FROM test.testnames WHERE module = modulename.module ORDER BY name ASC
    LOOP
      SELECT INTO output_record * FROM test.run_test(testname.name);
      RETURN NEXT output_record;
    END LOOP;
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;


------------------------------ Pass/fail ------------------------------


CREATE OR REPLACE FUNCTION test.finish(result text, msg text) RETURNS VOID AS $$
-- Use this to finish a test. Raises the given result as an exception (for rollback).
DECLARE
  fullmsg        text;
BEGIN
  fullmsg := '[' || result || ']';
  IF msg IS NOT NULL THEN
    fullmsg := fullmsg || ' ' || msg;
  END IF;
  RAISE EXCEPTION '%', fullmsg;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.pass(msg text) RETURNS VOID AS $$
-- Use this to finish a successful test. Raises exception '[OK] msg'.
BEGIN
  PERFORM test.finish('OK', msg);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION test.pass() RETURNS VOID AS $$
-- Use this to finish a successful test. Raises exception '[OK]'.
BEGIN
  PERFORM test.finish('OK', NULL);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.fail(msg text) RETURNS VOID AS $$
-- Use this to finish a failed test. Raises exception '[FAIL] msg'.
BEGIN
  PERFORM test.finish('FAIL', msg);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION test.fail() RETURNS VOID AS $$
-- Use this to finish a failed test. Raises exception '[FAIL]'.
BEGIN
  PERFORM test.finish('FAIL', NULL);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.todo(msg text) RETURNS VOID AS $$
-- Use this to abort a test as 'todo'. Raises exception '[TODO] msg'.
BEGIN
  PERFORM test.finish('TODO', msg);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION test.todo() RETURNS VOID AS $$
-- Use this to abort a test as 'todo'. Raises exception '[TODO]'.
BEGIN
  PERFORM test.finish('TODO', NULL);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.skip(msg text) RETURNS VOID AS $$
-- Use this to skip a test. Raises exception '[SKIP] msg'.
BEGIN
  PERFORM test.finish('SKIP', msg);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION test.skip() RETURNS VOID AS $$
-- Use this to skip a test. Raises exception '[SKIP]'.
BEGIN
  PERFORM test.finish('SKIP', NULL);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


------------------------------ Assertions ------------------------------


CREATE OR REPLACE FUNCTION test.assert_void(call text) RETURNS VOID AS $$
-- Raises an exception if SELECT * FROM call != void.
DECLARE
  retval    text;
BEGIN
  EXECUTE test.statement(call) INTO retval;
  IF retval != '' THEN
    RAISE EXCEPTION 'Call: ''%'' did not return void. Got ''%'' instead.', call, retval;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.assert(assertion boolean, msg text) RETURNS VOID AS $$
-- Raises an exception (msg) if assertion is false.
-- 
-- assertion may not be NULL.
BEGIN
  IF assertion IS NULL THEN
    RAISE EXCEPTION 'Assertion test may not be NULL.';
  END IF;
  
  IF NOT assertion THEN
    RAISE EXCEPTION '%', msg;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.assert_equal(elem_1 anyelement, elem_2 anyelement) RETURNS VOID AS $$
-- Raises an exception if elem_1 is not equal to elem_2.
-- 
-- The two arguments must be of the same type. If they are not,
-- you will receive "ERROR:  invalid input syntax ..."
BEGIN
  IF ((elem_1 IS NULL AND NOT (elem_2 IS NULL)) OR
      (elem_2 IS NULL AND NOT (elem_1 IS NULL)) OR
      elem_1 != elem_2) THEN
    RAISE EXCEPTION '% != %', elem_1, elem_2;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.assert_not_equal(elem_1 anyelement, elem_2 anyelement) RETURNS VOID AS $$
-- Raises an exception if elem_1 is equal to elem_2
-- 
-- The two arguments must be of the same type. If they are not,
-- you will receive "ERROR:  invalid input syntax ..."
BEGIN
  IF ((elem_1 IS NULL AND elem_2 IS NULL) OR elem_1 = elem_2) THEN
    RAISE EXCEPTION '% = %', elem_1, elem_2;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.assert_less_than(elem_1 anyelement, elem_2 anyelement) RETURNS VOID AS $$
-- Raises an exception if elem_1 >= elem_2
-- 
-- The two arguments must be of the same type. If they are not,
-- you will receive "ERROR:  invalid input syntax ..."
BEGIN
  IF (elem_1 IS NULL or elem_2 IS NULL) THEN
    RAISE EXCEPTION 'Assertion arguments may not be NULL.';
  END IF;
  IF NOT (elem_1 < elem_2) THEN
    RAISE EXCEPTION '% not < %', elem_1, elem_2;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.assert_less_than_or_equal(elem_1 anyelement, elem_2 anyelement) RETURNS VOID AS $$
-- Raises an exception if elem_1 > elem_2
-- 
-- The two arguments must be of the same type. If they are not,
-- you will receive "ERROR:  invalid input syntax ..."
BEGIN
  IF (elem_1 IS NULL or elem_2 IS NULL) THEN
    RAISE EXCEPTION 'Assertion arguments may not be NULL.';
  END IF;
  IF NOT (elem_1 <= elem_2) THEN
    RAISE EXCEPTION '% not <= %', elem_1, elem_2;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.assert_greater_than(elem_1 anyelement, elem_2 anyelement) RETURNS VOID AS $$
-- Raises an exception if elem_1 <= elem_2
-- 
-- The two arguments must be of the same type. If they are not,
-- you will receive "ERROR:  invalid input syntax ..."
BEGIN
  IF (elem_1 IS NULL or elem_2 IS NULL) THEN
    RAISE EXCEPTION 'Assertion arguments may not be NULL.';
  END IF;
  IF NOT (elem_1 > elem_2) THEN
    RAISE EXCEPTION '% not > %', elem_1, elem_2;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.assert_greater_than_or_equal(elem_1 anyelement, elem_2 anyelement) RETURNS VOID AS $$
-- Raises an exception if elem_1 < elem_2
-- 
-- The two arguments must be of the same type. If they are not,
-- you will receive "ERROR:  invalid input syntax ..."
BEGIN
  IF (elem_1 IS NULL or elem_2 IS NULL) THEN
    RAISE EXCEPTION 'Assertion arguments may not be NULL.';
  END IF;
  IF NOT (elem_1 >= elem_2) THEN
    RAISE EXCEPTION '% not >= %', elem_1, elem_2;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION test.assert_raises(call text, errm text, state text) RETURNS VOID AS $$
-- Raises an exception if call does not raise errm and/or state.
-- 
-- Example:
--
--    PERFORM test.assert_raises('get_transaction_by_id(''a'')', 'Bad argument', NULL);
--
-- If errm or state are NULL, that value will not be tested. This allows
-- you to test by message alone (since the 5-char SQLSTATE values are cryptic),
-- or trap a range of errors by SQLSTATE without regard for the exact message.
-- 
-- If you don't know the message you want to trap, call this function with
-- errm = '' and state = ''. The resultant error will tell you the
-- SQLSTATE and SQLERRM that were raised.
DECLARE
  msg       text;
BEGIN
  BEGIN
    EXECUTE test.statement(call);
  EXCEPTION
    WHEN OTHERS THEN
      IF ((state IS NOT NULL AND SQLSTATE != state) OR
          (errm IS NOT NULL AND SQLERRM != errm)) THEN
        msg = 'Call: ''' || call || ''' raised ''(' || SQLSTATE || ') ' || SQLERRM || ''' instead of ''(' || state || ') ' || errm || '''.';
        RAISE EXCEPTION '%', msg;
      END IF;
      RETURN;
  END;
  msg := 'Call: ' || quote_literal(call) || ' did not raise an error.';
  RAISE EXCEPTION '%', msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.assert_raises(call text, errm text) RETURNS VOID AS $$
-- Implicit state version of assert_raises
BEGIN
  PERFORM test.assert_raises(call, errm, NULL);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.assert_raises(call text) RETURNS VOID AS $$
-- Implicit errm, column version of assert_raises
BEGIN
  PERFORM test.assert_raises(call, NULL, NULL);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.assert_rows(call_1 text, call_2 text) RETURNS VOID AS $$
-- Asserts that two sets of rows have equal values.
--
-- Both arguments should be SELECT statements yielding a single row or a set of rows.
-- Either may also be any table, view, or procedure call that returns records.
-- It is also common for the second arg to be sans a FROM clause, and simply SELECT values.
-- Neither source nor expected need to be sorted. Either may include a trailing semicolon.
--
-- Example:
-- 
--    PERFORM test.assert_rows('SELECT first, last, city FROM table1',
--                             'SELECT ''Davy'', ''Crockett'', NULL');
DECLARE
  rec     record;
  s       text;
  e       text;
  msg     text;
BEGIN
  s := test.statement(call_1);
  e := test.statement(call_2);
  
  FOR rec in EXECUTE s || ' EXCEPT ' || e
  LOOP
    RAISE EXCEPTION 'Record: % from: % not found in: %', rec, call_1, call_2;
  END LOOP;
  
  FOR rec in EXECUTE e || ' EXCEPT ' || s
  LOOP
    RAISE EXCEPTION 'Record: % from: % not found in: %', rec, call_2, call_1;
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.assert_column(call text, expected anyarray, colname text) RETURNS VOID AS $$
-- Raises an exception if SELECT colname FROM call != expected (in order).
--
-- If colname is NULL or omitted, the first column of call's output will be used.
--
-- 'call' can be any table, view, or procedure that returns records.
-- 'expected' MUST be an array of the same type as colname. If necessary, cast it using :: to avoid
-- the error 'type of "record1._assert_column_result" does not match that when preparing the plan'.
-- TODO: can this function detect the type and cast it for the user?
-- 
-- Example:
--    PERFORM test.assert_column(
--      'get_favorite_user_ids(' || user_id || ');',
--      ARRAY[24, 10074, 87321], 'user_id');
-- 
DECLARE
  record1       record;
  record2       record;
  curs_base     refcursor;
  curs_expected refcursor;
  firstname     text;
  found_1       boolean;
  lower_bound   int;
  base_type     text;
  msg           text;
BEGIN
  -- Dump the call output into a temp table
  IF colname IS NULL THEN
    -- No colname; instead, create the temp table and then read the catalog
    -- to grab the name of the first column.
    EXECUTE 'CREATE TEMPORARY TABLE _test_assert_column_base AS ' || test.statement(call);
    SELECT INTO firstname a.attname
      FROM pg_class c LEFT JOIN pg_attribute a ON c.oid = a.attrelid
      WHERE c.relname = '_test_assert_column_base'
      -- "The number of the column. Ordinary columns are numbered from 1 up.
      -- System columns, such as oid, have (arbitrary) negative numbers"
      AND a.attnum >= 1
      ORDER BY a.attnum;
    EXECUTE 'ALTER TABLE _test_assert_column_base RENAME ' || firstname || ' TO _assert_column_result;';
  ELSE
    EXECUTE 'CREATE TEMPORARY TABLE _test_assert_column_base AS ' ||
      'SELECT ' || colname || ' AS _assert_column_result FROM ' || call || ';';
  END IF;
  SELECT INTO base_type pgt.typname
    FROM pg_attribute pga LEFT JOIN pg_type pgt ON pga.atttypid = pgt.oid
    WHERE pga.attrelid = (SELECT oid FROM pg_class WHERE relname = '_test_assert_column_base')
    AND pga.attnum = 1;
  -- Casting to ::name doesn't work so well.
  IF base_type = 'name' THEN
    base_type := 'text';
  END IF;
  
  -- Dump the provided array into a temp table
  -- Use EXECUTE for all statements involving this table so its query plan
  -- doesn't get cached and re-used (or subsequent calls will fail).
  EXECUTE 'CREATE TEMPORARY TABLE _test_assert_column_expected (LIKE _test_assert_column_base);';
  lower_bound = array_lower(expected, 1);
  IF lower_bound iS NOT NULL THEN
    FOR i IN lower_bound..array_upper(expected, 1)
    LOOP
      IF expected[i] IS NULL THEN
        EXECUTE 'INSERT INTO _test_assert_column_expected (_assert_column_result) VALUES (NULL);';
      ELSEIF base_type IN ('text', 'varchar', 'char', 'bytea', 'date', 'timestamp', 'timestamptz', 'time', 'timetz') THEN
        EXECUTE 'INSERT INTO _test_assert_column_expected (_assert_column_result) VALUES ('
                || quote_literal(expected[i]) || ');';
      ELSE
        EXECUTE 'INSERT INTO _test_assert_column_expected (_assert_column_result) VALUES ('
                || expected[i] || ');';
      END IF;
    END LOOP;
  END IF;
  
  -- Compare the two tables in order.
  <<TRY>>
  BEGIN
    OPEN curs_base FOR EXECUTE 'SELECT * FROM _test_assert_column_base';
    OPEN curs_expected FOR EXECUTE 'SELECT * FROM _test_assert_column_expected';
    LOOP
      FETCH curs_base INTO record1;
      found_1 := FOUND;
      FETCH curs_expected INTO record2;
      IF FOUND THEN
        IF NOT found_1 THEN
          PERFORM test.fail('element: ' || record2._assert_column_result || ' not found in call: ' || call);
        END IF;
      ELSE
        IF NOT found_1 THEN
          EXIT;
        ELSE
          PERFORM test.fail('record: ' || record1._assert_column_result || ' not found in array: ' || array_to_string(expected, ', '));
        END IF;
      END IF;
      PERFORM test.assert_equal(record1._assert_column_result, record2._assert_column_result);
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    DROP TABLE _test_assert_column_base;
    EXECUTE 'DROP TABLE _test_assert_column_expected';
    msg := SQLERRM;
    RAISE EXCEPTION '%', msg;
  END;
  
  CLOSE curs_base;
  CLOSE curs_expected;
  DROP TABLE _test_assert_column_base;
  EXECUTE 'DROP TABLE _test_assert_column_expected';
  RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.assert_column(call text, expected anyarray) RETURNS VOID AS $$
-- Implicit column version of assert_column
BEGIN
  PERFORM test.assert_column(call, expected, NULL);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.assert_values(call_1 text, call_2 text, columns text) RETURNS VOID AS $$
-- Raises an exception if SELECT columns FROM call_1 != SELECT columns FROM call_2.
--
-- Example:
--    row_1 := obj('get_favorite_user_ids(' || user_id || ')')
--    PERFORM test.assert_equal(row_1.object, 'users WHERE user_id = 355', 'last_name');
--
BEGIN
  PERFORM test.assert_rows(
    'SELECT ' || columns || ' FROM ' || call_1,
    'SELECT ' || columns || ' FROM ' || call_2
    );
  RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.assert_empty(calls text[]) RETURNS VOID AS $$
-- Raises an exception if the given calls have any rows.
DECLARE
  result      bool;
  failed      text[] DEFAULT '{}'::text[];
  failed_len  int;
BEGIN
  IF array_lower(calls, 1) IS NOT NULL THEN
    FOR i in array_lower(calls, 1)..array_upper(calls, 1)
    LOOP
      EXECUTE 'SELECT EXISTS (' || test.statement(calls[i]) || ');' INTO result;
      IF result THEN
        failed := failed || ('"' || btrim(calls[i]) || '"');
      END IF;
    END LOOP;
  END IF;
  
  IF array_lower(failed, 1) IS NOT NULL THEN
    failed_len := (array_upper(failed, 1) - array_lower(failed, 1)) + 1;
    IF failed_len = 1 THEN
      PERFORM test.fail('The call ' || array_to_string(failed, ', ') || ' is not empty.');
    ELSEIF failed_len > 1 THEN
      PERFORM test.fail('The calls ' || array_to_string(failed, ', ') || ' are not empty.');
    END IF;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.assert_empty(call text) RETURNS VOID AS $$
-- Raises an exception if the given call returns any rows.
DECLARE
  result    bool;
BEGIN
  EXECUTE 'SELECT EXISTS (' || test.statement(call) || ');' INTO result;
  IF result THEN
    PERFORM test.fail('The call "' || call || '" is not empty.');
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.assert_not_empty(calls text[]) RETURNS VOID AS $$
-- Raises an exception if the given calls have no rows.
DECLARE
  result      bool;
  failed      text[];
  failed_len  int;
BEGIN
  IF array_lower(calls, 1) IS NOT NULL THEN
    FOR i in array_lower(calls, 1)..array_upper(calls, 1)
    LOOP
      EXECUTE 'SELECT EXISTS (' || test.statement(calls[i]) || ');' INTO result;
      IF NOT result THEN
        failed := failed || ('"' || btrim(calls[i]) || '"');
      END IF;
    END LOOP;
  END IF;
  
  IF array_lower(failed, 1) IS NULL THEN
    -- failed is an empty array (no failures).
    NULL;
  ELSE
    failed_len := (array_upper(failed, 1) - array_lower(failed, 1)) + 1;
    IF failed_len = 1 THEN
      PERFORM test.fail('The call ' || array_to_string(failed, ', ') || ' is empty.');
    ELSEIF failed_len > 1 THEN
      PERFORM test.fail('The calls ' || array_to_string(failed, ', ') || ' are empty.');
    END IF;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.assert_not_empty(call text) RETURNS VOID AS $$
-- Raises an exception if the given table has no rows.
DECLARE
  result    bool;
BEGIN
  EXECUTE 'SELECT EXISTS (' || test.statement(call) || ');' INTO result;
  IF NOT result THEN
    PERFORM test.fail('The call "' || call || '" is empty.');
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.timing(call text, number int) RETURNS interval AS $$
-- Return an interval encompassing 'number' runs of the given call.
-- If 'number' is NULL or omitted, it defaults to 1000000.
DECLARE
  v_call   text;
  v_number int;
  start    timestamp with time zone;
BEGIN
  v_call := test.statement(call);
  v_number := number;
  IF number IS NULL THEN v_number := 1000000; END IF;
  -- Mustn't use now() here since that value is fixed for the entire transaction.
  -- Also, clock_timestamp isn't available until 8.2 so we use timeofday instead.
  start := timeofday()::timestamp;
  FOR i IN 1..v_number
  LOOP
    EXECUTE v_call;
  END LOOP;
  -- We grab the total clock time outside the loop. It's a toss-up whether the loop
  -- overhead outweighs assignment overhead if we accumulated the time inside the loop;
  -- therefore I chose "outside" since it makes the whole run faster. ;)
  RETURN (timeofday()::timestamp - start);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.timing(call text) RETURNS interval AS $$
-- Return an interval encompassing 1,000 runs of the given call.
BEGIN
  RETURN test.timing(call, NULL);
END;
$$ LANGUAGE plpgsql;
