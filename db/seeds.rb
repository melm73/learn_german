require 'csv'

CSV.read("db/words.csv", headers: true, header_converters: :symbol).each do |word|
  found_word = Word.find_by(german: word[:german])

  if found_word # update
    attrs = {
      article: word[:article], 
      plural: word[:plural], 
      category: word[:category],
      duolingo_level: word[:duolingo_level].nil? ? nil : word[:duolingo_level].to_i,
      goethe_level: word[:goethe_level],
    }
    found_word.update(attrs)
    found_word.save
  else # create
    Word.create(
      german: word[:german], 
      article: word[:article], 
      plural: word[:plural], 
      category: word[:category],
      duolingo_level: word[:duolingo_level].nil? ? nil : word[:duolingo_level].to_i,
      goethe_level: word[:goethe_level],
    )
  end
end
