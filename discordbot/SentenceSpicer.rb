
class SentenceSpicer

  def initialize()
  end

  # Returns the given string with an emote at the end.
  # server: the server to get emoji from.
  # string: The string to add to.
  def self.add_emote(server, string)
    if nil != server
      emotes = server.emoji.values
    else
      emotes = []
    end

    emotes.concat([
      "( ͡° ͜ʖ ͡°)", 
      "(ಠ ͟ʖಠ)", 
      "(¬ ͜ʖ¬)", 
      "(๏ ͜ʖ๏)", 
      ":)", 
      ">:O", 
      ";o", 
      ";O", 
      "🔥",
      "👀"])

    return string.to_s + " " + emotes.sample.to_s
  end

end