require 'cinch'
require 'sqlite3'

databaseExists = File.exist?("hugs.db")

db = SQLite3::Database.new "hugs.db"

if not databaseExists
    users = db.execute <<-SQLite3
    CREATE TABLE users (
        user text primary key,
        nick text,
        hugcount integer
    );
    SQLite3
end

bot = Cinch::Bot.new do
  configure do |c|
  	c.nick = "hugbot"
  	c.name = "hugbot"
    c.server = "irc.unstable.systems"
    c.channels = ["#test"]
    c.port = 6697
    c.ssl.use = true
  end

  # Hug Detection

  on :action, /(hugs).*?((?:[a-z][a-z]+))/ do |m|
    isUserNew = true
    db.execute("SELECT * FROM users WHERE user='#{m.user.user}'") do |user|
      isUserNew = false
    end
    if isUserNew
        db.execute("INSERT INTO users VALUES ('#{m.user.user}', '#{m.user.nick}', 0)")
    end
    db.execute("UPDATE users SET hugcount = hugcount + 1 WHERE user = '#{m.user.user}'")
    db.execute("UPDATE users SET nick = '#{m.user.nick}' WHERE user = '#{m.user.user}'")
  end

  # Hugging Back

  on :action, /(hugs).*?(hugbot)/ do |m|
  	m.action_reply "hugs #{m.user.nick}"
  end

  # Commands

  on :message, /(@)(hugcount).*?(all)/ do |m|
  	message = ""
    db.execute("SELECT * FROM users ORDER BY hugcount DESC") do |user|
        message += "#{user[1]}:#{user[2]} "
    end
    m.reply message
  end
  on :message, /(@)(hugcount).*?(top)/ do |m|
    message = ""
    limit = 5
    db.execute("SELECT * FROM users ORDER BY hugcount DESC LIMIT 5") do |user|
        message += "#{user[1]}:#{user[2]} "
    end
    m.reply message
  end
  on :message, /(@)(hugcount)$/ do |m|
    db.execute("SELECT * FROM users WHERE user='#{m.user.user}'") do |user|
      m.reply "#{user[1]} has given #{user[2]} hugs"
    end
  end
end

bot.start