BEGIN;

  -- Data Quality : Add Lookup Table
  CREATE TABLE City (
    Code INTEGER NOT NULL,
    Description CHARACTER VARYING(40),
    State CHARACTER(2)
  );

  CREATE SEQUENCE City_Code_Seq;

  ALTER SEQUENCE City_Code_Seq OWNED BY City.Code;

  ALTER TABLE City ALTER COLUMN Code SET DEFAULT nextval('city_code_seq'::regclass);

  ALTER TABLE ONLY City ADD CONSTRAINT City_Pk PRIMARY KEY (Code);


  -- Transformation : Introduce New Column
  ALTER TABLE Customer ADD City_Code INTEGER;


  -- Referential Integrity : Add Foreign Key Constraint
  ALTER TABLE Customer 
          ADD CONSTRAINT Customer_City_Fk 
  FOREIGN KEY (City_Code) 
   REFERENCES City(Code);

  -- Architectural : Introduce Index
  CREATE INDEX Customer_City_In ON Customer(City_Code);

  -- Stored Function para Sincronizar os Dados (AFTER INSERT OR UPDATE)
  CREATE OR REPLACE FUNCTION SyncCustomerCity() RETURNS trigger AS
  $$
  DECLARE
    iCodeCity INTEGER;
  BEGIN

    -- Todo: Aplicar funções para melhorar qualidade do dado do nome da cidade
    SELECT Code
      INTO iCodeCity
      FROM City
     WHERE upper(trim(City.Description)) = upper(trim(NEW.City));

    IF NOT FOUND THEN
      iCodeCity := nextval('city_code_seq');
      INSERT INTO City(code, description, state)
           VALUES (iCodeCity, upper(trim(NEW.City)), 'NI');
    END IF;

    NEW.City_Code := iCodeCity;

    RETURN NEW;
  END;
  $$
  LANGUAGE plpgsql;

  -- Trigger para Periodo de Transicao 
  CREATE TRIGGER "TriggerSyncCustomerCity" BEFORE INSERT OR UPDATE ON Customer FOR EACH ROW EXECUTE PROCEDURE SyncCustomerCity();

  COMMENT ON TRIGGER "TriggerSyncCustomerCity" ON Customer IS 'Sincronizacao do Cadastro de Cidades {drop date = 31/12/2010}' ;

  -- Ajustar dados tabela Customer
  -- Transformation : Update Data
  UPDATE Customer
     SET City_Code = NULL;


  -- Dados de Teste
  /*INSERT INTO Customer (Name, Phone, Address, Age, Photo, City) 
       VALUES ('Noname1', '51 3333-2222', 'Av. Noname', 99, '', 'Canoas');
  INSERT INTO Customer (Name, Phone, Address, Age, Photo, City) 
       VALUES ('Noname2', '51 3333-2222', 'Av. Noname', 99, '', 'Canoas');
  INSERT INTO Customer (Name, Phone, Address, Age, Photo, City) 
       VALUES ('Noname3', '51 3333-2222', 'Av. Noname', 99, '', 'Canoas');
  INSERT INTO Customer (Name, Phone, Address, Age, Photo, City) 
       VALUES ('Noname4', '51 3333-2222', 'Av. Noname', 99, '', 'PORTO ALEGRE');
  INSERT INTO Customer (Name, Phone, Address, Age, Photo, City) 
       VALUES ('Noname5', '51 3333-2222', 'Av. Noname', 99, '', 'Porto Alegre');*/

  -- Versionamento
  INSERT INTO DatabaseConfiguration 
       VALUES (default);

COMMIT;
