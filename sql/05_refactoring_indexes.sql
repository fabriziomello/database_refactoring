BEGIN;

  -- Architectural : Introduce Index
  CREATE INDEX Customer_Name_In ON Customer(Name);

  -- Architectural : Introduce Index
  CREATE INDEX Product_Description_In ON Product(Description);

  -- Architectural : Introduce Index
  CREATE INDEX City_Description_In ON City(Description);

  -- Architectural : Introduce Index
  CREATE INDEX City_State_In ON City(State);

  -- Versionamento
  INSERT INTO DatabaseConfiguration 
       VALUES (default);

COMMIT;
