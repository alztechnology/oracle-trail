-- AL's Oracle Trail practice schema (Oracle 19c / 23ai)
-- Run this whole script once in Oracle FreeSQL (freesql.com, the new Live SQL) or your Oracle Free container.
-- Safe to re-run: it drops the trail tables (and the scratch tables the lessons create) first.

BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('RECON_RESULTS','PRICE_UPDATES','BIG_ORDERS','ORDER_AUDIT','BILLING_FEED','PAYMENTS','INVOICES','ORDER_ITEMS',
                                 'ORDERS','PRODUCTS','CUSTOMERS','EMPLOYEES','DEPARTMENTS')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN ('ORDER_SEQ','AUDIT_SEQ')) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/

CREATE TABLE departments (
  dept_id    NUMBER(4)    CONSTRAINT dept_pk PRIMARY KEY,
  dept_name  VARCHAR2(30) NOT NULL,
  region     VARCHAR2(10)
);

CREATE TABLE employees (
  emp_id         NUMBER(6)     CONSTRAINT emp_pk PRIMARY KEY,
  first_name     VARCHAR2(30)  NOT NULL,
  last_name      VARCHAR2(30)  NOT NULL,
  email          VARCHAR2(60)  CONSTRAINT emp_email_uk UNIQUE,
  dept_id        NUMBER(4)     CONSTRAINT emp_dept_fk REFERENCES departments(dept_id),
  manager_id     NUMBER(6)     CONSTRAINT emp_mgr_fk REFERENCES employees(emp_id),
  hire_date      DATE          NOT NULL,
  salary         NUMBER(10,2)  CONSTRAINT emp_sal_ck CHECK (salary > 0),
  commission_pct NUMBER(3,2)
);

CREATE TABLE customers (
  customer_id   NUMBER(6)     CONSTRAINT cust_pk PRIMARY KEY,
  customer_name VARCHAR2(60)  NOT NULL,
  segment       VARCHAR2(20),
  country       VARCHAR2(30),
  email         VARCHAR2(60),
  created_date  DATE          DEFAULT SYSDATE NOT NULL
);

CREATE TABLE products (
  product_id   NUMBER(6)     CONSTRAINT prod_pk PRIMARY KEY,
  product_name VARCHAR2(60)  NOT NULL,
  category     VARCHAR2(20)  NOT NULL,
  unit_price   NUMBER(10,2)  NOT NULL,
  active_flag  CHAR(1)       DEFAULT 'Y' CONSTRAINT prod_active_ck CHECK (active_flag IN ('Y','N'))
);

CREATE TABLE orders (
  order_id     NUMBER(8)     CONSTRAINT ord_pk PRIMARY KEY,
  customer_id  NUMBER(6)     NOT NULL CONSTRAINT ord_cust_fk REFERENCES customers(customer_id),
  sales_rep_id NUMBER(6)     CONSTRAINT ord_rep_fk REFERENCES employees(emp_id),
  order_date   DATE          NOT NULL,
  status       VARCHAR2(12)  NOT NULL CONSTRAINT ord_status_ck CHECK (status IN ('OPEN','SHIPPED','CANCELLED')),
  channel      VARCHAR2(10)
);

CREATE TABLE order_items (
  order_id     NUMBER(8)     CONSTRAINT oi_ord_fk REFERENCES orders(order_id),
  line_no      NUMBER(3),
  product_id   NUMBER(6)     NOT NULL CONSTRAINT oi_prod_fk REFERENCES products(product_id),
  quantity     NUMBER(6)     NOT NULL CONSTRAINT oi_qty_ck CHECK (quantity > 0),
  unit_price   NUMBER(10,2)  NOT NULL,
  discount_pct NUMBER(5,2)   DEFAULT 0 NOT NULL,
  CONSTRAINT oi_pk PRIMARY KEY (order_id, line_no)
);

