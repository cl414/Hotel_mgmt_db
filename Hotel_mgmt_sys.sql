
-- ==========================
-- 1️⃣ Create Schemas
-- ==========================
CREATE SCHEMA IF NOT EXISTS BranchDB_A;
CREATE SCHEMA IF NOT EXISTS BranchDB_B;

-- ==========================
-- 2️⃣ BranchDB_A Tables
-- ==========================
SET search_path = BranchDB_A, public;

CREATE TABLE IF NOT EXISTS Service (
  ServiceID SERIAL PRIMARY KEY,
  ServiceName VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS Staff (
  StaffID SERIAL PRIMARY KEY,
  FullName VARCHAR(150) NOT NULL,
  Position VARCHAR(100),
  ServiceID INT REFERENCES Service(ServiceID),
  Email VARCHAR(150),
  Phone VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Guest (
  GuestID SERIAL PRIMARY KEY,
  FullName VARCHAR(150) NOT NULL,
  Gender VARCHAR(10),
  Email VARCHAR(150),
  Phone VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Room (
  RoomID SERIAL PRIMARY KEY,
  RoomNumber VARCHAR(10) NOT NULL,
  RoomType VARCHAR(50),
  PricePerNight NUMERIC(10,2),
  Status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Booking (
  BookingID SERIAL PRIMARY KEY,
  GuestID INT REFERENCES Guest(GuestID),
  RoomID INT REFERENCES Room(RoomID),
  CheckIn DATE,
  CheckOut DATE,
  Status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Payment (
  PaymentID SERIAL PRIMARY KEY,
  BookingID INT REFERENCES Booking(BookingID),
  Amount NUMERIC(10,2),
  PaymentDate DATE,
  Method VARCHAR(50)
);

-- ==========================
-- 3️⃣ Sample Data Inserts
-- ==========================
INSERT INTO Service (ServiceName)
VALUES ('Reception'), ('Housekeeping')
ON CONFLICT DO NOTHING;

INSERT INTO Staff (FullName, Position, ServiceID, Email, Phone)
VALUES 
  ('Alice Mukamana', 'Receptionist', 1, 'alice@hotel.com', '0788000001'),
  ('Jean Kamanzi', 'Cleaner', 2, 'jean@hotel.com', '0788000002')
ON CONFLICT DO NOTHING;

INSERT INTO Guest (FullName, Gender, Email, Phone)
VALUES
  ('Claude Harerimana', 'Male', 'claude@guest.com', '0788123456'),
  ('Aline Uwera', 'Female', 'aline@guest.com', '0788234567')
ON CONFLICT DO NOTHING;

INSERT INTO Room (RoomNumber, RoomType, PricePerNight, Status)
VALUES 
  ('A101', 'Single', 30000, 'Available'),
  ('A102', 'Double', 45000, 'Occupied')
ON CONFLICT DO NOTHING;

INSERT INTO Booking (GuestID, RoomID, CheckIn, CheckOut, Status)
VALUES
  (1, 2, '2025-10-01', '2025-10-05', 'Completed'),
  (2, 1, '2025-10-10', '2025-10-12', 'Booked')
ON CONFLICT DO NOTHING;

INSERT INTO Payment (BookingID, Amount, PaymentDate, Method)
VALUES
  (1, 180000, '2025-10-05', 'Cash')
ON CONFLICT DO NOTHING;

-- ==========================
-- 4️⃣ Enable FDW and dblink
-- ==========================
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE EXTENSION IF NOT EXISTS dblink;

-- Drop existing server if exists (revision)
DROP SERVER IF EXISTS branchb_srv CASCADE;

CREATE SERVER branchb_srv
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host '127.0.0.1', dbname 'BranchDB_B', port '5432');

-- User mapping
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
SERVER branchb_srv
OPTIONS (user 'postgres', password 'postgres');

-- Import BranchDB_B schema into public (revision safe)
IMPORT FOREIGN SCHEMA BranchDB_B
  LIMIT TO (Guest, Booking, Payment, Room, Staff, Service)
  FROM SERVER branchb_srv INTO public;

-- ==========================
-- 5️⃣ dblink connection
-- ==========================
DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_foreign_server WHERE srvname = 'conn_branchb') THEN
      PERFORM dblink_connect('conn_branchb', 'host=127.0.0.1 dbname=BranchDB_B user=postgres password=postgres');
   END IF;
END$$;

-- Example remote SELECT
SELECT * FROM dblink('conn_branchb', 'SELECT guestid, fullname FROM BranchDB_B.Guest')
  AS t(guestid INT, fullname TEXT);

-- Example distributed join
SET search_path = BranchDB_A, public;
SELECT a.guestid, a.fullname, b.bookingid, b.roomid
FROM Guest a
LEFT JOIN LATERAL (
  SELECT * FROM dblink('conn_branchb',
    format('SELECT bookingid, guestid, roomid FROM BranchDB_B.Booking WHERE guestid = %s', a.guestid)
  ) AS t(bookingid INT, guestid INT, roomid INT)
) b ON true;


CREATE DATABASE BranchDB_B
  WITH OWNER = postgres
  ENCODING = 'UTF8'
  CONNECTION LIMIT = -1;


CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE EXTENSION IF NOT EXISTS dblink;


DROP SERVER IF EXISTS branchb_srv CASCADE;



CREATE SERVER branchb_srv
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host '127.0.0.1', dbname 'BranchDB_B', port '5432');


CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
SERVER branchb_srv
OPTIONS (user 'postgres', password 'postgres');

IMPORT FOREIGN SCHEMA BranchDB_B
  LIMIT TO (Guest, Room, Booking, Payment)
  FROM SERVER branchb_srv INTO public;

IMPORT FOREIGN SCHEMA BranchDB_B
  LIMIT TO (Guest, Room, Booking, Payment)
  FROM SERVER branchb_srv
  INTO public;



SELECT 1
FROM pg_database
WHERE datname = 'BranchDB_A';





DO $$
BEGIN
   IF NOT EXISTS (
       SELECT 1 FROM pg_database WHERE datname = 'BranchDB_A'
   ) THEN
       PERFORM dblink_exec('dbname=postgres user=postgres password=postgres',
           'CREATE DATABASE "BranchDB_A" WITH OWNER = postgres ENCODING = ''UTF8''');
   END IF;
END$$;



SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'BranchDB_A';


CREATE SCHEMA IF NOT EXISTS BranchDB_A;


CREATE TABLE IF NOT EXISTS Guest (
    GuestID SERIAL PRIMARY KEY,
    FullName VARCHAR(150) NOT NULL,
    Gender VARCHAR(10),
    Email VARCHAR(150),
    Phone VARCHAR(30)
);



SELECT * 
FROM pg_catalog.pg_foreign_server
WHERE srvname = 'branchb_srv';


SELECT * FROM pg_catalog.pg_user_mapping WHERE srvname = 'branchb_srv';




SELECT * 
FROM pg_foreign_server
WHERE srvname = 'branchb_srv';



SELECT *
FROM pg_user_mapping
WHERE srvname = 'branch_srv';


SELECT *
FROM pg_foreign_server
WHERE srvname = 'branch_srv';


SELECT 
    um.umuser, 
    r.rolname AS username, 
    fs.srvname, 
    um.options
FROM pg_user_mapping um
JOIN pg_foreign_server fs ON um.umserver = fs.oid
JOIN pg_roles r ON um.umuser = r.oid
WHERE fs.srvname = 'branchb_srv';





SELECT 
    um.umuser, 
    r.rolname AS username, 
    fs.srvname, 
    um.umoptions
FROM pg_user_mapping um
JOIN pg_foreign_server fs ON um.umserver = fs.oid
JOIN pg_roles r ON um.umuser = r.oid
WHERE fs.srvname = 'branchb_srv';



SELECT * FROM public.Guest LIMIT 5;
SELECT * FROM public.Room LIMIT 5;
SELECT * FROM public.Booking LIMIT 5;
SELECT * FROM public.Payment LIMIT 5;


SET search_path = BranchDB_A, public;

SELECT a.guestid, a.fullname, b.bookingid, b.roomid
FROM Guest a               -- local table in BranchDB_A
LEFT JOIN public.Booking b  -- foreign table from BranchDB_B
    ON a.guestid = b.guestid;



SET search_path = BranchDB_A, public;

SELECT a.guest_id, a.fullname, b.bookingid, b.roomid
FROM Guest a                -- local table in BranchDB_A
LEFT JOIN public.Booking b   -- foreign table from BranchDB_B
    ON a.guest_id = b.guestid;
SET search_path = BranchDB_A, public;

SELECT a.guest_id, a.fullname, b.bookingid, b.roomid
FROM Guest a                 -- local table in BranchDB_A
LEFT JOIN public.Booking b    -- foreign table from BranchDB_B
    ON a.guest_id = b.guest_id;

-- BranchDB_B – RoomType table
CREATE TABLE IF NOT EXISTS RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    description TEXT
);

-- Update Room table to reference RoomType
CREATE TABLE IF NOT EXISTS Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    room_type_id INT REFERENCES RoomType(room_type_id),
    price_per_night NUMERIC(10,2),
    status VARCHAR(20)
);

