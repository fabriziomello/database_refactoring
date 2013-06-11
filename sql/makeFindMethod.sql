CREATE OR REPLACE FUNCTION makeFindMethod(sSchema TEXT, sTable TEXT) RETURNS BOOLEAN AS
$$
DECLARE
  sFunctionCreate    TEXT;
  sFunctionDrop      TEXT;
  sFunctionSignature TEXT;

  sTableName         TEXT;
  sTableString       TEXT;

  sExpression        TEXT;
  sRecordTable       TEXT;

  sEOL               TEXT    DEFAULT E'\n';

  rFields            RECORD;

  lReturn            BOOLEAN DEFAULT true;
BEGIN

  sTableName   := quote_ident(sSchema)||'.'||quote_ident(sTable);
  sTableString := sSchema || '_' || sTable;
  sRecordTable := 'r' || sTableString;

  sFunctionSignature := 'find_' || sTableString || '_By_Template(rTemplate ' || sTableName || ', sOperator TEXT)';

  sFunctionDrop := 'DROP FUNCTION IF EXISTS ' || sFunctionSignature || ';';

  sFunctionCreate :=                    'CREATE OR REPLACE FUNCTION ' || sFunctionSignature || sEOL;
  sFunctionCreate := sFunctionCreate || 'RETURNS SETOF ' || sTableName || sEOL;
  sFunctionCreate := sFunctionCreate || 'AS'  || sEOL;
  sFunctionCreate := sFunctionCreate || E'\$\$' || sEOL;
  sFunctionCreate := sFunctionCreate || 'DECLARE' || sEOL;
  sFunctionCreate := sFunctionCreate || '  sQuery TEXT DEFAULT ' || quote_literal('SELECT * FROM ' || sTableName || ' ') || ';' || sEOL;
  sFunctionCreate := sFunctionCreate || '  sWhere TEXT DEFAULT ' || quote_literal('WHERE ') || ';' || sEOL;
  sFunctionCreate := sFunctionCreate || '  sOpe   TEXT DEFAULT ' || quote_literal('') || ';' || sEOL;
  sFunctionCreate := sFunctionCreate || '  r' || sTableString || ' ' || sTableName || '%ROWTYPE;' || sEOL;
  sFunctionCreate := sFunctionCreate || 'BEGIN' || sEOL;

  FOR rFields IN 
    SELECT column_name,
           upper(udt_name) as udt_name
      FROM information_schema.columns 
     WHERE table_schema = sSchema 
       AND table_name   = sTable
  LOOP

    IF rFields.udt_name IN ('VARCHAR', 'BPCHAR') THEN
      sExpression := quote_literal(rFields.column_name || ' = ') || ' || quote_literal(rTemplate.' || quote_ident(rFields.column_name) ||');';
    ELSE
      sExpression := quote_literal(rFields.column_name || ' = ') || ' || CAST(rTemplate.' || quote_ident(rFields.column_name) || ' AS TEXT);';
    END IF;

    sFunctionCreate := sFunctionCreate || '  IF rTemplate.' || quote_ident(rFields.column_name) || ' IS NOT NULL THEN' || sEOL;
    sFunctionCreate := sFunctionCreate || '    sQuery := sQuery || sWhere || sOpe || ' || sExpression || sEOL;
    sFunctionCreate := sFunctionCreate || '    sWhere := '''';' || sEOL;
    sFunctionCreate := sFunctionCreate || '    sOpe   := '' ''||sOperator||'' '';' || sEOL;
    sFunctionCreate := sFunctionCreate || '  END IF;' || sEOL;
   
  END LOOP;

  sFunctionCreate := sFunctionCreate || '  FOR ' || sRecordTable || ' IN EXECUTE sQuery' || sEOL;
  sFunctionCreate := sFunctionCreate || '  LOOP' || sEOL;
  sFunctionCreate := sFunctionCreate || '    RETURN NEXT ' || sRecordTable || ';' || sEOL;
  sFunctionCreate := sFunctionCreate || '  END LOOP;' || sEOL || sEOL;
  sFunctionCreate := sFunctionCreate || '  RETURN;' || sEOL;
  sFunctionCreate := sFunctionCreate || 'END;' || sEOL;
  sFunctionCreate := sFunctionCreate || E'\$\$' || sEOL;
  sFunctionCreate := sFunctionCreate || 'LANGUAGE plpgsql;';

  BEGIN
    EXECUTE sFunctionDrop;
    EXECUTE sFunctionCreate;
  EXCEPTION
    WHEN others THEN
      RAISE INFO '% - %', SQLSTATE, SQLERRM;
      lReturn := false;
  END;

  RETURN lReturn;
END;
$$
LANGUAGE plpgsql;
