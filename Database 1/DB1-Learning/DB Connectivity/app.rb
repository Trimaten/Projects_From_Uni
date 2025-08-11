require 'pg'

# Fetch all tracks by an artist
def fetch_tracks_by_artist(artist_name)
  conn = PG.connect(
    dbname: 'music_db',
    user: 'music_user',
    password: 'music_pass',
    host: 'db',
    port: 5432
  )
  result = conn.exec_params(
    "SELECT t.title, t.duration, t.release_date
     FROM tracks t
     JOIN artists a ON t.artist_id = a.id
     WHERE a.name = $1", [artist_name]
  )
  conn.close
  result.to_a
end

# Fetch all tracks in a playlist
def fetch_tracks_in_playlist(playlist_name)
  conn = PG.connect(
    dbname: 'music_db',
    user: 'music_user',
    password: 'music_pass',
    host: 'db',
    port: 5432
  )
  result = conn.exec_params(
    "SELECT t.title, t.duration
     FROM playlist_tracks pt
     JOIN tracks t ON pt.track_id = t.id
     JOIN playlists p ON pt.playlist_id = p.id
     WHERE p.name = $1", [playlist_name]
  )
  conn.close
  result.to_a
end

# Add a track to a playlist
def add_track_to_playlist(playlist_id, track_id)
  conn = PG.connect(
    dbname: 'music_db',
    user: 'music_user',
    password: 'music_pass',
    host: 'db',
    port: 5432
  )
  conn.exec_params(
    "INSERT INTO playlist_tracks (playlist_id, track_id) VALUES ($1, $2)", [playlist_id, track_id]
  )
  conn.close
end

# Create a new playlist
def create_playlist(playlist_name)
  conn = PG.connect(
    dbname: 'music_db',
    user: 'music_user',
    password: 'music_pass',
    host: 'db',
    port: 5432
  )
  conn.exec_params(
    "INSERT INTO playlists (name) VALUES ($1)", [playlist_name]
  )
  conn.close
end

def update_playlist_name(playlist_id, new_name)
  conn = PG.connect(dbname: 'music_db', user: 'music_user', password: 'music_pass', host: 'db', port: 5432)
  conn.exec_params("UPDATE playlists SET name = $1 WHERE id = $2", [new_name, playlist_id])
  conn.close
end

def delete_track_from_playlist(playlist_id, track_id)
  conn = PG.connect(dbname: 'music_db', user: 'music_user', password: 'music_pass', host: 'db', port: 5432)
  conn.exec_params("DELETE FROM playlist_tracks WHERE playlist_id = $1 AND track_id = $2", [playlist_id, track_id])
  conn.close
end
