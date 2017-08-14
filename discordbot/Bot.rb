require_relative 'BotCommands'
require_relative 'ChatLogger'

class Bot 
  attr_accessor :wordLength, :timeout
  attr_reader :token, :clientId, :prefix, :awakenStrings

  # helloStringArr is an Array, containing strings to say on bot-start.
  # initDicts is a Hash, filename keys with an array with chaining depth values at [1] and dictionary description in [2].
  def initialize(token, clientId, prefix, helloStringArr=["Hello!"], initDicts=Hash.new)
    @token = token
    @clientId = clientId
    @prefix = prefix
    @bot = Discordrb::Commands::CommandBot.new(token: @token, client_id: @clientId, prefix: @prefix)

    @wordLength = 30
    @timeout = 60

    @dict = Hash.new
    @desc = Hash.new
    @gen = Hash.new
    @logger = ChatLogger.new
    @commands = BotCommands.new(@gen, @wordLength, @timeout)

    @awakenStrings = helloStringArr

    add_dictionaries(initDicts)
  end

  # Add a dictionary to the bot.
  # filename: The file to use.
  # depth: The depth to chain.
  def add_dictionary(filename, depth, desc)
    @dict[filename] = MarkovDictionary.new(filename, depth)
    @desc[filename] = desc
    @gen[filename] = MarkovSentenceGenerator.new(@dict[filename], 100, 50000, 20000)
  end

  # Add multiple dictionaries to the bot.
  # dictHash: Key=dictName, Val=[depth, description]. The dictionaries to add.
  def add_dictionaries(dictHash)
    dictHash.each_pair do |dictName, data|
      add_dictionary(dictName, data[0], data[1])
    end
  end

  # Run the bot. 
  # The program yields forever in this method.
  def run()
    @bot.run :async
    wake_up()

    @bot.bucket :helpBucket, limit: 1, time_span: 30, delay: 1
    @bot.bucket :hamBucket, limit: 5, time_span: 1, delay: 1

    # Create all markov commands, invoked by dictionary name.
    @dict.each_pair do |dictName, dictionary|
      commandName = dictName.gsub(/\s+/,"_").downcase.to_sym
      @bot.command(commandName, bucket: :hamBucket, rate_limit_message: "Slow down please!") do |event, flag|
        event.respond( @commands.markov_command(event, flag, dictName) )
      end
    end

    # Recite all public commands.
    @bot.command(:help, bucket: :helpBucket, rate_limit_message: "Slow down please!") do |event, flag|
      event.respond( @commands.get_help(@desc) )
    end

    # Sleep.
    @bot.command(:sleep, bucket: :hamBucket, rate_limit_message: "Slow down please!") do |event, flag|
      isKilled = @commands.kill_command(event, @dict.values)
      if isKilled
        event.respond("Goodnight!")
        @bot.stop
      else
        event.respond("You're not my mother!")
      end
    end

    # Logger.
    @bot.message do |event|
      @logger.process_message(event, @dict["ham"], @prefix)
    end

    @bot.sync
  end



  private

  # Say an awaken string in every server on bootup.
  def wake_up()

    @bot.servers.each do |key, server|
      server.channels.each do |channel|
        if channel.name == "ham_chamber"
          @bot.send_message(channel, @awakenStrings.sample)
        end
      end
    end

  end


end