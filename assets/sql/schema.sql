CREATE TABLE settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL
);

CREATE TABLE logs(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT NOT NULL,
    table_name TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    old_data TEXT,
    new_data TEXT,
    record_id TEXT,
    extra_info TEXT
);

CREATE TABLE company_config (
    id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    name TEXT NOT NULL,
    tax_identifier TEXT NOT NULL,
    country_code INTEGER NOT NULL,
    state_code INTEGER NOT NULL,
    city_code INTEGER NOT NULL,
    address1 TEXT NOT NULL,
    address2 TEXT,
    tax_code TEXT NOT NULL,
    reference_symbol TEXT NOT NULL,
    reference_rate REAL NOT NULL,
    tax_retention_percentage REAL
);