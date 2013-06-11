BEGIN;

  -- Popular Customer com Dados Inexistentes
  -- Transformation : Insert Data
  INSERT INTO Customer
       SELECT DISTINCT
              Sales.Customer,
              '(CustomerMigration: '||CAST(Sales.Customer AS TEXT)||')',
              '99 9999-9999', 
              '(AddressMigration: '||CAST(Sales.Customer AS TEXT)||')', 
              0, 
              '', 
              '(CityMigration)' 
         FROM Sales 
              LEFT JOIN Customer ON Customer.Code = Sales.Customer 
        WHERE Customer.Code IS NULL;

  -- Referential Integrity : Add Foreign Key Constraint
  ALTER TABLE Sales 
          ADD CONSTRAINT Sales_Customer_Fk 
  FOREIGN KEY (Customer) 
   REFERENCES Customer(Code);

  -- Architectural : Introduce Index
  CREATE INDEX Sales_Customer_In ON Sales(Customer);

  -- Popular Product com Dados Inexistentes
  -- Transformation : Insert Data
  INSERT INTO Product
       SELECT DISTINCT
              Sales.Product,
              '(ProductMigration: '||CAST(Sales.Product AS TEXT)||')',
              'NI', 
              0, 
              0, 
              0 
         FROM Sales 
              LEFT JOIN Product ON Product.Code = Sales.Product 
        WHERE Product.Code IS NULL;

  -- Referential Integrity : Add Foreign Key Constraint
  ALTER TABLE Sales 
          ADD CONSTRAINT Sales_Product_Fk 
  FOREIGN KEY (Product) 
   REFERENCES Product(Code);

  -- Architectural : Introduce Index
  CREATE INDEX Sales_Product_In ON Sales(Product);

  -- Versionamento
  INSERT INTO DatabaseConfiguration 
       VALUES (default);

COMMIT;