-- Sample data for RoomType
INSERT INTO RoomType (type_name, description) VALUES
('Single', 'Single occupancy'),
('Double', 'Double occupancy'),
('Suite', 'Luxury suite');



-- Use schema
CREATE SCHEMA IF NOT EXISTS BranchDB_A;
SET search_path = BranchDB_A, public;

-- RoomType Table
CREATE TABLE IF NOT EXISTS RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,
    description TEXT
);

-- Room Table
CREATE TABLE IF NOT EXISTS Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    room_type_id INT REFERENCES RoomType(room_type_id),
    status VARCHAR(20)
);

-- Guest Table
CREATE TABLE IF NOT EXISTS Guest (
    guest_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    gender VARCHAR(10),
    email VARCHAR(150),
    phone VARCHAR(30)
);

-- Booking Table
CREATE TABLE IF NOT EXISTS Booking (
    booking_id SERIAL PRIMARY KEY,
    guest_id INT REFERENCES Guest(guest_id),
    room_id INT REFERENCES Room(room_id),
    check_in DATE,
    check_out DATE,
    status VARCHAR(20)
);

-- Payment Table
CREATE TABLE IF NOT EXISTS Payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id),
    amount NUMERIC(10,2),
    payment_date DATE,
    method VARCHAR(50)
);

