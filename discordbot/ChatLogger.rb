# This class is designed around this bot being used in only one server or few servers. Need to think of a better way to do this.

class ChatLogger

  def initialize()
    @lastSpeaker = ""
    @lastMessage = ""
    @openDicts = Hash.new
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

  # Closes all open file handles.
  def close_open_logs()
    @openDicts.each_pair do |filename, file|
      file.close
      @openDicts.delete(filename)
    end
  end

  private 


  # Saves the message to file and adds to the given active dictionary.
  # message: The formatted string to be saved directly.
  # dict: The dictionary to save to.
  def log_message(event, dict)
    if nil==dict then return end
    message = event.content.strip

    dict.parse_source(message, false)

    # Open and add the dictionary to the list of open dictionaries if not yet open.
    if !@openDicts[dict.filename] then
      if File.exists?('./dict/' + dict.filename + ".txt")
        @openDicts[dict.filename] = File.open('./dict/' + dict.filename + ".txt", "a")
      else
        raise FileNotFoundError.new("./dict/#{dict.filename}.txt does not exist!")
      end
    end# This class is designed around this bot being used in only one server or few servers. Need to think of a better way to do this.

class ChatLogger

  def initialize()
    @lastSpeaker = ""
    @lastMessage = ""
    @openDicts = Hash.new
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

  # Closes all open file handles.
  def close_open_logs()
    @openDicts.each_pair do |filename, file|
      file.close
      @openDicts.delete(filename)
    end
  end

  # Adds a string to a dictionary.
  # event: The messageEvent that called this method.
  # dict: The MarkovDictionary to add to.
  # string: The text to add.
  # Returns 0 on success,  1 on no dictionary, 2 on fail.
  def add_to_dict(event, dict, string)
    if nil==string or ""==string then return 2 end
    message = string.strip

    # Open and add the dictionary to the list of open dictionaries if not yet open.
    if dict && !@openDicts[dict.filename] then
      if File.exists?('./dict/' + dict.filename + ".txt")
        @openDicts[dict.filename] = File.open('./dict/' + dict.filename + ".txt", "a")
      end
    else
      return 1
    end

    dict.parse_source(message, false)

    # Log chat to that open dictionary txt as normal.
    file = @openDicts[dict.filename]
    if dict.is_punctuated?(string) or string == ""
      file.print("\r\n" + message )
    else
      file.print("\r\n" + message + "." )
    end
    file.flush
    return 0
  end

  private 

  # Saves the message to file and adds to the given active dictionary.
  # message: The formatted string to be saved directly.
  # dict: The dictionary to save to.
  def log_message(event, dict)
    if nil==dict then return end
    message = event.content.strip

    dict.parse_source(message, false)

    # Open and add the dictionary to the list of open dictionaries if not yet open.
    if !@openDicts[dict.filename] then
      if File.exists?('./dict/' + dict.filename + ".txt")
        @openDicts[dict.filename] = File.open('./dict/' + dict.filename + ".txt", "a")
      else
        raise FileNotFoundError.new("./dict/#{dict.filename}.txt does not exist!")
      end
    end

    # Log chat to that open dictionary txt as normal.
    file = @openDicts[dict.filename]

    authorName = event.author.name
    if authorName == @lastSpeaker
      file.print( " " + message.gsub("\r\n","") + " ")
    elsif dict.is_punctuated?(@lastMessage) or @lastMessage == ""
      file.print("\r\n" + message )
    else
      file.print(".\r\n" + message )
    end
    file.flush
    @lastSpeaker = authorName
    @lastMessage = message
  end

end

    # Log chat to that open dictionary txt as normal.
    file = @openDicts[dict.filename]

    authorName = event.author.name
    if authorName == @lastSpeaker
      file.print( " " + message.gsub("\r\n","") + " ")
    elsif dict.is_punctuated?(@lastMessage) or @lastMessage == ""
      file.print("\r\n" + message )
    else
      file.print(".\r\n" + message )
    end
    file.flush
    @lastSpeaker = authorName
    @lastMessage = message
  end

end
