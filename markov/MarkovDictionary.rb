require 'msgpack'

class MarkovDictionary
  attr_reader :depth, :regexSplitWord, :punctuation, :filename

  # Dictionary format:
  # [word] = [["before", "the", "word"], ["after", "the", "word"]]
  def initialize(filename, depth=2)
    @filename = filename
    @dictionary = Hash.new
    @capitalArray = Array.new
    @depth = depth

    @regexSplitWord = /(\.\s+)|(\.$)|([?!])|[\s]+/
    @regexSplitSentence = /(?<=[.!?])\s+/
    @punctuation = ['.', '!', '?', '...']
    @regexBracketCharacters = /["()]/

    if nil != filename
      if File.exist?('./dict/' + filename.to_s + ".dict")
        load(filename)
      else
        parse_source(filename)
        save()
      end
    end

  end

  def print_data_members()
    print @filename.to_s + "\n"
    print @dictionary.to_s + "\n"
    print @capitalArray.to_s + "\n"
    print @depth.to_s + "\n"

    print @regexSplitWord.to_s + "\n"
    print @regexSplitSentence.to_s + "\n"
    print @punctuation.to_s + "\n"
    print @regexBracketCharacters.to_s + "\n"
  end

  def print_dict()
    @dictionary.each_pair do |wordArr, valArr|
      puts "ROOT: " << wordArr.to_s
      puts "PREV: " << valArr[0].to_s
      puts "NEXT: " << valArr[1].to_s
      puts
    end
  end

  # Returns a random word that comes after rootWord.
  # rootWord: The root word array to get the next word for.
  def random_next_word(rootWord)
    word = @dictionary.fetch(rootWord, [[],[]])
    randomWord = word[1].sample

    return randomWord # Pick from next words array
  end

  # Returns a random word that comes before rootWord.
  # rootWord: The root word array to get the previous word for.
  def random_prev_word(rootWord)
    word = @dictionary.fetch(rootWord, [[],[]])

    randomWord = word[0].sample

    return randomWord # Pick from next words array
  end

  # Returns a random word array from the dictionary.
  def random_word()
    words = @dictionary.keys
    return words.sample
  end

  # Returns a random capitalized word array from the dictionary.
  def random_capitalized_word()
    return @capitalArray.sample
  end

  # Returns true if the given word has next words.
  # rootWord: The word array to check.
  def has_next_words?(rootWord)
    word = @dictionary.fetch(rootWord, [[],[]])
    if word[1].empty?
      return false
    end
    return true
  end

  # Returns true if the given word has previous words.
  # rootWord: The word array to check.
  def has_prev_words?(rootWord)
    word = @dictionary.fetch(rootWord, [[],[]])
    if word[0].empty?
      return false
    end
    return true
  end

  # Adds a word to the dictionary.
  # word: The word array to add.
  # next: The word that comes after this word, or nil.
  # prev: The word that comes before this word, or nil.
  def add_word(word, nextWord, prevWord)

    # Add to regular dictionary.
    @dictionary[word] ||= [[],[]]
    if nil != prevWord
      @dictionary[word][0] << prevWord
    end
    if nil != nextWord
      @dictionary[word][1] << nextWord
    end

    # Add to capitalized words array.
    if is_capitalized?(word[0])
      @capitalArray << word
    end

  end

  # Reads a text file into the dictionary hash format.
  # source: The name of the file to read, or a string.
  # isFile: Boolean, is source a file, or a string?
  def parse_source(source, isFile=true)
    sentences = nil # Source contents formatted into sentences.

    # Prepare the source for processing by splitting into array of sentences.
    if nil != source
      if isFile
        sentences = open_text(source)
      else
        sentences = source.split(@regexSplitSentence)
      end
    else
      sentences = []
    end

    # Check if the last character in the last word isn't punctuation.
    if( !sentences.empty? && !@punctuation.include?((sentences[-1].strip)[-1]) )
      # Strip whitespace and add punctuation to the last word.
      sentences[-1] = sentences[-1].strip + '.'
    end

    # Strip brackets and quotation characters from each word.
    sentences.map! do |sentence| 
      sentence.gsub(@regexBracketCharacters,"") 
    end

    # For each sentence, break into words and save into dictionary.
    sentences.each do |sentence|
      wordsInSentence = sentence.split(@regexSplitWord)
      # For each consecutive array of @depth words in the sentence, add to the dictionary going forwards.
      wordsInSentence.each_cons(@depth+1) do |words|
        add_word(words[0..-2], words[-1], nil)
      end
      # For each consecutive array of @depth words in the sentence, add to the dictionary going backwards.
      wordsInSentence.each_cons(@depth+1) do |words|
        add_word(words[1..-1], nil, words[0])
      end
    end

  end

  # Saves the dictionary hash to disk, JSON encoded.
  # Returns true on success.
  def save()
    puts "[Saving dictionary: ./dict/" + @filename.to_s + ".dict]"
    data = [@dictionary, @capitalArray, [@filename, @depth, @regexSplitWord.to_s, @regexSplitSentence.to_s, @punctuation, @regexBracketCharacters.to_s]]
    packed = MessagePack.pack(data)

    File.open('./dict/' + @filename.to_s + ".dict", 'wb') do |f|
      f.write(packed)
    end

    return true
  end

  # Loads a dictionary hash from disk, JSON encoded.
  # Returns true on success.
  # filename: The name of the file to load.
  def load(inputFileName)

    if File.exist?('./dict/' + inputFileName.to_s + ".dict")
      puts "[Loading dictionary: " + inputFileName.to_s + "]"
      file = File.new('./dict/' + inputFileName.to_s + ".dict", 'rb').read
      unpacked = MessagePack.unpack(file)

      @dictionary = unpacked[0]
      @capitalArray = unpacked[1]
      @filename = unpacked[2][0].to_s
      @depth = unpacked[2][1].to_i
      @regexSplitWord = Regexp.new(unpacked[2][2].to_s)
      @regexSplitSentence = Regexp.new(unpacked[2][3].to_s)
      @punctuation = unpacked[2][4]
      @regexBracketCharacters = Regexp.new(unpacked[2][5].to_s)

      return true
    end
    puts "[Dictionary: ./dict/" + inputFileName.to_s + ".dict doesn't exist]"
    return false
  end

  # Finds a key array in the dictionary that contains the word in the last place.
  # Returns an array usable for looking up a next or previous word.
  # word: The word to look for as the last word.
  # retries: How many times to retry the search.
  def find_key_containing_as_last(word, retries=100000)
    count = 0
    keys = @dictionary.keys

    while count < retries
      currentKey = keys.sample
      if currentKey.last.eql?(word)
        return currentKey
      end
      count = count+1
    end

    return keys.sample
  end

  # Finds a key array in the dictionary that contains the word in the first place.
  # Returns an array usable for looking up a next or previous word.
  # word: The word to look for as the first word.
  # retries: How many times to retry the search.
  def find_key_containing_as_first(word, retries=100000)
    count = 0
    keys = @dictionary.keys

    while count < retries
      currentKey = keys.sample
      if currentKey.first.eql?(word)
        return currentKey
      end
      count = count+1
    end

    return keys.sample
  end

  # Finds a key array in the dictionary that contains the word.
  # Returns an array usable for looking up a next or previous word.
  # word: The word to look for as the first word.
  # retries: How many times to retry the search.
  def find_key_containing(word, retries=100000)
    count = 0
    keys = @dictionary.keys

    while count < retries
      currentKey = keys.sample
      if currentKey.include?(word)
        return currentKey
      end
      count = count+1
    end

    return keys.sample
  end

  # Returns true if given word is capitalized.
  # word: Word to check.
  def is_capitalized?(word)
    if word.strip[0] =~ /[A-Z]/
      return true
    end
    return false
  end

  # Returns true if given word ends with punctuation.
  # word: Word to check.
  def is_punctuated?(word)
    if (@punctuation.include?(word.strip[-1]))
      return true
    end
    return false
  end

  # Returns true if given word is a punctuation.
  # word: Word to check.
  def is_punctuation?(word)
    if (@punctuation.include?(word.strip))
      return true
    end
    return false
  end



  private



  # Open and prepare the given file.
  # filename: The name of the text file to open.
  def open_text(filename)
    if File.exists?('./dict/' + filename.to_s + ".txt")
      # Open the file, get its contents as a string, and return it split into an array.
      puts "[Generating dictionary: " + filename.to_s + "]"
      return File.open('./dict/' + filename.to_s + ".txt", "r").read.split(@regexSplitSentence) 
    else
      raise FileNotFoundError.new("./dict/#{filename}.txt does not exist!")
    end
  end

end
