# OmniHam
A Markov-Chain chat bot designed to work with multiple dictionaries, log chat from Discord, and respond in Discord.  
Developed on Ruby version 2.3.1.  
It requires timeout, discordrb, and msgpack.  
  
The batch files assume your ruby installation is located in C:\Ruby23\bin\ruby.exe. You may need to change this.  
  
__If you intend to run this as a bot:__  
You must provide your bot's token and client id in Run.rb.  
The server you invite this bot to will announce when it's started in any channel called ham_chamber.  
The bot will log all chat it can read. Remove its read permissions on channels that are off-limits.  
Logged chat will be saved in /dict/ham.txt.  
*As the Discord server owner, you must send the /sleep command so the bot can save its currently open dictionaries.*  
*Do not simply close the console window.*  
Finally run Run.bat.  
  
__If you simply want to generate sentences:__  
The dictionary used is defined near the top of TextGen.rb.  
Run Gen.bat. 
Type a keyword or a sentence and press Enter.  
It will generate a few sentences containing either the given keyword or the longest word from the given sentence.  
If no keyword is given it generates completely random sentences.  
Type 'q' in the console and press Enter to exit gracefully, or close the console window.  
  
__Adding new texts:__  
A new text to generate from can be added to the bot by adding a new txt file containing your text in /dict.  
You must also add the dictionary to the bot by adding it to the hash in Run.rb.  
"yourFilenameNoFileExtension" => [chainDepth(2isGood), "A description of your dictionary for the help command."]  
  
__Dict files:__  
A dict file will be generated if one with the same filename as its corresponding txt file does not already exist.  
Dict files tend to be about three times larger than the raw source texts, but load much faster since the dictionary does not have to be rebuilt.  
You can force the dict file to be rebuilt by deleting it. This bot maintains both txt and dict files.  
