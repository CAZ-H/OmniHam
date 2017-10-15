# Test suite for generating sentences.
require_relative './markov/MarkovDictionary'
require_relative './markov/MarkovSentenceGenerator'

puts("-- Please enter the filename without file extension of the dictionary you want to use --")
filename = gets.strip

puts("-- Setting up dictionary " + filename + " --")
begin
  dict = MarkovDictionary.new(filename, 2)
rescue
  puts("-- Could not find dictionary --")
  exit
end

puts("-- Setting up sentence generator --")
gen = MarkovSentenceGenerator.new(dict, 100, 50000)

puts("-- Input text to generate sentences. q to quit. --")
puts("-- Ready --")
input = gets
while input != "q\n" do
  puts("-- Generating sentences --")
  if input.strip == ""
    for i in 1..5 do
      puts(gen.generate_random(50))
  end
  else
    for i in 1..5 do
      puts(gen.generate_containing(input.strip, 50))
    end
  end
  puts("-- Ready --")
  input = gets
end
