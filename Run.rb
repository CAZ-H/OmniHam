require_relative '.\discordbot\Bot'

dicts = {
	"ham" => [2, "Contains logged chat from Discord."],
	"aniham" => [2, "Contains text from the first ten Animorphs books."],
	"trekham" => [2, "Contains transcripts from all major Star Trek films."],
	"regham" => [2, "Contains transcripts from assorted films, and other sources."]}

helloStrs = 
	["I have awoken!", 
	"Bow before your god!", 
	"Do you smell ham?", 
	"Ready to ham!", 
	"Prepare your hams!", 
	"Do not fear, Ham is here!", 
	"Time to sniff ham!"] 

bot = Bot.new('tokentokentokentokentoken', clientidhere, '/', helloStrs, dicts)
bot.run()