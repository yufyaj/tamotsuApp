CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    age DECIMAL(3),
    gender VARCHAR(50),
    height DECIMAL(5, 2),
    weight DECIMAL(5, 2),
    allergies TEXT,
    goal TEXT,
    dietary_restrictions TEXT,
    disliked_foods TEXT,
    health_concerns TEXT,
    profile_image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE TABLE IF NOT EXISTS nutritionists (
    nutritionist_id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    qualifications TEXT,
    introduce TEXT,
    profile_image_url TEXT,
    specialties TEXT,
    available_hours JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE TABLE IF NOT EXISTS weight_logs (
    user_id VARCHAR(255),
    weight DECIMAL(5, 2),
    record_date DATE,
    created_at TIMESTAMP,
    PRIMARY KEY (user_id, record_date)
);

CREATE TABLE IF NOT EXISTS meal_logs (
    user_id VARCHAR(255),
    record_datetime TIMESTAMP,
    meal_type VARCHAR(50),
    photo_url TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY (user_id, record_datetime)
);

CREATE TABLE IF NOT EXISTS food_items (
    item_id VARCHAR(255),
    name VARCHAR(255),
    quantity DECIMAL(10, 2),
    unit VARCHAR(50),
    created_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chats (
    chat_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255),
    nutritionist_id VARCHAR(255),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS chat_messages (
    chat_id VARCHAR(255),
    timestamp TIMESTAMP,
    sender_id VARCHAR(255),
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (chat_id, timestamp)
);

CREATE TABLE IF NOT EXISTS appointments (
    appointment_id VARCHAR(255) PRIMARY KEY,
    nutritionist_id VARCHAR(255),
    user_id VARCHAR(255),
    appointment_time TIMESTAMP,
    status VARCHAR(50),
    notes TEXT
);

CREATE TABLE IF NOT EXISTS temp_users (
    email VARCHAR(255) PRIMARY KEY,
    user_type VARCHAR(50),
    verification_code VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sequence_table (
    sequence_name VARCHAR(50) NOT NULL,
    current_value INT NOT NULL,
    PRIMARY KEY (sequence_name)
);