-- Sample Data

-- Room Types
INSERT INTO RoomType (type_name, price_per_night, description) VALUES
('Single', 50.00, 'Single occupancy'),
('Double', 80.00, 'Double occupancy'),
('Suite', 150.00, 'Luxury suite')
ON CONFLICT DO NOTHING;

-- Rooms
INSERT INTO Room (room_number, room_type_id, status) VALUES
('101', 1, 'Available'),
('102', 2, 'Available'),
('201', 3, 'Available')
ON CONFLICT DO NOTHING;

-- Guests
INSERT INTO Guest (full_name, gender, email, phone) VALUES
('Alice Uwase', 'Female', 'alice@example.com', '0788000001'),
('John Nkurunziza', 'Male', 'john@example.com', '0788000002')
ON CONFLICT DO NOTHING;

-- Bookings
INSERT INTO Booking (guest_id, room_id, check_in, check_out, status) VALUES
(1, 1, '2025-11-01', '2025-11-05', 'Confirmed'),
(2, 2, '2025-11-02', '2025-11-06', 'Confirmed')
ON CONFLICT DO NOTHING;

-- Payments
INSERT INTO Payment (booking_id, amount, payment_date, method) VALUES
(1, 200.00, '2025-11-01', 'Cash'),
(2, 400.00, '2025-11-02', 'Credit Card')
ON CONFLICT DO NOTHING;




-- BranchDB_A
SET search_path = BranchDB_A, public;

CREATE TABLE IF NOT EXISTS Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);

-- BranchDB_B
SET search_path = BranchDB_B, public;

CREATE TABLE IF NOT EXISTS Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);


-- BranchDB_A
SET search_path = BranchDB_A, public;

INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Room Service - Dinner', 20.00, '2025-11-02'),
(2, 'Laundry', 10.00, '2025-11-03')
ON CONFLICT DO NOTHING;

-- BranchDB_B
SET search_path = BranchDB_B, public;

INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Spa', 50.00, '2025-11-04'),
(2, 'Breakfast', 15.00, '2025-11-05')
ON CONFLICT DO NOTHING



-- BranchDB_A
SET search_path = BranchDB_A, public;

INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Room Service - Dinner', 20.00, '2025-11-02'),
(2, 'Laundry', 10.00, '2025-11-03')
ON CONFLICT DO NOTHING;

-- BranchDB_B
SET search_path = BranchDB_B, public;

INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Spa', 50.00, '2025-11-04'),
(2, 'Breakfast', 15.00, '2025-11-05')
ON CONFLICT DO NOTHING;


-- For BranchDB_A
SET search_path = BranchDB_A, public;





-- BranchDB_A
SET search_path = BranchDB_A, public;
DROP TABLE IF EXISTS Service;

CREATE TABLE Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);

-- BranchDB_B
SET search_path = BranchDB_B, public;
DROP TABLE IF EXISTS Service;

CREATE TABLE Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);



-- BranchDB_A
INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Room Service - Dinner', 20.00, '2025-11-02'),
(2, 'Laundry', 10.00, '2025-11-03');

-- BranchDB_B
INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Spa', 50.00, '2025-11-04'),
(2, 'Breakfast', 15.00, '2025-11-05');



-- Enable FDW extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create server for BranchDB_B
DROP SERVER IF EXISTS branchb_srv CASCADE;
CREATE SERVER branchb_srv FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'BranchDB_B', port '5432');

-- Map current user to server
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER SERVER branchb_srv
OPTIONS (user 'postgres', password 'postgres');




IMPORT FOREIGN SCHEMA BranchDB_B
LIMIT TO (Guest, Room, Booking, Payment, Service)
FROM SERVER branchb_srv INTO public;



SELECT datname FROM pg_database;




-- Step 1: Connect to postgres default database to create/drop BranchDB_B
\c postgres

-- Drop BranchDB_B if it exists
DROP DATABASE IF EXISTS BranchDB_B;

-- Create BranchDB_B
CREATE DATABASE BranchDB_B
WITH 
OWNER = postgres
ENCODING = 'UTF8'
LC_COLLATE = 'en_US.utf8'
LC_CTYPE = 'en_US.utf8'
TEMPLATE = template0;

-- Step 2: Connect to BranchDB_B
\c BranchDB_B

-- Create schema
CREATE SCHEMA IF NOT EXISTS BranchDB_B;
SET search_path = BranchDB_B, public;

-- Step 3: Create tables

-- RoomType Table
CREATE TABLE IF NOT EXISTS RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,
    description TEXT
);

-- Room Table
CREATE TABLE IF NOT EXISTS Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    room_type_id INT REFERENCES RoomType(room_type_id),
    status VARCHAR(20)
);

-- Guest Table
CREATE TABLE IF NOT EXISTS Guest (
    guest_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    gender VARCHAR(10),
    email VARCHAR(150),
    phone VARCHAR(30)
);

-- Booking Table
CREATE TABLE IF NOT EXISTS Booking (
    booking_id SERIAL PRIMARY KEY,
    guest_id INT REFERENCES Guest(guest_id),
    room_id INT REFERENCES Room(room_id),
    check_in DATE,
    check_out DATE,
    status VARCHAR(20)
);

-- Payment Table
CREATE TABLE IF NOT EXISTS Payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id),
    amount NUMERIC(10,2),
    payment_date DATE,
    method VARCHAR(50)
);

-- Service Table
CREATE TABLE IF NOT EXISTS Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);

-- Step 4: Insert sample data

-- Room Types
INSERT INTO RoomType (type_name, price_per_night, description) VALUES
('Single', 55.00, 'Single occupancy - Branch B'),
('Double', 85.00, 'Double occupancy - Branch B'),
('Suite', 160.00, 'Luxury suite - Branch B');

-- Rooms
INSERT INTO Room (room_number, room_type_id, status) VALUES
('103', 1, 'Available'),
('104', 2, 'Available'),
('202', 3, 'Available');

-- Guests
INSERT INTO Guest (full_name, gender, email, phone) VALUES
('Pauline Mukamana', 'Female', 'pauline@example.com', '0788000003'),
('Eric Manirakiza', 'Male', 'eric@example.com', '0788000004');

-- Bookings
INSERT INTO Booking (guest_id, room_id, check_in, check_out, status) VALUES
(1, 3, '2025-11-03', '2025-11-07', 'Confirmed'),
(2, 4, '2025-11-04', '2025-11-08', 'Confirmed');

-- Payments
INSERT INTO Payment (booking_id, amount, payment_date, method) VALUES
(1, 220.00, '2025-11-03', 'Cash'),
(2, 420.00, '2025-11-04', 'Credit Card');

