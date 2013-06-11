CREATE OR REPLACE FUNCTION test.test_customer() RETURNS VOID AS $$
-- module: customer
DECLARE
  rRecord RECORD;
BEGIN
  <<MAIN>>
  BEGIN

    -- Create dummy records
    INSERT INTO
      Customer (name, phone, address, age, photo, city)
        VALUES ('Test Customer', '1234567890', 'Test Address', 0, 'images/photos/test_customer.png', 'Test city');

    SELECT *
      INTO rRecord
      FROM Customer
     WHERE code = CURRVAL('customer_code_seq');

    PERFORM test.assert_equal(rRecord.name,    'Test Customer');
    PERFORM test.assert_equal(rRecord.phone,   '1234567890');
    PERFORM test.assert_equal(rRecord.address, 'Test Address');
    PERFORM test.assert_equal(rRecord.age,     0);
    PERFORM test.assert_equal(rRecord.photo,   'images/photos/test_customer.png');
    PERFORM test.assert_equal(rRecord.city,    'Test city');

  END MAIN;

  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_product() RETURNS VOID AS $$
-- module: product
DECLARE
  rRecord RECORD;

  nAmount     NUMERIC(14,2) DEFAULT 100;
  nCost       NUMERIC(14,2) DEFAULT 1;
  nSell_Price NUMERIC(14,2) DEFAULT 2;
BEGIN
  <<MAIN>>
  BEGIN

    -- Create dummy records
    INSERT INTO
       Product (description, unit, amount, cost, sell_price)
        VALUES ('Test Product', 'UN', 100, 1, 2);

    SELECT *
      INTO rRecord
      FROM Product
     WHERE code = CURRVAL('product_code_seq');

    PERFORM test.assert_equal(rRecord.description, 'Test Product');
    PERFORM test.assert_equal(rRecord.unit,        'UN');
    PERFORM test.assert_equal(rRecord.amount,      nAmount);
    PERFORM test.assert_equal(rRecord.cost,        nCost);
    PERFORM test.assert_equal(rRecord.sell_price,  nSell_Price);

    UPDATE Product
       SET amount = amount - 10
     WHERE code = CURRVAL('product_code_seq');

    SELECT *
      INTO rRecord
      FROM Product
     WHERE code = CURRVAL('product_code_seq');

    PERFORM test.assert_equal(rRecord.amount,      (nAmount-10));

  END MAIN;

  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_sales() RETURNS VOID AS $$
-- module: sales
DECLARE
  rRecord RECORD;

  nAmount     NUMERIC(14,2) DEFAULT 10;
  nPrice      NUMERIC(14,2) DEFAULT 20;
BEGIN
  <<MAIN>>
  BEGIN

    -- Create dummy records
    INSERT INTO
        Product (description, unit, amount, cost, sell_price)
         VALUES ('Test Product', 'UN', 100, 1, 2);

    INSERT INTO
       Customer (name, phone, address, age, photo, city)
         VALUES ('Test Customer', '1234567890', 'Test Address', 0, 'images/photos/test_customer.png', 'Test city');

    INSERT INTO
          Sales (customer, product, date_sale, amount, price)
         VALUES (currval('customer_code_seq'), currval('product_code_seq'), current_date, nAmount, nPrice);

    SELECT *
      INTO rRecord
      FROM Sales
     WHERE code = CURRVAL('sales_code_seq');

    PERFORM test.assert_equal(rRecord.customer,  CAST(currval('customer_code_seq') AS integer));
    PERFORM test.assert_equal(rRecord.product,   CAST(currval('product_code_seq')  AS integer));
    PERFORM test.assert_equal(rRecord.date_sale, current_date);
    PERFORM test.assert_equal(rRecord.amount,    nAmount);
    PERFORM test.assert_equal(rRecord.price,     nPrice);

    PERFORM test.assert_equal((rRecord.price/rRecord.amount), (SELECT sell_price FROM product WHERE code = currval('product_code_seq')));

  END MAIN;

  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_sales_check_product() RETURNS VOID AS $$
-- module: sales
BEGIN
  PERFORM test.assert_empty('SELECT * FROM sales WHERE NOT EXISTS (SELECT 1 FROM product WHERE product.code = sales.product)');

  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.test_sales_check_customer() RETURNS VOID AS $$
-- module: sales
BEGIN
  PERFORM test.assert_empty('SELECT * FROM sales WHERE NOT EXISTS (SELECT 1 FROM customer WHERE customer.code = sales.customer)');

  PERFORM test.pass();
END;
$$ LANGUAGE plpgsql;


SELECT * FROM test.run_all();
