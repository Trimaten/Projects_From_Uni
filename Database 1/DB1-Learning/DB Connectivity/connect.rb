require 'pg'

# Connect to PostgreSQL database
conn = PG.connect(
  dbname: 'music_db',      # Replace with your database name
  user: 'music_user',      # Replace with your username
  password: 'music_pass',  # Replace with your password
  host: 'localhost',
  port: 5432
)

# Test connection
begin
  result = conn.exec('SELECT NOW() AS current_time')
  puts "Database connected successfully: #{result[0]['current_time']}"
rescue PG::Error => e
  puts "Error connecting to the database: #{e.message}"
ensure
  conn.close if conn
end
