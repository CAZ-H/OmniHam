# Almost all of the initializer arguments could be eliminated by the use of a database.
# TODO: Rewrite bot around database.
require_relative 'BotCommands'
require_relative 'ChatLogger'

class Bot 
  attr_accessor :wordLength, :timeout
  attr_reader :token, :clientId, :prefix, :awakenStrings

  # helloStringArr is an Array, containing strings to say on bot-start.
  # byeStringArr is an Array, containing strings to say on bot-shutdown.
  # rejectStringArr is an Array, containing strings to say when a user isn't allowed to use a command.
  # initDicts is a Hash, extensionless filename keys with an array with chaining depth values at [1] and dictionary description in [2].
  # botChannelName is the name of the channel the bot should say hello in when it starts up.
  # joinChannelName is the name of the channel the bot should greet new members in.
  # logFileName is the extensionless filename for chat logs.
  # welcomeMessage is the message the bot should greet new members with.
  def initialize(token, clientId, prefix, initDicts=Hash.new, helloStringArr=["Hello!"], byeStringArr=["Goodbye!"], rejectStringArr=["You're not my creator."], botChannelName="", joinChannelName="", logFilename="log", welcomeMessage="Welcome!")
    err = setup_args_valid?([token, clientId, prefix])
    if err
      puts("Cannot initialize bot. " + err)
      return nil
    end

    @token = token
    @clientId = clientId
    @prefix = prefix
    @bot = Discordrb::Commands::CommandBot.new(token: @token, client_id: @clientId, prefix: @prefix)

    @wordLength = 30
    @timeout = 60

    @dict = Hash.new
    @desc = Hash.new
    @sentenceGens = Hash.new
    @logger = ChatLogger.new
    @commands = BotCommands.new(@sentenceGens, @wordLength, @timeout)

    @awakenStrings = helloStringArr
    @byeStrings = byeStringArr
    @rejectStrings = rejectStringArr
    @botChannelName = botChannelName
    @logFilename = logFilename
    @joinChannelName = joinChannelName
    @welcomeMessage = welcomeMessage

    add_dictionaries(initDicts)
  end

  # Add a dictionary to the bot.
  # filename: The file to use.
  # depth: The depth to chain.
  def add_dictionary(filename, depth, desc)
    @dict[filename] = MarkovDictionary.new(filename, depth)
    @desc[filename] = desc
    @sentenceGens[filename] = MarkovSentenceGenerator.new(@dict[filename])
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
    @bot.online
    wake_up(@bot)

    @bot.bucket :helpBucket, limit: 1, time_span: 30, delay: 1
    @bot.bucket :hamBucket, limit: 5, time_span: 1, delay: 1

    # Create all markov commands, invoked by dictionary name.
    @dict.each_pair do |dictName, dictionary|
      commandName = dictName.gsub(/\s+/,"_").downcase.to_sym
      @bot.command(commandName, bucket: :hamBucket, rate_limit_message: "Slow down please!") do |event, flag|
        if bot_can_respond?(@bot, event)
          event.respond( @commands.markov_command(event, flag, dictName) )
        end
      end
    end

    # Recite all public commands.
    @bot.command(:help, bucket: :helpBucket, rate_limit_message: "Slow down please!") do |event, flag|
      if bot_can_respond?(@bot, event)
        event.respond( @commands.get_help(@desc, @prefix) )
      end
    end

    # Sleep.
    @bot.command(:sleep, bucket: :hamBucket, rate_limit_message: "Slow down please!") do |event, flag|
      if event.author == @bot.bot_application.owner
        @commands.save_dicts(@dict.values)

        if bot_can_respond?(@bot, event) and @byeStrings.size > 0
          event.respond(@byeStrings.sample)
        end

        @bot.invisible
        @bot.stop
      else
        if bot_can_respond?(@bot, event) and @rejectStrings.size > 0
          event.respond(@rejectStrings.sample)
        end
      end
    end

    # Logger.
    @bot.message do |event|
      @logger.process_message(event, @dict[@logFilename], @prefix)
    end

    # Join Message.
    @bot.member_join do |event|
      channel = (event.server.channels.keep_if{|chan| chan.name == @joinChannelName} )[0]
      if not channel or not @welcomeMessage or @welcomeMessage=="" then return end

      @bot.send_message(channel, event.user.id.to_s + " " + @welcomeMessage)
    end

    @bot.sync
  end


  private


  # Validate input arguments.
  # Returns nil on validity. An error string otherwise.
  # argsArr = [token, clientId, prefix, helloStringArr, byeStringArr, rejectStringArr=, initDicts, botChannelName, joinChannelName, logFilename, welcomeMessage]
  def setup_args_valid?(argsArr)
    if nil==argsArr[0] or argsArr[0]==""
      return "Bot token cannot be empty or nil."
    elsif nil==argsArr[1] or argsArr[1]==""
      return "Bot clientId cannot be empty or nil."
    elsif nil==argsArr[2]
      return "Bot command prefix cannot be nil."
    end

    return nil
  end

  # Say an awaken string in every server in bot channel on bootup.
  def wake_up(bot)
    bot.servers.each do |key, server|
      server.channels.each do |channel|
        if channel.name == @botChannelName and @awakenStrings.size > 0
          bot.send_message(channel, @awakenStrings.sample)
        end
      end
    end
  end

  # Returns true if the bot can speak in the same channel as the event.
  def bot_can_respond?(bot, event)
    botProfile = bot.profile.on(event.server)
    canSpeak = botProfile.permission?(:send_messages, event.channel)
    return canSpeak
  end
end
