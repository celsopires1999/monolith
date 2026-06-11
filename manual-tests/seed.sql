-- ============================================
-- Seed data for manual tests
-- Run AFTER applying EF Core migrations
-- ============================================
-- Usage:
--   psql -h localhost -U <user> -d hotel_reservation -f seed.sql
-- Or run via your PostgreSQL client of choice
-- ============================================

-- Hotel (known GUID for use in manual tests)
INSERT INTO hotels (id, name, street, city, state, country, zip_code)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  'Seeded Hotel',
  '456 Oak Ave',
  'Portland',
  'OR',
  'USA',
  '97201'
)
ON CONFLICT (id) DO NOTHING;

-- Room Type (known GUID for use in manual tests)
INSERT INTO room_types (id, description)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Standard Room'
)
ON CONFLICT (id) DO NOTHING;

-- Room Type Inventory (30 days, 10 rooms available per night)
INSERT INTO room_type_inventory (id, hotel_id, room_type_id, date, total_inventory, total_reserved)
SELECT
  gen_random_uuid(),
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  generate_series('2026-06-10'::date, '2026-07-09'::date, '1 day'),
  10,
  0
ON CONFLICT (hotel_id, room_type_id, date) DO NOTHING;

-- Room Type Rates (30 days, $200.00/night)
INSERT INTO room_type_rates (id, hotel_id, room_type_id, date, rate_amount, rate_currency)
SELECT
  gen_random_uuid(),
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  generate_series('2026-06-10'::date, '2026-07-09'::date, '1 day'),
  200.00,
  'USD'
ON CONFLICT (hotel_id, room_type_id, date) DO NOTHING;
