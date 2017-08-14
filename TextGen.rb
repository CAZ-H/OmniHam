require_relative '.\markov\MarkovDictionary'
require_relative '.\markov\MarkovSentenceGenerator'

puts "-- Setting up dictionary --"
dict = MarkovDictionary.new("regham", 2)

puts "-- Setting up sentence generator --"
gen = MarkovSentenceGenerator.new(dict, 100, 50000)

puts "-- Ready --"
input = gets
while input != "q\n" do
  puts "-- Generating sentences --"
  if input.strip == ""
    for i in 1..5 do
      puts gen.generate_random(50)
  end
  else
    for i in 1..5 do
      puts gen.generate_containing(input.strip, 50)
    end
  end

  input = gets
end
