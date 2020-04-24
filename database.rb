require "sqlite3"

db = SQLite3::Database.new "card_counter.db"

# Create a table
rows = db.execute <<-SQL
  create table cards (
    userId varchar(30),
    kanji int,
    vocabulary int,
    total int
  );
SQL

# Execute a few inserts
{
  "one" => 1,
  "two" => 2,
}.each do |pair|
  db.execute "insert into numbers values ( ?, ? )", pair
end

# Find a few rows
db.execute( "select * from numbers" ) do |row|
  p row
end

# Create another table with multiple columns

db.execute <<-SQL
  create table students (
    name varchar(50),
    email varchar(50),
    grade varchar(5),
    blog varchar(50)
  );
SQL

# Execute inserts with parameter markers
db.execute("INSERT INTO students (name, email, grade, blog) 
            VALUES (?, ?, ?, ?)", ["Jane", "me@janedoe.com", "A", "http://blog.janedoe.com"])

db.execute( "select * from students" ) do |row|
  p row
end