-- Services
INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Spa', 50.00, '2025-11-04'),
(2, 'Breakfast', 15.00, '2025-11-05');








-- Step 1: Drop BranchDB_B if it exists
DROP DATABASE IF EXISTS BranchDB_B;

-- Step 2: Create BranchDB_B
CREATE DATABASE BranchDB_B
WITH 
OWNER = postgres
ENCODING = 'UTF8'
LC_COLLATE = 'en_US.utf8'
LC_CTYPE = 'en_US.utf8'
TEMPLATE = template0;

-- Note: Now manually connect to BranchDB_B in your SQL tool
-- Example in pgAdmin: Right-click BranchDB_B -> Query Tool -> run next steps

-- Step 3: Create schema
CREATE SCHEMA IF NOT EXISTS BranchDB_B;
SET search_path = BranchDB_B, public;

-- Step 4: Create tables

CREATE TABLE IF NOT EXISTS RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    room_type_id INT REFERENCES RoomType(room_type_id),
    status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Guest (
    guest_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    gender VARCHAR(10),
    email VARCHAR(150),
    phone VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Booking (
    booking_id SERIAL PRIMARY KEY,
    guest_id INT REFERENCES Guest(guest_id),
    room_id INT REFERENCES Room(room_id),
    check_in DATE,
    check_out DATE,
    status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id),
    amount NUMERIC(10,2),
    payment_date DATE,
    method VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);

-- Step 5: Insert sample data

INSERT INTO RoomType (type_name, price_per_night, description) VALUES
('Single', 55.00, 'Single occupancy - Branch B'),
('Double', 85.00, 'Double occupancy - Branch B'),
('Suite', 160.00, 'Luxury suite - Branch B');

INSERT INTO Room (room_number, room_type_id, status) VALUES
('103', 1, 'Available'),
('104', 2, 'Available'),
('202', 3, 'Available');

INSERT INTO Guest (full_name, gender, email, phone) VALUES
('Pauline Mukamana', 'Female', 'pauline@example.com', '0788000003'),
('Eric Manirakiza', 'Male', 'eric@example.com', '0788000004');

INSERT INTO Booking (guest_id, room_id, check_in, check_out, status) VALUES
(1, 3, '2025-11-03', '2025-11-07', 'Confirmed'),
(2, 4, '2025-11-04', '2025-11-08', 'Confirmed');

INSERT INTO Payment (booking_id, amount, payment_date, method) VALUES
(1, 220.00, '2025-11-03', 'Cash'),
(2, 420.00, '2025-11-04', 'Credit Card');

INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Spa', 50.00, '2025-11-04'),
(2, 'Breakfast', 15.00, '2025-11-05');





-- Step 0: Disconnect from BranchDB_B if connected
-- In pgAdmin, make sure you are connected to another DB like 'postgres'

-- Step 1: Drop BranchDB_B if it exists
DROP BRANCHDB_D IF EXISTS BranchDB_B;

-- Step 2: Create BranchDB_B
CREATE DATABASE BranchDB_B
WITH 
OWNER = postgres
ENCODING = 'UTF8'
LC_COLLATE = 'en_US.utf8'
LC_CTYPE = 'en_US.utf8'
TEMPLATE = template0;

-- === After creating the database, manually connect to BranchDB_B ===
-- In pgAdmin: Right-click BranchDB_B -> Query Tool -> run next steps

-- Step 3: Create schema
CREATE SCHEMA IF NOT EXISTS BranchDB_B;
SET search_path = BranchDB_B, public;

-- Step 4: Create tables

CREATE TABLE IF NOT EXISTS RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    room_type_id INT REFERENCES RoomType(room_type_id),
    status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Guest (
    guest_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    gender VARCHAR(10),
    email VARCHAR(150),
    phone VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Booking (
    booking_id SERIAL PRIMARY KEY,
    guest_id INT REFERENCES Guest(guest_id),
    room_id INT REFERENCES Room(room_id),
    check_in DATE,
    check_out DATE,
    status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id),
    amount NUMERIC(10,2),
    payment_date DATE,
    method VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);

-- Step 5: Insert sample data

-- Room Types
INSERT INTO RoomType (type_name, price_per_night, description) VALUES
('Single', 55.00, 'Single occupancy - Branch B'),
('Double', 85.00, 'Double occupancy - Branch B'),
('Suite', 160.00, 'Luxury suite - Branch B');

