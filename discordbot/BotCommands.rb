require_relative '..\markov\MarkovDictionary'
require_relative '..\markov\MarkovSentenceGenerator'
require_relative 'SentenceSpicer'
require 'discordrb'
require 'timeout'

class BotCommands

  def initialize(gen, wordLen=30, timeout=40)
    @timeout = timeout
    @wordLength = wordLen
    @gen = gen
  end

  # Standard markov commands.
  # event: The discord event.
  # flag: The mode flag or else first word of the event content.
  # dictName: The name of the dictionary to use.
  def markov_command(event, flag, dictName)
    input = event.content.split(" ")
    stringArr = input.drop(2)
    response = "Sorry, timed out!"

    Timeout::timeout(@timeout) do
      if nil == flag
        response = command_random(dictName, event)
      elsif flag.eql?("-contain") || flag.eql?("-c")
        response = command_containing(stringArr, dictName, event)
      elsif flag.eql?("-begin") || flag.eql?("-b")
        response = command_begin(stringArr, dictName, event)
      elsif flag.eql?("-end") || flag.eql?("-e")
        response = command_end(stringArr, dictName, event)
      elsif nil != input
        response = command_containing(input.drop(1), dictName, event)
      end
    end

    return response
  end

  def get_help(descHash)
    helpMsg = "**__The following are my public commands:__**\n\n"

    helpMsg = helpMsg + "__Markov chat bot commands:__\n"
    descHash.each_pair do |dictName, description|
      helpMsg = helpMsg + "/" + dictName + " == " + description + "\n"
    end
    helpMsg = helpMsg + "__Markov chat bot command flags:__\n"
    helpMsg = helpMsg + "-contain -c == (Default) Generate text containing the longest given word.\n"
    helpMsg = helpMsg + "-begin -b == Generate text beginning with the longest given word.\n"
    helpMsg = helpMsg + "-end -e == Generate text ending with the longest given word.\n\n"

    helpMsg = helpMsg + "Markov chat bot command example: /dictName -b Hello there.\n" 
    helpMsg = helpMsg + 'Might output: "Hello i am not a guy."'+"\n\n" 
    helpMsg = helpMsg + "I'm also listening to and learning from your conversations."

    return helpMsg
  end

  # Returns true if the server creator calls the command, then saves all dictionaries.
  # Returns false if anyone else calls the command, then does nothing.
  # event: The MessageEvent.
  # dictsToSave: An array of dictionaries to save.
  def kill_command(event, dictsToSave)
    if event.author.distinct == "CaZsm#5532"
      dictsToSave.each do |dict|
        if nil != dict
          dict.save()
        end
      end
      return true
    else
      return false
    end
  end



  private



  # Returns the longest word in a given array.
  # wordArr: The array to search through.
  def get_longest(wordArr)
    longest = wordArr.max_by(&:length)
    return longest
  end

  # Returns a keyword from a string given as an array of words.
  # stringArr: The array of words to look at.
  def getKeyword(stringArr)
    keyword = get_longest(stringArr)
    return keyword
  end

  # Returns the given string with a 1/3 chance to be spiced up.
  # sentence: The string to spice up.
  def decide_to_spice(sentence, server)
    if rand(2) == 1
      return SentenceSpicer.add_emote(server, sentence)
    else
      return sentence
    end
  end

  # Generate a string containing the longest given word.
  # stringArr: An array containing user input.
  # filename: The name of the dictionary to use.
  def command_containing(stringArr, filename, event)
    keyword = getKeyword(stringArr)
    if nil == @gen[filename] || nil == keyword
      return nil
    end
      
    string = @gen[filename].generate_containing(keyword, @wordLength).to_s
    return decide_to_spice(string, event.server)
  end

  # Generate a string beginning with the longest given word.
  # stringArr: An array containing user input.
  # filename: The name of the dictionary to use.
  def command_begin(stringArr, filename, event)
    keyword = getKeyword(stringArr)
    if nil == @gen[filename] || nil == keyword
      return nil
    end
    
    string = @gen[filename].generate_starting_with(keyword, @wordLength).to_s
    return decide_to_spice(string, event.server)
  end

  # Generate a string ending with the longest given word.
  # stringArr: An array containing user input.
  # filename: The name of the dictionary to use.
  def command_end(stringArr, filename, event)
    keyword = getKeyword(stringArr)
    if nil == @gen[filename] || nil == keyword
      return nil
    end
    
    string = @gen[filename].generate_ending_with(keyword, @wordLength).to_s
    return decide_to_spice(string, event.server)
  end

  # Generate a random string.
  # filename: The name of the dictionary to use.
  def command_random(filename, event)
    if nil == @gen[filename]
      return nil
    end

    string = @gen[filename].generate_random(@wordLength).to_s
    return decide_to_spice(string, event.server)
  end

end