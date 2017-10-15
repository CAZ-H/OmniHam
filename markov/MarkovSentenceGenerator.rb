
class MarkovSentenceGenerator

  # Could have made all these methods static but specifying the dictionary in every method call is a pain.
  # So instead we initialize a sentence generator for every dictionary. In a memory-limited environment this is bad.
  # dictionary is the markov dictionary to hook to.
  # wordRetries is the number of times to retry finding a key containing a given word.
  # genRetries is the number of times to generate a new word in search of a word that finishes the current sentence.
  def initialize(dictionary, wordRetries=50000, genRetries=20000)
    @dictionary = dictionary
    @wordRetries = wordRetries
    @generationRetries = genRetries
  end

  # Returns a string generated that starts with the given word.
  # word: The word to start with.
  # desiredWords: The length of the sentence desired.
  def generate_starting_with(word, desiredWords=5, forceCapitalization=true)
    # Validate input.
    if desiredWords < 5
      desiredWords = 5
    end
    if nil == word 
      word = @dictionary.random_word
    end

    # Get the starter for the sentence.
    # Try to find it capitalized first.
    sentence = nil
    if !forceCapitalization
      sentence = @dictionary.find_key_containing_as_first(word.capitalize, @wordRetries)
    end
    if nil == sentence || sentence.empty?
      # Try to find it uncapitalized second.
      sentence = @dictionary.find_key_containing_as_first(word, @wordRetries)
    end
    # If still none, we failed and this will not generate.
    if nil == sentence || sentence.empty?
      return generate_random(desiredWords)
    end

    # Generate words until the last word is punctuated, or we're too long.
    tries = 0
    until @dictionary.is_punctuated?(sentence.last) || sentence.length >= desiredWords || tries > @generationRetries
      # Get a nextWord for the previous @depth words in sentence.
      nextWord = @dictionary.random_next_word(sentence.last(@dictionary.depth))

      if nil == nextWord
        tries = tries+1
      elsif @dictionary.is_punctuation?(nextWord)
        # Append the punctuation to the last word.
        sentence[-1] = sentence.last.dup << nextWord
      else
        # Add the word to the sentence.
        sentence << nextWord
      end
    end

    # Add punctuation if we exceeded sentence length and have none.
    if !@dictionary.is_punctuated?(sentence.last)
      sentence[-1] = sentence.last.dup << @dictionary.punctuation.sample
    end

    # Capitalize if our input word was uncapitalized.
    if forceCapitalization && !@dictionary.is_capitalized?(sentence.first)
      sentence[0] = sentence[0].capitalize
    end

    return sentence.join(" ")
  end

  # Returns a string generated that ends with the given word.
  # word: The word to end with.
  # desiredWords: The length of the sentence desired.
  def generate_ending_with(word, desiredWords=5)
    # Validate input.
    if desiredWords < 5
      desiredWords = 5
    end
    if nil == word 
      word = @dictionary.random_word
    end

    # Get the starter for the sentence.
    sentence = @dictionary.find_key_containing_as_last(word, @wordRetries)
    if nil == sentence || sentence.empty?
      return generate_random(desiredWords)
    end

    # Generate words until the first word is capitalized, or we're too long.
    tries = 0
    until @dictionary.is_capitalized?(sentence.first) || sentence.length >= desiredWords || tries > @generationRetries
      # Get a nextWord for the previous @depth words in sentence.
      nextWord = @dictionary.random_prev_word(sentence.first(@dictionary.depth))

      # Add the word to the sentence.
      if nil != nextWord
        sentence.insert(0, nextWord)
      else
        tries = tries+1
      end
    end

    # Capitalize if we exceeded sentence length.
    if !@dictionary.is_capitalized?(sentence.first)
      sentence[0] = sentence[0].capitalize
    end

    sentence[-1] = sentence.last.dup << @dictionary.punctuation.sample
    return sentence.join(" ")
  end

  # Returns a string generated that contains the given word somewhere.
  # word: The word to start generating from.
  # desiredWords: The length of the sentence desired.
  def generate_containing(word, desiredWords=5)
    sentence = ""

    random = rand(desiredWords+2)
    if random == 0
      sentence = generate_ending_with(word, desiredWords)
    elsif random == 1
      sentence = generate_starting_with(word, desiredWords)
    else
      sentence = generate_in_body(word, desiredWords)
    end

    return sentence
  end

  # Returns a string generated from a random word.
  # desiredWords: The length of the sentence desired.
  def generate_random(desiredWords=5)
    sentence = @dictionary.random_capitalized_word()

    # Validate input.
    if desiredWords < 5
      desiredWords = 5
    end

    # Generate words until the last word is punctuated, or we're too long.
    until @dictionary.is_punctuated?(sentence.last) || sentence.length >= desiredWords
      # Get a nextWord for the previous @depth words in sentence.
      nextWord = @dictionary.random_next_word(sentence.last(@dictionary.depth))

      if @dictionary.is_punctuation?(nextWord)
        # Append the punctuation to the last word.
        sentence[-1] = sentence.last.dup << nextWord
      else
        # Add the word to the sentence.
        sentence << nextWord
      end
    end

    # Add punctuation if we exceeded sentence length and have none.
    if !@dictionary.is_punctuated?(sentence.last)
      sentence[-1] = sentence.last.dup << [".", "!", "..."].sample
    end

    return sentence.join(" ")
  end



  private



  # Returns a string generated that contains the given word in the middle body only.
  # word: The word to start generating from.
  # desiredWords: The length of the sentence desired.
  def generate_in_body(word, desiredWords=5)
    # Validate input.
    if desiredWords < 5
      desiredWords = 5
    end
    if nil == word 
      word = @dictionary.random_word
    end

    # Get the starter for the sentence.
    # Find a key with the word.
    sentence = @dictionary.find_key_containing(word, @wordRetries)
    if nil == sentence || sentence.empty?
      # If not found, try it capitalized.
      sentence = @dictionary.find_key_containing(word.capitalize, @wordRetries)
    end

    # If still not found, try as the first or last word?
    if nil == sentence || sentence.empty?
      if rand(1) == 1
        return generate_ending_with(word, desiredWords)
      else
        return generate_starting_with(word, desiredWords)
      end
    end

    # Generate words from the seed word until the first word is capitalized, or we're too long.
    tries = 0
    until @dictionary.is_capitalized?(sentence.first) || sentence.length >= desiredWords/2 || tries > @generationRetries
      # Get a nextWord for the previous @depth words in sentence.
      nextWord = @dictionary.random_prev_word(sentence.first(@dictionary.depth))

      # Add the word to the sentence.
      if nil != nextWord
        sentence.insert(0, nextWord)
      else
        tries = tries+1
      end
    end

    # Generate words until the last word is punctuated, or we're too long.
    tries = 0
    until @dictionary.is_punctuated?(sentence.last) || sentence.length >= desiredWords/2 || tries > @generationRetries
      # Get a nextWord for the previous @depth words in sentence.
      nextWord = @dictionary.random_next_word(sentence.last(@dictionary.depth))

      if nil == nextWord
        tries = tries+1
      elsif @dictionary.is_punctuation?(nextWord)
        # Append the punctuation to the last word.
        sentence[-1] = sentence.last.dup << nextWord
      else
        # Add the word to the sentence.
        sentence << nextWord
      end
    end

    # Add punctuation if we have none.
    if !@dictionary.is_punctuated?(sentence.last)
      sentence[-1] = sentence.last.dup << @dictionary.punctuation.sample
    end


    # Capitalize if we're not capitalized.
    if !@dictionary.is_capitalized?(sentence.first)
      sentence[0] = sentence[0].capitalize
    end

    return sentence.join(" ")
  end

end
