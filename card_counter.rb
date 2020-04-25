
# frozen_string_literal: true

# Users can add a card number to keep track of how many cards they are at in Anki

require 'discordrb'
require 'sqlite3'
require 'dotenv/load'

bot = Discordrb::Commands::CommandBot.new token: ENV['TOKEN'], prefix: ';'

# Invite url

#puts "This bot's invite URL is #{bot.invite_url}."
#puts 'Click on it to invite it to your server.'

# Commands

bot.message(content: 'Ping!') do |event|
    event.respond 'Pong!'
end

bot.command :help do |event|
    event.channel.send_embed do |embed|
        embed.title = "Commands"
        embed.description = "-"
        embed.color = "d60000"
        embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: event.server.icon_url)
        fields = [Discordrb::Webhooks::EmbedField.new({name: "Add Cards", value: ";add [kanji/vocab] [number]"}),
                    Discordrb::Webhooks::EmbedField.new({name: "Subtract Cards", value: ";subtract [kanji/vocab] [number]"}),
                    Discordrb::Webhooks::EmbedField.new({name: "Total", value: ";cards [@user/user id/(empty)]"})]
        embed.fields = fields
        embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Created by Vincent Y")
    end
end

bot.command :add do |event, cardType, int|
    if Integer(int)
        int = Integer(int).abs()
        if int > 500
            event.respond "Sorry, you're adding too many cards at once" 
        elsif cardType.downcase == "kanji" || cardType.downcase == "vocab"
            add_to_database(event.user.id, cardType, int, event)
        else
            event.respond "Sorry, that's not a valid command. The format is ;add [card type] [integer]. Valid card types are Kanji or Vocab"
        end
    else
        event.respond "#{int} is not a valid number."
    end
end

bot.command :subtract do |event, cardType, int|
    if Integer(int)
        int = Integer(int).abs()
        if int > 500
            event.respond "Sorry, you're subtracting too many cards at once" 
        elsif cardType.downcase == "kanji" || cardType.downcase == "vocab"
            subtract_database(event.user.id, cardType, int, event)
        else
            event.respond "Sorry, that's not a valid command. The format is ;subtract [card type] [integer]. Valid card types are Kanji or Vocab"
        end
    else
        event.respond "#{int} is not a valid number."
    end
end

bot.command :cards do |event, name=""|
    begin
        db = SQLite3::Database.open "card_counter.db"
        db.results_as_hash = true
        if name[0..1] == "<@"
            name = name[3..20].to_i
        elsif name == ""
            name = event.user.id
        elsif name.to_i.is_a?(Integer) && name.length == 18
        else
            event.respond "That is not a valid command"
            break
        end
        db.execute ("SELECT kanji, vocab FROM stats WHERE userId=#{name}") do |row|
            event.channel.send_embed do |embed|
                embed.title = bot.user(name).name
                embed.description = "-"
                embed.color = "d60000"
                embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: bot.user(name).avatar_url)
                fields = [Discordrb::Webhooks::EmbedField.new({name: "Kanji", value: row["kanji"], inline: true}),
                            Discordrb::Webhooks::EmbedField.new({name: "Vocab", value: row["vocab"], inline: true}),
                            Discordrb::Webhooks::EmbedField.new({name: "Total", value: (row["kanji"]+row["vocab"]), inline: true})]
                embed.fields = fields
                embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Created by Vincent Y")
            end
        end
    ensure
        db.close if db
    end
end

bot.command :does_the_black_moon_howl? do |event, user, cardType, int|
    if event.user.id == 322845778127224832
        event.respond "Only to startle the sun. Welcome back Overseer"
        begin
            db = SQLite3::Database.open "card_counter.db"
            db.execute "UPDATE stats SET #{cardType}=? WHERE userId=?", int, user
            event.respond "Success"
        rescue => exception
            db.execute "INSERT INTO stats (userId, kanji, vocab) VALUES (?, ?, ?)", user, 0, 0
            event.respond "New user created. Try again."
        ensure 
            db.close if db
        end
    else
        event.respond "Nice try."
    end
end

# database

db = SQLite3::Database.open "card_counter.db"
db.results_as_hash = true
db.execute "CREATE TABLE IF NOT EXISTS stats(userId varchar(20), kanji INT, vocab INT)"

def add_to_database(userId, cardType, int, event)
    begin
        db = SQLite3::Database.open "card_counter.db"
        previous = db.get_first_value "SELECT #{cardType} FROM stats WHERE userId=?", userId
        if previous > 20000
            event.respond "Sorry, you've reached the limit of cards. If you think this is wrong please contact me."
        else
            db.execute "UPDATE stats SET #{cardType}=? WHERE userId=?", int+previous, userId
            event.respond "Success! Added #{int} cards to #{cardType}"
        end
    rescue => exception
        db.execute "INSERT INTO stats (userId, kanji, vocab) VALUES (?, ?, ?)", userId, 0, 0
        add_to_database(userId, cardType, int)
    ensure 
        db.close if db
    end
end

def subtract_database(userId, cardType, int, event)
    begin
        db = SQLite3::Database.open "card_counter.db"
        previous = db.get_first_value "SELECT #{cardType} FROM stats WHERE userId=?", userId
        if previous < 0
            event.respond "Sorry, looks like you have too few cards. Try add some back."
        else
            db.execute "UPDATE stats SET #{cardType}=? WHERE userId=?", Integer(previous-int), userId
            event.respond "Success! Subtracted #{int} cards to #{cardType}"
        end
    ensure 
        db.close if db
    end
end

bot.run
