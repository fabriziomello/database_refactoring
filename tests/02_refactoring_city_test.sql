--
-- ATENCAO: Teste deve ser ajustado após período de transição
--
CREATE OR REPLACE FUNCTION test.test_city() RETURNS VOID AS $$
-- module: city
DECLARE
  rRecord customer%ROWTYPE;
BEGIN

  -- Create dummy records
  INSERT INTO
     Customer (name, phone, address, age, photo, city)
       VALUES ('Test Customer', '1234567890', 'Test Address', 0, 'images/photos/test_customer.png', 'Test city');

  PERFORM test.assert_not_empty(E'SELECT * FROM City WHERE description = \'TEST CITY\'');

  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;


SELECT * FROM test.run_all();
