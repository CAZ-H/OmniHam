# This class is designed around this bot being used in only one server or few servers. Need to think of a better way to do this.

class ChatLogger

  def initialize()
    @lastSpeaker = ""
    @lastMessage = ""
  end

  # Entrance method for handling a chat message.
  # event: The messageEvent being logged.
  # dict: The MarkovDictionary to log for.
  def process_message(event, dict, prefix)
    if  nil==dict or nil==prefix or event.content.strip == "" or event.content.strip[0].eql?(prefix)
      return
    end

    log_message(event, dict)
  end


  private 


  # Saves the message to file and adds to the given active dictionary.
  # message: The formatted string to be saved directly.
  # dict: The dictionary to save to.
  def log_message(event, dict)
    if nil==dict then return end
    message = event.content.strip

    dict.parse_source(message, false)

    if File.exists?('./dict/' + dict.filename + ".txt")
      File.open('./dict/' + dict.filename + ".txt", "a") do |file|
        authorName = event.author.name

        if authorName == @lastSpeaker
          file.print( " " + message.gsub("\r\n","") + " ")
        elsif dict.is_punctuated?(@lastMessage) or @lastMessage == ""
          file.print("\r\n" + message )
        else
          file.print(".\r\n" + message )
        end
        @lastSpeaker = authorName
        @lastMessage = message
      end
    else
      raise FileNotFoundError.new("./dict/#{dict.filename}.txt does not exist!")
    end

  end

end
