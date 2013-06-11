
DROP FUNCTION IF EXISTS find_City_By_Code(INTEGER);

CREATE OR REPLACE FUNCTION find_City_By_Code(INTEGER) RETURNS SETOF City AS
$$
  SELECT *
    FROM City
   WHERE City.Code = $1;
$$
LANGUAGE sql;


DROP FUNCTION IF EXISTS find_City_By_Template(public.City, TEXT);

CREATE OR REPLACE FUNCTION find_City_By_Template(rTemplate public.City, sOperator TEXT) RETURNS SETOF public.City AS
$$
DECLARE
  sQuery TEXT DEFAULT 'SELECT * FROM City ';
  sWhere TEXT DEFAULT 'WHERE';
  sOpe   TEXT DEFAULT '';

  rCity  City%ROWTYPE;
BEGIN

  IF rTemplate.Code IS NOT NULL THEN
    sQuery := sQuery || sWhere || ' Code = ' || CAST(rTemplate.Code AS TEXT) || ' ' || sOpe;
    sWhere := '';
    sOpe   := sOperator;
  END IF;

  IF rTemplate.Description IS NOT NULL THEN
    sQuery := sQuery || sWhere || sOpe || ' Description = ' || quote_literal(rTemplate.Description);
    sWhere := '';
    sOpe   := sOperator;
  END IF;
  
  IF rTemplate.State IS NOT NULL THEN
    sQuery := sQuery || sWhere || sOpe || ' State = ' || quote_literal(rTemplate.State);
    sWhere := '';
    sOpe   := sOperator;
  END IF;

  FOR rCity IN EXECUTE sQuery
  LOOP
    RETURN NEXT rCity;
  END LOOP;

  RETURN; 
END;
$$
LANGUAGE plpgsql;
