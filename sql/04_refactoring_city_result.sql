BEGIN;

  -- Apaga trigger de Sincronizacao pois Periodo de Transicao acabou
  DROP FUNCTION IF EXISTS SyncCustomerCity() CASCADE;

  -- Apaga Foreign Key
  -- Referential Integrity : Drop Foreign Key Constraint
  ALTER TABLE Customer DROP CONSTRAINT Customer_City_Fk;

  -- Algumas tarefas:
  --  1. Remover antiga coluna City VARCHAR(40)
  --  2. Renomear coluna City_Code para City

  -- 1. Structural : Drop Column
  ALTER TABLE Customer DROP COLUMN City;

  -- 2. Structural : Rename Column (Para esse refactoring será necessário outros)

  -- 2.1. Transformation : Introduce New Column
  ALTER TABLE Customer ADD City INTEGER;

  -- 2.2. Transformation : Update Data
  UPDATE Customer SET City = City_Code;

  -- 2.3. Structural : Drop Column
  ALTER TABLE Customer DROP COLUMN City_Code CASCADE;

  -- 2.4. Referencial Integrity : Add Foreign Key Constraint
  ALTER TABLE Customer 
          ADD CONSTRAINT Customer_City_Fk
  FOREIGN KEY (City)
   REFERENCES City(Code);

  -- 2.5 Architectural : Introduce Index
  CREATE INDEX Customer_City_In ON Customer(City);


  -- Versionamento
  INSERT INTO DatabaseConfiguration 
       VALUES (default);

COMMIT;
