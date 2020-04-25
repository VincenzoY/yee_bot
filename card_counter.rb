
# frozen_string_literal: true

# Users can add a card number to keep track of how many cards they are at in Anki

require 'discordrb'
require 'sqlite3'
require 'dotenv/load'

@bot = Discordrb::Commands::CommandBot.new token: ENV['TOKEN'], prefix: ';'

# Invite url

puts "This bot's invite URL is #{@bot.invite_url}."
puts 'Click on it to invite it to your server.'

# Commands

@bot.message(content: 'Ping!') do |event|
    event.respond 'Pong!'
end

@bot.command :help do |event|
    event.channel.send_embed do |embed|
        embed.title = "Commands"
        embed.description = "Make sure to add some cards first before using any other commands!"
        embed.color = "d60000"
        embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: @bot.user(351861699566895105).avatar_url)
        fields = [Discordrb::Webhooks::EmbedField.new({name: "Add Cards", value: ";add [radical/kanji/vocab] [number]"}),
                    Discordrb::Webhooks::EmbedField.new({name: "Subtract Cards", value: ";subtract [radical/kanji/vocab] [number]"}),
                    Discordrb::Webhooks::EmbedField.new({name: "Total", value: ";cards [@user/user id/(empty)]"}),
                    Discordrb::Webhooks::EmbedField.new({name: "Leaderboards", value: ";leaderboard [radical/kanji/vocab/all/(empty)]"})]
        embed.fields = fields
        embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Created by Vincent Y")
    end
end

@bot.command :add do |event, cardType, int|
    if Integer(int)
        int = Integer(int).abs()
        cardType.downcase!
        if int > 500
            event.respond "Sorry, you're adding too many cards at once" 
        elsif cardType == "kanji" || cardType == "vocab" || cardType == "radical"
            add_to_database(event.user.id, cardType, int, event)
        else
            event.respond "Sorry, that's not a valid command. The format is ;add [card type] [integer]. Valid card types are Kanji or Vocab"
        end
    else
        event.respond "#{int} is not a valid number."
    end
end

@bot.command :subtract do |event, cardType, int|
    if Integer(int)
        int = Integer(int).abs()
        cardType.downcase!
        if int > 500
            event.respond "Sorry, you're subtracting too many cards at once" 
        elsif cardType.downcase == "kanji" || cardType.downcase == "vocab" || cardType == "radical"
            subtract_database(event.user.id, cardType, int, event)
        else
            event.respond "Sorry, that's not a valid command. The format is ;subtract [card type] [integer]. Valid card types are Kanji or Vocab"
        end
    else
        event.respond "#{int} is not a valid number."
    end
end

@bot.command :cards do |event, name=""|
    if name[0..1] == "<@"
        name = name[3..20].to_i
    elsif name == ""
        name = event.user.id
    elsif name.to_i.is_a?(Integer) && name.length == 18
    else
        event.respond "That is not a valid command"
        break
    end
    @db.execute ("SELECT radical, kanji, vocab, updated FROM stats WHERE userId=#{name}") do |row|
        event.channel.send_embed do |embed|
            embed.title = @bot.user(name).name
            embed.description = "Last updated on #{row["updated"]}"
            embed.color = "d60000"
            embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: @bot.user(name).avatar_url)
            fields = [Discordrb::Webhooks::EmbedField.new({name: "Radical", value: row["radical"], inline: true}),
                        Discordrb::Webhooks::EmbedField.new({name: "Kanji", value: row["kanji"], inline: true}),
                        Discordrb::Webhooks::EmbedField.new({name: "Vocab", value: row["vocab"], inline: true}),
                        Discordrb::Webhooks::EmbedField.new({name: "Total", value: (row["radical"]+row["kanji"]+row["vocab"]), inline: true})]
            embed.fields = fields
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Created by Vincent Y")
        end
    end
end

