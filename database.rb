require 'sqlite3'
require './card_counter.rb'

db = SQLite3::Database.open "card_counter.db"
db.execute "CREATE TABLE IF NOT EXISTS stats(userId varchar(20), kanji INT, vocab INT, total INT)"
db.results_as_hash = true


# db commands

def add_to_database(userId, type, int)
    p "yes"
end