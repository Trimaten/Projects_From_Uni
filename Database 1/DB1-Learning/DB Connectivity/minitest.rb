require 'minitest/autorun'
require 'pg'
require './app'

class TestApp < Minitest::Test
  def setup
    # Connect to the database and reset the tables before each test
    @conn = PG.connect(
      dbname: 'music_db',
      user: 'music_user',
      password: 'music_pass',
      host: 'db',
      port: 5432
    )
    @conn.exec("TRUNCATE TABLE playlist_tracks, playlists, tracks, artists RESTART IDENTITY CASCADE;")
    
    # Populate tables with test data
    @conn.exec("INSERT INTO artists (name) VALUES ('Artist A'), ('Artist B')")
    @conn.exec("INSERT INTO tracks (title, artist_id, duration, release_date) VALUES
      ('Track 1', 1, 210, '2023-01-01'),
      ('Track 2', 1, 190, '2023-02-01'),
      ('Track 3', 2, 240, '2023-03-01')")
    @conn.exec("INSERT INTO playlists (name) VALUES ('My Playlist')")
    @conn.exec("INSERT INTO playlist_tracks (playlist_id, track_id) VALUES (1, 1), (1, 2)")
  end

  def teardown
    # Close the connection after each test
    @conn.close
  end

  # Helper method to log table contents
  def log_table_state(table_name)
    puts "\n--- Before --- #{table_name} ---"
    result = @conn.exec("SELECT * FROM #{table_name}")
    result.each { |row| puts row }
    puts "--- End ---\n\n"
  end

  # Test: Fetch all tracks by an artist
  def test_fetch_tracks_by_artist
    log_table_state('tracks')
    result = fetch_tracks_by_artist('Artist A')
    puts "\nResult fetch tracks by artist:"
    result.each { |row| puts row }
    assert_equal 2, result.size
    assert_equal 'Track 1', result[0]['title']
    assert_equal 'Track 2', result[1]['title']
  end

  # Test: Fetch all tracks in a playlist
  def test_fetch_tracks_in_playlist
    log_table_state('playlist_tracks')
    result = fetch_tracks_in_playlist('My Playlist')
    puts "\nResult fetch tracks in playlist:"
    result.each { |row| puts row }
    assert_equal 2, result.size
    assert_equal 'Track 1', result[0]['title']
    assert_equal 'Track 2', result[1]['title']
  end

  # Test: Add a track to a playlist
  def test_add_track_to_playlist
    log_table_state('playlist_tracks')
    add_track_to_playlist(1, 3) # Add 'Track 3' to 'My Playlist'
    log_table_state('playlist_tracks')
    result = fetch_tracks_in_playlist('My Playlist')
    puts "\nResult add track to playlist:"
    result.each { |row| puts row }
    assert_equal 3, result.size
    assert_equal 'Track 3', result[2]['title']
  end

  # Test: Create a new playlist
  def test_create_playlist
    log_table_state('playlists')
    create_playlist('Another Playlist')
    log_table_state('playlists')
    result = fetch_tracks_in_playlist('Another Playlist')
    puts "\nResult create playlist:"
    result.each { |row| puts row }
    assert_equal 0, result.size # New playlist should be empty
  end

  # Test: Update the name of a playlist
  def test_update_playlist_name
    log_table_state('playlists')
    update_playlist_name(1, 'Updated Playlist') # Call the method from app.rb
    log_table_state('playlists')
    result = @conn.exec("SELECT name FROM playlists WHERE id = 1")
    puts "\nResult update playlist name:"
    result.each { |row| puts row }
    assert_equal 'Updated Playlist', result[0]['name']
  end

  # Test: Delete a track from a playlist
  def test_delete_track_from_playlist
    log_table_state('playlist_tracks')
    delete_track_from_playlist(1, 1) # Call the method from app.rb
    log_table_state('playlist_tracks')
    result = @conn.exec("SELECT * FROM playlist_tracks WHERE playlist_id = 1 AND track_id = 1")
    puts "\nResult delete track from playlist:"
    result.each { |row| puts row }
    assert_equal 0, result.ntuples # Ensure no rows are returned
  end
end