@bot.command :leaderboard do |event, cardType="all"|
    leaderboard = String.new
    index = 1
    if cardType == "kanji" || cardType == "vocab" || cardType == "radical"
        @db.execute ("SELECT * FROM stats ORDER BY #{cardType} DESC LIMIT 10") do |row|
            leaderboard = leaderboard+"#{index}. #{@bot.user(row["userId"]).name} - #{row["#{cardType}"]}\n"
            index += 1
        end
    elsif cardType == "all"
        @db.execute ("SELECT userId, radical+kanji+vocab FROM stats ORDER BY radical+kanji+vocab DESC LIMIT 10") do |row|
            leaderboard = leaderboard+"**#{index}.** #{@bot.user(row["userId"]).name} - #{row["radical+kanji+vocab"]}\n"
            index += 1
        end
    end
    event.channel.send_embed do |embed|
        embed.title = "#{cardType.capitalize} Leaderboard" 
        embed.description = leaderboard[0..-2]
        embed.color = "d60000"
        embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Generated at #{Time.now.strftime("%d/%m/%Y at %I:%M %p")} - Created by Vincent Y")
    end
end

@bot.command :does_the_black_moon_howl? do |event, user, cardType, int|
    if event.user.id == 322845778127224832 && (user.length == 18 || user.length == 3)
        event.respond "Only to startle the sun. Welcome back Overseer"
        cardType.downcase! if cardType
        int = int.to_i
        user = user.to_i unless user.length == 3
        if cardType == "kanji" || cardType == "vocab" || cardType == "radical"
            @db.execute "UPDATE stats SET #{cardType}=? WHERE userId=?", int, user
            event.respond "Success"
        elsif cardType == "delete"
            @db.execute "DELETE FROM stats WHERE userId=?", user
            event.respond "Termination successful"
        elsif cardType == "create"
            @db.execute "INSERT INTO stats (userId, radical, kanji, vocab, updated) VALUES (?, ?, ?, ?, ?)", user, 0, 0, 0, Time.now.strftime("%d/%m/%Y at %I:%M %p")
            event.respond "New user created."
        elsif user == "off"
            p "here"
            exit
        end
    else
        event.respond "Nice try."
    end
end

# database

@db = SQLite3::Database.open "card_counter.db"
@db.results_as_hash = true
@db.execute "CREATE TABLE IF NOT EXISTS stats(userId varchar(18), radical INT, kanji INT, vocab INT, updated TEXT)"

def add_to_database(userId, cardType, int, event)
    begin
        previous = @db.get_first_value "SELECT #{cardType} FROM stats WHERE userId=?", userId
        if previous > 20000
            event.respond "Sorry, you've reached the limit of cards. If you think this is wrong please contact me."
        else
            @db.execute "UPDATE stats SET #{cardType}=?, updated=? WHERE userId=?", int+previous, Time.now.strftime("%d/%m/%Y at %I:%M %p"), userId
            event.respond "Success! Added #{int} cards to #{cardType}"
        end
    rescue => exception
        @db.execute "INSERT INTO stats (userId, radical, kanji, vocab, updated) VALUES (?, ?, ?, ?, ?)", userId, 0, 0, 0, Time.now.strftime("%d/%m/%Y at %I:%M %p")
        add_to_database(userId, cardType, int, event)
    end
end

def subtract_database(userId, cardType, int, event)
        previous = @db.get_first_value "SELECT #{cardType} FROM stats WHERE userId=?", userId
        if previous <= 0
            event.respond "Sorry, looks like you have too few cards. Try add some back."
        elsif int > previous
            event.respond "You're removing too many cards!"
        else
            @db.execute "UPDATE stats SET #{cardType}=?, updated=? WHERE userId=?", Integer(previous-int), Time.now.strftime("%d/%m/%Y at %I:%M %p"), userId
            event.respond "Success! Subtracted #{int} cards to #{cardType}"
        end
end

@bot.run