CREATE TABLE invoices (
  invoice_id   NUMBER(8)     CONSTRAINT inv_pk PRIMARY KEY,
  order_id     NUMBER(8)     NOT NULL CONSTRAINT inv_ord_fk REFERENCES orders(order_id),
  invoice_date DATE          NOT NULL,
  amount       NUMBER(12,2)  NOT NULL,
  status       VARCHAR2(10)  NOT NULL CONSTRAINT inv_status_ck CHECK (status IN ('ISSUED','PAID','VOID'))
);

CREATE TABLE payments (
  payment_id   NUMBER(8)     CONSTRAINT pay_pk PRIMARY KEY,
  invoice_id   NUMBER(8)     NOT NULL CONSTRAINT pay_inv_fk REFERENCES invoices(invoice_id),
  payment_date DATE          NOT NULL,
  amount       NUMBER(12,2)  NOT NULL,
  method       VARCHAR2(10)
);

-- Raw extract from the billing system, loaded as text (realistic and a bit messy)
CREATE TABLE billing_feed (
  feed_id       NUMBER(8)     CONSTRAINT feed_pk PRIMARY KEY,
  order_ref     VARCHAR2(20),
  billed_amount NUMBER(12,2),
  billed_date   VARCHAR2(10),
  currency      VARCHAR2(3)
);

INSERT INTO departments (dept_id, dept_name, region) VALUES (10, 'Sales', 'APJ');
INSERT INTO departments (dept_id, dept_name, region) VALUES (20, 'Finance', 'APJ');
INSERT INTO departments (dept_id, dept_name, region) VALUES (30, 'Operations', 'EMEA');
INSERT INTO departments (dept_id, dept_name, region) VALUES (40, 'IT', 'APJ');
INSERT INTO departments (dept_id, dept_name, region) VALUES (50, 'Marketing', NULL);

INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (100, 'Siti', 'Rahman', 'siti.rahman@trailco.my', 10, NULL, DATE '2015-03-01', 30000, NULL);
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (101, 'Daniel', 'Tan', 'daniel.tan@trailco.my', 10, 100, DATE '2018-06-15', 12000, 0.1);
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (102, 'Priya', 'Nair', 'priya.nair@trailco.my', 10, 100, DATE '2019-01-07', 11000, 0.15);
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (103, 'Wei Ling', 'Ong', 'weiling.ong@trailco.my', 20, 100, DATE '2017-09-20', 13000, NULL);
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (104, 'Arjun', 'Kumar', 'arjun.kumar@trailco.my', 20, 103, DATE '2021-02-01', 8000, NULL);
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (105, 'Nurul', 'Huda', 'nurul.huda@trailco.my', 30, 100, DATE '2020-11-11', 9500, NULL);
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (106, 'Marcus', 'Lee', 'marcus.lee@trailco.my', 40, 100, DATE '2016-04-04', 15000, NULL);
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (107, 'Farah', 'Aziz', 'farah.aziz@trailco.my', 10, 101, DATE '2023-08-01', 7000, 0.05);
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, hire_date, salary, commission_pct) VALUES (108, 'James', 'Wong', 'james.wong@trailco.my', NULL, 106, DATE '2024-05-20', 6000, NULL);

