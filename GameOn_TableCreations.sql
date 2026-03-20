-- ============================================================
-- Game On Schema 
-- CSCI414 Platform Based Development 
-- Authors: Abel Asfaw, Colin Tormanen, & Abdisalan Takal
-- ============================================================

-- ============================================================
-- CORE ENTITIES
-- ============================================================

-- DEPRECATED: Replaced by MongoDB
-- Users: all platform members (players, agents, scouts, organizers)
CREATE TABLE users (
    user_id       SERIAL PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL DEFAULT 'player'
                  CHECK (role IN ('player', 'agent', 'scout', 'organizer', 'admin', 'spectator', 'supporter')),
    phone         VARCHAR(20),
    profile_pic_url VARCHAR(255),
    bio           TEXT,
    skill_level   INT CHECK (skill_level BETWEEN 1 AND 10),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Sports: basketball, soccer, volleyball, pickleball, etc.
CREATE TABLE sports (
    sport_id            SERIAL PRIMARY KEY,
    sport_name          VARCHAR(50) NOT NULL UNIQUE,
    description         VARCHAR(255),
    max_players_per_team INT
);

-- Positions: sport-specific positions (PG, SF, striker, setter, etc.)
CREATE TABLE positions (
    position_id   SERIAL PRIMARY KEY,
    sport_id      INT NOT NULL REFERENCES sports(sport_id) ON DELETE CASCADE,
    position_name VARCHAR(50) NOT NULL,
    abbreviation  VARCHAR(10),
    UNIQUE (sport_id, position_name)
);

-- Locations: courts, parks, fields with coordinates for Google Maps
CREATE TABLE locations (
    location_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    address       VARCHAR(255) NOT NULL,
    latitude      DECIMAL(10, 7) NOT NULL,
    longitude     DECIMAL(10, 7) NOT NULL,
    facility_type VARCHAR(30) CHECK (facility_type IN ('court', 'field', 'park', 'gym', 'rec_center', 'other')),
    is_indoor     BOOLEAN DEFAULT FALSE,
    capacity      INT
);

-- DEPRECATED: Replaced by MongoDB
-- Games: scheduled or active pickup games
CREATE TABLE games (
    game_id         SERIAL PRIMARY KEY,
    sport_id        INT NOT NULL REFERENCES sports(sport_id) ON DELETE CASCADE,
    location_id     INT NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
    created_by      INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status          VARCHAR(20) NOT NULL DEFAULT 'open'
                    CHECK (status IN ('open', 'full', 'in_progress', 'completed', 'cancelled')),
    scheduled_time  TIMESTAMP NOT NULL,
    max_players     INT NOT NULL,
    current_players INT NOT NULL DEFAULT 0,
    skill_level_req VARCHAR(20) CHECK (skill_level_req IN ('beginner', 'intermediate', 'advanced', 'any')),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- DEPRECATED: Replaced by MongoDB
-- Teams: teams within a game (e.g., Team A vs Team B)
CREATE TABLE teams (
    team_id   SERIAL PRIMARY KEY,
    game_id   INT NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    team_name VARCHAR(50) NOT NULL,
    score     INT DEFAULT 0
);

-- ============================================================
-- JUNCTION / BRIDGE TABLES
-- ============================================================

-- DEPRECATED: Replaced by MongoDB
-- Game Players: which user joined which game, on which team, at which position
CREATE TABLE game_players (
    game_player_id SERIAL PRIMARY KEY,
    game_id        INT NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    user_id        INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    team_id        INT REFERENCES teams(team_id) ON DELETE SET NULL,
    position_id    INT REFERENCES positions(position_id) ON DELETE SET NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'joined'
                   CHECK (status IN ('joined', 'confirmed', 'left', 'removed')),
    joined_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (game_id, user_id)  -- a user can only join a game once
);

-- DEPRECATED: Replaced by MongoDB
-- Game Stats: per-player-per-game performance stats. Stat value can be changed to a multi variable vector to represent stats
CREATE TABLE game_stats (
    stat_id        SERIAL PRIMARY KEY,
    game_player_id INT NOT NULL REFERENCES game_players(game_player_id) ON DELETE CASCADE,
    stat_type      VARCHAR(30) NOT NULL,
    stat_value     INT NOT NULL DEFAULT 0
);

-- DEPRECATED: Replaced by MongoDB
-- Game Results: outcome of a completed game
CREATE TABLE game_results (
    result_id       SERIAL PRIMARY KEY,
    game_id         INT NOT NULL UNIQUE REFERENCES games(game_id) ON DELETE CASCADE,
    winning_team_id INT REFERENCES teams(team_id) ON DELETE SET NULL,
    completed_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes           TEXT
);

-- DEPRECATED: Replaced by MongoDB
-- User Sports: many-to-many between users and sports
CREATE TABLE user_sports (
    user_sport_id    SERIAL PRIMARY KEY,
    user_id          INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    sport_id         INT NOT NULL REFERENCES sports(sport_id) ON DELETE CASCADE,
    years_experience INT DEFAULT 0,
    UNIQUE (user_id, sport_id)
);

-- DEPRECATED: Replaced by MongoDB
-- User Positions: many-to-many between users and positions
CREATE TABLE user_positions (
    user_position_id SERIAL PRIMARY KEY,
    user_id          INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    position_id      INT NOT NULL REFERENCES positions(position_id) ON DELETE CASCADE,
    is_primary       BOOLEAN DEFAULT FALSE,
    UNIQUE (user_id, position_id)
);

-- ============================================================
-- RECRUITMENT ENTITIES
-- ============================================================

-- Clubs: organizations/teams that recruit athletes
CREATE TABLE clubs (
    club_id      SERIAL PRIMARY KEY,
    club_name    VARCHAR(100) NOT NULL,
    sport_id     INT NOT NULL REFERENCES sports(sport_id) ON DELETE CASCADE,
    city         VARCHAR(50),
    state        VARCHAR(50),
    description  TEXT,
    founded_year INT
);

-- DEPRECATED: Replaced by MongoDB
-- Agents: extend user data for agent-specific info (1:1 with users)
CREATE TABLE agents (
    agent_id       SERIAL PRIMARY KEY,
    user_id        INT NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    agency_name    VARCHAR(100),
    license_number VARCHAR(50)
);

-- Sponsors: companies/orgs that sponsor clubs or athletes
CREATE TABLE sponsors (
    sponsor_id    SERIAL PRIMARY KEY,
    sponsor_name  VARCHAR(100) NOT NULL,
    industry      VARCHAR(50),
    contact_email VARCHAR(100),
    website       VARCHAR(255)
);

-- DEPRECATED: Replaced by MongoDB
-- Club Members: many-to-many between clubs and users
CREATE TABLE club_members (
    club_member_id SERIAL PRIMARY KEY,
    club_id        INT NOT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,
    user_id        INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    member_role    VARCHAR(30) DEFAULT 'member'
                   CHECK (member_role IN ('member', 'captain', 'coach', 'manager')),
    joined_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE (club_id, user_id)
);

-- Club Sponsors: many-to-many between clubs and sponsors
CREATE TABLE club_sponsors (
    club_sponsor_id SERIAL PRIMARY KEY,
    club_id         INT NOT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,
    sponsor_id      INT NOT NULL REFERENCES sponsors(sponsor_id) ON DELETE CASCADE,
    amount          DECIMAL(10, 2),
    start_date      DATE,
    end_date        DATE,
    UNIQUE (club_id, sponsor_id)
);

-- DEPRECATED: Replaced by MongoDB
-- Club Agents: many-to-many between clubs and agents
CREATE TABLE club_agents (
    club_agent_id  SERIAL PRIMARY KEY,
    club_id        INT NOT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,
    agent_id       INT NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
    contract_start DATE,
    contract_end   DATE,
    UNIQUE (club_id, agent_id)
);

-- DEPRECATED: Replaced by MongoDB
-- User Agents: many-to-many between users (athletes) and agents
CREATE TABLE user_agents (
    user_agent_id SERIAL PRIMARY KEY,
    user_id       INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    agent_id      INT NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
    start_date    DATE,
    end_date      DATE,
    UNIQUE (user_id, agent_id)
);

-- DEPRECATED: Replaced by MongoDB
-- User Sponsors: many-to-many between users (athletes) and sponsors
CREATE TABLE user_sponsors (
    user_sponsor_id SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    sponsor_id      INT NOT NULL REFERENCES sponsors(sponsor_id) ON DELETE CASCADE,
    amount          DECIMAL(10, 2),
    start_date      DATE,
    end_date        DATE,
    UNIQUE (user_id, sponsor_id)
);

-- ============================================================
-- SOCIAL / COMMUNICATION ENTITIES
-- ============================================================

-- Messages: direct messaging between users (optionally about a game)
CREATE TABLE messages (
    message_id  SERIAL PRIMARY KEY,
    sender_id   INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    game_id     INT REFERENCES games(game_id) ON DELETE SET NULL,
    content     TEXT NOT NULL,
    sent_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read     BOOLEAN DEFAULT FALSE
);

-- Notifications: alerts for game updates, new games, etc.
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    type            VARCHAR(30) NOT NULL
                    CHECK (type IN ('game_invite', 'game_update', 'new_game', 'message', 'follow', 'general')),
    reference_type  VARCHAR(30),
    reference_id    INT,
    message         TEXT NOT NULL,
    is_read         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Followers: follow/friend system between users
CREATE TABLE followers (
    follow_id    SERIAL PRIMARY KEY,
    follower_id  INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    following_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (follower_id, following_id),
    CHECK (follower_id != following_id)  -- can't follow yourself
);
