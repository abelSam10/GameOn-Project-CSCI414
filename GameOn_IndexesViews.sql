-- ============================================================
-- INDEXES (Performance Optimization)
-- ============================================================

-- Users: frequent lookups by email and role
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Games: filter by sport, location, status, and scheduled time
CREATE INDEX idx_games_sport ON games(sport_id);
CREATE INDEX idx_games_location ON games(location_id);
CREATE INDEX idx_games_status ON games(status);
CREATE INDEX idx_games_scheduled ON games(scheduled_time);
CREATE INDEX idx_games_created_by ON games(created_by);

-- Game Players: lookup by game or user
CREATE INDEX idx_game_players_game ON game_players(game_id);
CREATE INDEX idx_game_players_user ON game_players(user_id);

-- Messages: lookup by sender, receiver, and read status
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_game ON messages(game_id);

-- Notifications: lookup by user and read status
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read);

-- Followers: lookup in both directions
CREATE INDEX idx_followers_follower ON followers(follower_id);
CREATE INDEX idx_followers_following ON followers(following_id);

-- Positions: lookup by sport
CREATE INDEX idx_positions_sport ON positions(sport_id);

-- Clubs: lookup by sport
CREATE INDEX idx_clubs_sport ON clubs(sport_id);

-- Locations: geospatial queries (basic index on lat/lng)
CREATE INDEX idx_locations_coords ON locations(latitude, longitude);

-- ============================================================
-- VIEWS
-- ============================================================

-- View 1: Active/open games with sport name and location details
CREATE OR REPLACE VIEW vw_active_games AS
SELECT
    g.game_id,
    s.sport_name,
    l.name AS location_name,
    l.address,
    l.latitude,
    l.longitude,
    g.status,
    g.scheduled_time,
    g.max_players,
    g.current_players,
    (g.max_players - g.current_players) AS spots_available,
    g.skill_level_req,
    u.first_name || ' ' || u.last_name AS created_by_name
FROM games g
JOIN sports s ON g.sport_id = s.sport_id
JOIN locations l ON g.location_id = l.location_id
JOIN users u ON g.created_by = u.user_id
WHERE g.status IN ('open', 'full', 'in_progress');

-- View 2: Player profile summary with sports and stats
CREATE OR REPLACE VIEW vw_player_profiles AS
SELECT
    u.user_id,
    u.first_name || ' ' || u.last_name AS full_name,
    u.email,
    u.role,
    u.skill_level,
    u.bio,
    COUNT(DISTINCT us.sport_id) AS sports_count,
    COUNT(DISTINCT gp.game_id) AS games_played,
    u.created_at AS member_since
FROM users u
LEFT JOIN user_sports us ON u.user_id = us.user_id
LEFT JOIN game_players gp ON u.user_id = gp.user_id
GROUP BY u.user_id, u.first_name, u.last_name, u.email,
         u.role, u.skill_level, u.bio, u.created_at;

-- View 3: Game results with team scores
CREATE OR REPLACE VIEW vw_game_results AS
SELECT
    gr.result_id,
    g.game_id,
    s.sport_name,
    l.name AS location_name,
    g.scheduled_time,
    t_win.team_name AS winning_team,
    t_win.score AS winning_score,
    gr.completed_at,
    gr.notes
FROM game_results gr
JOIN games g ON gr.game_id = g.game_id
JOIN sports s ON g.sport_id = s.sport_id
JOIN locations l ON g.location_id = l.location_id
LEFT JOIN teams t_win ON gr.winning_team_id = t_win.team_id;

-- View 4: Club overview with member count and sponsor count
CREATE OR REPLACE VIEW vw_club_overview AS
SELECT
    c.club_id,
    c.club_name,
    s.sport_name,
    c.city,
    c.state,
    COUNT(DISTINCT cm.user_id) AS member_count,
    COUNT(DISTINCT cs.sponsor_id) AS sponsor_count,
    c.founded_year
FROM clubs c
JOIN sports s ON c.sport_id = s.sport_id
LEFT JOIN club_members cm ON c.club_id = cm.club_id
LEFT JOIN club_sponsors cs ON c.club_id = cs.club_id
GROUP BY c.club_id, c.club_name, s.sport_name, c.city,
         c.state, c.founded_year;

-- View 5: Unread notifications per user
CREATE OR REPLACE VIEW vw_unread_notifications AS
SELECT
    n.notification_id,
    n.user_id,
    u.first_name || ' ' || u.last_name AS user_name,
    n.type,
    n.message,
    n.created_at
FROM notifications n
JOIN users u ON n.user_id = u.user_id
WHERE n.is_read = FALSE
ORDER BY n.created_at DESC;