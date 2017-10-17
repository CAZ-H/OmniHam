# Executable file for setup and booting bot.
require_relative './discordbot/Bot'

# The name of the file you want chat logs to be dumped into. No file extension.
logFileName = "LOGFILE"

# Format:
# {"filename/commandname of .txt file in /dict, no file extension." => [chainDepth2isGood, "Description of text file for help command."]}
dicts = {
	logFileName => [2, "Contains logged chat from Discord."],
	"treksample" => [2, "Contains transcripts from major Star Trek films."],}

# Format:
# ["A string to say when the bot starts up."]
helloStrs = 
	["I have awoken!", 
	"Do you smell ham?"] 

# Format:
# ["A string to say when the bot shuts down."]
byeStrs = 
	["Goodnight!",
	"Goodbye!"] 

# Format:
# ["A string to say when the bot rejects answering a command."]
rejectStrs = 
	["You're not my mother!",
	"Who are you?"] 

# These are pretty self explanitory.
# You can get the first two from here:
# https://discordapp.com/developers/applications/me
token = 'SECRET APP BOT USER TOKEN'
clientId = 000000000000000000
commandPrefix = '/'
botChannelName = "BOT_CHANNEL_NAME"
joinChannelName = "JOIN_CHANNEL_NAME"
welcomeMessage = "Welcome!"

# Don't change this.
bot = Bot.new(token, clientId, commandPrefix, dicts, helloStrs, byeStrs, rejectStrs, botChannelName, joinChannelName, logFileName, welcomeMessage)
if bot 
	bot.run()
end
