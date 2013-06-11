-- Tests for the 'global' function which Epic provides.
-- To run, execute epic.sql, then this script, then test.run_module('test_globals').

CREATE OR REPLACE FUNCTION test._test_global() RETURNS VOID AS $$
DECLARE
  g      text;
  g2     text;
  rec    record;
  trec   record;
BEGIN
  g := global('pg_namespace WHERE nspname = ''test'';');
  
  -- The returned string MUST be the name of the TEMP table.
  PERFORM test.assert(g LIKE E'\_global\_%', g || ' not like _global');
  
  rec := get(g);
  
  -- The result of get() should be a normal record.
  PERFORM test.assert_equal(rec.nspname, 'test');
  
  -- The returned record MUST possess a .__name__ attribute.
  PERFORM test.assert(rec.__name__ LIKE E'\_global\_%', rec.__name__ || ' not like _global');
  
  -- The global MUST reference a temporary table with the same fields.
  EXECUTE 'SELECT * FROM ' || g INTO trec;
  PERFORM test.assert_equal(trec.nspname, 'test');
  PERFORM test.assert_equal(trec.nspowner, rec.nspowner);
  PERFORM test.assert_equal(trec.nspacl, rec.nspacl);
  
  -- The TEMP table MUST possess its own constructor SQL string in a COMMENT
  PERFORM test.assert_equal(constructor(g), 'SELECT * FROM pg_namespace WHERE nspname = ''test''');
  
  -- Test the iter() function.
  g2 := global('iter(''' || g || ''')');
  PERFORM test.assert_not_empty(g2);
  
  -- Test the attributes() function.
  PERFORM test.assert_column('SELECT attname FROM attributes(''' || g || ''')',
                             ARRAY['nspname', 'nspowner', 'nspacl']);
  
  -- Test the len() function.
  PERFORM test.assert_equal(len(g), 1);
  
  -- Raise an exception to test deletion of the TEMP table ON COMMIT
  RAISE EXCEPTION '%', g;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_global() RETURNS VOID AS $$
-- module: test_globals
DECLARE
  rec    record;
BEGIN
  BEGIN
    PERFORM test._test_global();
  EXCEPTION WHEN raise_exception THEN
    -- The table, since temporary, MUST be DROP'ed on rollback.
    BEGIN
      EXECUTE 'SELECT * FROM ' || SQLERRM INTO rec;
    EXCEPTION WHEN undefined_table THEN
      NULL;
    END;
  END;
  
  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;