-- Rooms
INSERT INTO Room (room_number, room_type_id, status) VALUES
('103', 1, 'Available'),
('104', 2, 'Available'),
('202', 3, 'Available');

-- Guests
INSERT INTO Guest (full_name, gender, email, phone) VALUES
('Pauline Mukamana', 'Female', 'pauline@example.com', '0788000003'),
('Eric Manirakiza', 'Male', 'eric@example.com', '0788000004');

-- Bookings
INSERT INTO Booking (guest_id, room_id, check_in, check_out, status) VALUES
(1, 3, '2025-11-03', '2025-11-07', 'Confirmed'),
(2, 4, '2025-11-04', '2025-11-08', 'Confirmed');

-- Payments
INSERT INTO Payment (booking_id, amount, payment_date, method) VALUES
(1, 220.00, '2025-11-03', 'Cash'),
(2, 420.00, '2025-11-04', 'Credit Card');

-- Services
INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Spa', 50.00, '2025-11-04'),
(2, 'Breakfast', 15.00, '2025-11-05');

DROP DATABASE IF EXISTS BranchDB_B;

DROP DATABASE [IF EXISTS] database_name;


-- Make sure you are connected to another database like 'postgres'
-- Drop BranchDB_B if it exists
DROP DATABASE IF EXISTS BranchDB_B;

-- Create BranchDB_B
CREATE DATABASE BranchDB_B
WITH 
OWNER = postgres
ENCODING = 'UTF8'
LC_COLLATE = 'en_US.utf8'
LC_CTYPE = 'en_US.utf8'
TEMPLATE = template0;



-- ========================================
-- BranchDB_B Setup Script (Safe to Run)
-- ========================================

-- Step 0: Set schema
CREATE SCHEMA IF NOT EXISTS BranchDB_B;
SET search_path = BranchDB_B, public;

-- Step 1: Drop tables if they exist (safe inside transaction)
DROP TABLE IF EXISTS Service CASCADE;
DROP TABLE IF EXISTS Payment CASCADE;
DROP TABLE IF EXISTS Booking CASCADE;
DROP TABLE IF EXISTS Guest CASCADE;
DROP TABLE IF EXISTS Room CASCADE;
DROP TABLE IF EXISTS RoomType CASCADE;

-- Step 2: Create tables

CREATE TABLE RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,
    description TEXT
);

CREATE TABLE Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    room_type_id INT REFERENCES RoomType(room_type_id),
    status VARCHAR(20)
);

CREATE TABLE Guest (
    guest_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    gender VARCHAR(10),
    email VARCHAR(150),
    phone VARCHAR(30)
);

CREATE TABLE Booking (
    booking_id SERIAL PRIMARY KEY,
    guest_id INT REFERENCES Guest(guest_id),
    room_id INT REFERENCES Room(room_id),
    check_in DATE,
    check_out DATE,
    status VARCHAR(20)
);

CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id),
    amount NUMERIC(10,2),
    payment_date DATE,
    method VARCHAR(50)
);

CREATE TABLE Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);

-- Step 3: Insert sample data

-- Room Types
INSERT INTO RoomType (type_name, price_per_night, description) VALUES
('Single', 55.00, 'Single occupancy - Branch B'),
('Double', 85.00, 'Double occupancy - Branch B'),
('Suite', 160.00, 'Luxury suite - Branch B');

-- Rooms
INSERT INTO Room (room_number, room_type_id, status) VALUES
('103', 1, 'Available'),
('104', 2, 'Available'),
('202', 3, 'Available');

-- Guests
INSERT INTO Guest (full_name, gender, email, phone) VALUES
('Pauline Mukamana', 'Female', 'pauline@example.com', '0788000003'),
('Eric Manirakiza', 'Male', 'eric@example.com', '0788000004');

-- Bookings
INSERT INTO Booking (guest_id, room_id, check_in, check_out, status) VALUES
(1, 3, '2025-11-03', '2025-11-07', 'Confirmed'),
(2, 4, '2025-11-04', '2025-11-08', 'Confirmed');

-- Payments
INSERT INTO Payment (booking_id, amount, payment_date, method) VALUES
(1, 220.00, '2025-11-03', 'Cash'),
(2, 420.00, '2025-11-04', 'Credit Card');