INSERT INTO customers (customer_id, customer_name, segment, country, email, created_date) VALUES (1, 'Acme Trading Sdn Bhd', 'Corporate', 'Malaysia', 'ap@acme.my', DATE '2024-01-10');
INSERT INTO customers (customer_id, customer_name, segment, country, email, created_date) VALUES (2, 'Bintang Retail', 'SME', 'Malaysia', 'finance@bintang.my', DATE '2024-02-14');
INSERT INTO customers (customer_id, customer_name, segment, country, email, created_date) VALUES (3, 'Coral Logistics Pte Ltd', 'Corporate', 'Singapore', 'billing@coral.sg', DATE '2024-03-03');
INSERT INTO customers (customer_id, customer_name, segment, country, email, created_date) VALUES (4, 'Delta Foods', 'SME', 'Thailand', NULL, DATE '2024-05-21');
INSERT INTO customers (customer_id, customer_name, segment, country, email, created_date) VALUES (5, 'Everest Tech', 'Corporate', 'India', 'accounts@everest.in', DATE '2024-07-01');
INSERT INTO customers (customer_id, customer_name, segment, country, email, created_date) VALUES (6, 'Fajar Studio', 'SME', NULL, 'hello@fajar.my', DATE '2025-01-15');
INSERT INTO customers (customer_id, customer_name, segment, country, email, created_date) VALUES (7, 'ACME Trading', 'Corporate', 'Malaysia', 'AP@acme.my', DATE '2025-02-02');
INSERT INTO customers (customer_id, customer_name, segment, country, email, created_date) VALUES (8, 'Gemilang Hotels', 'Corporate', 'Malaysia', 'ar@gemilang.my', DATE '2025-06-30');

INSERT INTO products (product_id, product_name, category, unit_price, active_flag) VALUES (1, 'Laptop Pro 14', 'Hardware', 4500, 'Y');
INSERT INTO products (product_id, product_name, category, unit_price, active_flag) VALUES (2, 'Laptop Air 13', 'Hardware', 3800, 'Y');
INSERT INTO products (product_id, product_name, category, unit_price, active_flag) VALUES (3, '27in Monitor', 'Hardware', 1200, 'Y');
INSERT INTO products (product_id, product_name, category, unit_price, active_flag) VALUES (4, 'Docking Station', 'Accessories', 650, 'Y');
INSERT INTO products (product_id, product_name, category, unit_price, active_flag) VALUES (5, 'Wireless Mouse', 'Accessories', 90, 'Y');
INSERT INTO products (product_id, product_name, category, unit_price, active_flag) VALUES (6, 'Support Plan 1yr', 'Services', 800, 'Y');
INSERT INTO products (product_id, product_name, category, unit_price, active_flag) VALUES (7, 'Onsite Setup', 'Services', 300, 'Y');
INSERT INTO products (product_id, product_name, category, unit_price, active_flag) VALUES (8, 'USB-C Cable', 'Accessories', 35, 'N');

INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1001, 1, 101, DATE '2025-01-15', 'SHIPPED', 'WEB');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1002, 2, 102, DATE '2025-02-03', 'SHIPPED', 'PHONE');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1003, 3, 101, DATE '2025-02-20', 'SHIPPED', 'WEB');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1004, 1, 107, DATE '2025-03-11', 'SHIPPED', 'WEB');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1005, 4, 102, DATE '2025-04-02', 'CANCELLED', 'PHONE');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1006, 5, 101, DATE '2025-05-19', 'SHIPPED', 'PARTNER');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1007, 3, 102, DATE '2025-07-07', 'SHIPPED', 'WEB');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1008, 2, 107, DATE '2025-09-01', 'SHIPPED', 'WEB');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1009, 6, 102, DATE '2025-10-15', 'SHIPPED', 'PHONE');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1010, 5, 101, DATE '2025-12-30', 'SHIPPED', 'PARTNER');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1011, 1, 101, DATE '2026-01-05', 'SHIPPED', 'WEB');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1012, 7, 107, DATE '2026-02-10', 'SHIPPED', 'WEB');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1013, 3, 102, DATE '2026-03-03', 'OPEN', 'WEB');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1014, 5, 101, DATE '2026-03-28', 'OPEN', 'PARTNER');
INSERT INTO orders (order_id, customer_id, sales_rep_id, order_date, status, channel) VALUES (1015, 2, 102, DATE '2026-04-01', 'OPEN', 'PHONE');

INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1001, 1, 1, 2, 4500, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1001, 2, 5, 2, 90, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1002, 1, 3, 3, 1200, 10);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1003, 1, 2, 5, 3800, 5);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1003, 2, 6, 5, 800, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1004, 1, 4, 4, 650, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1005, 1, 1, 1, 4500, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1006, 1, 1, 10, 4500, 8);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1006, 2, 7, 1, 300, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1007, 1, 5, 20, 90, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1007, 2, 3, 2, 1200, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1008, 1, 2, 1, 3800, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1008, 2, 6, 1, 800, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1009, 1, 7, 2, 300, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1010, 1, 3, 6, 1200, 5);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1010, 2, 4, 6, 650, 5);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1011, 1, 1, 1, 4500, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1011, 2, 6, 1, 800, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1012, 1, 5, 5, 90, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1013, 1, 2, 2, 3800, 0);
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price, discount_pct) VALUES (1014, 1, 1, 3, 4500, 10);

INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5001, 1001, DATE '2025-01-16', 9180, 'PAID');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5002, 1002, DATE '2025-02-04', 3240, 'PAID');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5003, 1003, DATE '2025-02-21', 21950, 'PAID');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5004, 1004, DATE '2025-03-12', 2600, 'ISSUED');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5005, 1005, DATE '2025-04-03', 4500, 'VOID');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5006, 1006, DATE '2025-05-20', 41700, 'ISSUED');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5007, 1007, DATE '2025-07-08', 4200, 'PAID');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5009, 1009, DATE '2025-10-16', 600, 'PAID');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5010, 1010, DATE '2025-12-31', 10545, 'ISSUED');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5011, 1011, DATE '2026-01-06', 5300, 'PAID');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5012, 1011, DATE '2026-01-06', 5300, 'ISSUED');
INSERT INTO invoices (invoice_id, order_id, invoice_date, amount, status) VALUES (5013, 1012, DATE '2026-02-11', 450, 'PAID');

INSERT INTO payments (payment_id, invoice_id, payment_date, amount, method) VALUES (9001, 5001, DATE '2025-01-30', 9180, 'TRANSFER');
INSERT INTO payments (payment_id, invoice_id, payment_date, amount, method) VALUES (9002, 5002, DATE '2025-02-20', 3240, 'CARD');
INSERT INTO payments (payment_id, invoice_id, payment_date, amount, method) VALUES (9003, 5003, DATE '2025-03-10', 21950, 'TRANSFER');
INSERT INTO payments (payment_id, invoice_id, payment_date, amount, method) VALUES (9004, 5006, DATE '2025-06-15', 20000, 'TRANSFER');
INSERT INTO payments (payment_id, invoice_id, payment_date, amount, method) VALUES (9005, 5007, DATE '2025-07-30', 4200, 'CARD');
INSERT INTO payments (payment_id, invoice_id, payment_date, amount, method) VALUES (9006, 5009, DATE '2025-11-01', 600, 'CARD');
INSERT INTO payments (payment_id, invoice_id, payment_date, amount, method) VALUES (9007, 5011, DATE '2026-01-20', 5300, 'TRANSFER');
INSERT INTO payments (payment_id, invoice_id, payment_date, amount, method) VALUES (9008, 5013, DATE '2026-02-25', 500, 'CARD');

INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (1, 'ORD-1001', 9180, '16/01/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (2, 'ORD-1002', 3240, '04/02/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (3, 'ORD-1003', 22050, '21/02/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (4, 'ORD-1004', 2600, '12/03/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (5, 'ORD-1006', 41700, '20/05/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (6, 'ORD-1007', 4200, '08/07/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (7, 'ORD-1008', 4600, '02/09/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (8, ' ORD-1009 ', 600, '16/10/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (9, 'ORD-1010', 10546, '31/12/2025', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (10, 'ORD-1011', 5300, '06/01/2026', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (11, 'ORD-1012', 450, '11/02/2026', 'MYR');
INSERT INTO billing_feed (feed_id, order_ref, billed_amount, billed_date, currency) VALUES (12, 'ORD-1099', 1500, '15/03/2026', 'MYR');

COMMIT;
