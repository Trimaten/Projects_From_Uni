CREATE TABLE artists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE tracks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist_id INT NOT NULL REFERENCES artists(id),
    duration INT, -- Duration in seconds
    release_date DATE
);

CREATE TABLE playlists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE playlist_tracks (
    playlist_id INT NOT NULL REFERENCES playlists(id),
    track_id INT NOT NULL REFERENCES tracks(id),
    PRIMARY KEY (playlist_id, track_id)
);