-- Services
INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Spa', 50.00, '2025-11-04'),
(2, 'Breakfast', 15.00, '2025-11-05');

-- ========================================
-- BranchDB_B is now ready for FDW / dblink
-- ========================================


INSERT INTO Room (room_number, room_type_id, status) VALUES
('103', 1, 'Available'),  -- room_id = 1
('104', 2, 'Available'),  -- room_id = 2
('202', 3, 'Available');  -- room_id = 3




SET search_path = BranchDB_B, public;


DROP TABLE IF EXISTS Room CASCADE;



CREATE TABLE Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    room_type_id INT REFERENCES RoomType(room_type_id),
    status VARCHAR(20)
);



CREATE TABLE RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,
    description TEXT
);





-- Use BranchDB_B schema
SET search_path = BranchDB_B, public;

-- Drop tables if they exist (in reverse dependency order)
DROP TABLE IF EXISTS Service CASCADE;
DROP TABLE IF EXISTS Payment CASCADE;
DROP TABLE IF EXISTS Booking CASCADE;
DROP TABLE IF EXISTS Guest CASCADE;
DROP TABLE IF EXISTS Room CASCADE;
DROP TABLE IF EXISTS RoomType CASCADE;

-- Create tables
CREATE TABLE RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,
    description TEXT
);

CREATE TABLE Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    room_type_id INT REFERENCES RoomType(room_type_id),
    status VARCHAR(20)
);

CREATE TABLE Guest (
    guest_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    gender VARCHAR(10),
    email VARCHAR(150),
    phone VARCHAR(30)
);

CREATE TABLE Booking (
    booking_id SERIAL PRIMARY KEY,
    guest_id INT REFERENCES Guest(guest_id),
    room_id INT REFERENCES Room(room_id),
    check_in DATE,
    check_out DATE,
    status VARCHAR(20)
);

CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id),
    amount NUMERIC(10,2),
    payment_date DATE,
    method VARCHAR(50)
);

CREATE TABLE Service (
    service_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES Booking(booking_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    service_date DATE
);

-- Insert sample data
INSERT INTO RoomType (type_name, price_per_night, description) VALUES
('Single', 55.00, 'Single occupancy - Branch B'),
('Double', 85.00, 'Double occupancy - Branch B'),
('Suite', 160.00, 'Luxury suite - Branch B');

INSERT INTO Room (room_number, room_type_id, status) VALUES
('103', 1, 'Available'),
('104', 2, 'Available'),
('202', 3, 'Available');

INSERT INTO Guest (full_name, gender, email, phone) VALUES
('Pauline Mukamana', 'Female', 'pauline@example.com', '0788000003'),
('Eric Manirakiza', 'Male', 'eric@example.com', '0788000004');

INSERT INTO Booking (guest_id, room_id, check_in, check_out, status) VALUES
(1, 3, '2025-11-03', '2025-11-07', 'Confirmed'),
(2, 2, '2025-11-04', '2025-11-08', 'Confirmed');

INSERT INTO Payment (booking_id, amount, payment_date, method) VALUES
(1, 220.00, '2025-11-03', 'Cash'),
(2, 420.00, '2025-11-04', 'Credit Card');

INSERT INTO Service (booking_id, service_name, price, service_date) VALUES
(1, 'Spa', 50.00, '2025-11-04'),
(2, 'Breakfast', 15.00, '2025-11-05');



-- Run in BranchDB_A
CREATE EXTENSION IF NOT EXISTS postgres_fdw;




-- Create server connection to BranchDB_B
DROP SERVER IF EXISTS branchb_srv CASCADE;

CREATE SERVER branchb_srv
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',
    dbname 'BranchDB_B',
    port '5432'
);


CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
SERVER branchb_srv
OPTIONS (user 'postgres', password 'postgres');



IMPORT FOREIGN SCHEMA public
LIMIT TO (Guest, Room, Booking, Payment, Service, RoomType)
FROM SERVER branchb_srv
INTO public;


-- Connect to postgres database first
--\c postgres

-- Create BranchDB_B database (must run outside transaction)
CREATE BranchDB_B DATABASE;


--\c BranchDB_B

CREATE SCHEMA IF NOT EXISTS public;

-- Now create RoomType, Room, Guest, Booking, Payment, Service tables
-- (use the BranchDB_B script we prepared earlier)




\c postgres
CREATE DATABASE BranchDB_B;



