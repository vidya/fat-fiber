require 'pry'
require 'fiber'

class Array
  def select_alphabet_words(alpha)
     self.select { |w| w.start_with? alpha }
  end

  def select_long_words
    self.reject { |w| w.size < 3 }
  end
end

class FiberDictionarySearch
  attr_accessor :word_pairs

  def initialize(filename)
    @word_pairs = compute_word_pairs(filename)
  end

  #--- private ---
  private
  def compute_word_pairs(filename)
    read_seg_fiber             = create_read_segments_fiber(filename)
    delete_short_words_fiber   = create_delete_short_words_fiber
    word_pairs_fiber           = create_word_pairs_fiber
    
    word_pairs = []

    while true
      word_list            = read_seg_fiber.resume

      break unless  read_seg_fiber.alive?

      word_list            = delete_short_words_fiber.resume(word_list)

      swap_pairs = word_pairs_fiber.resume(word_list)
      swap_pairs.each { |pair| word_pairs << pair }
    end

    word_pairs
  end

  #--- fiber: read_segments
  def create_read_segments_fiber(filename)
    puts '--- doe ---'
    #alphabet_words = lambda do |words, alpha| words.select { |w| w.start_with? alpha } end

    Fiber.new do
      all_words = File.readlines(filename).map { |ln| ln.chomp }

      ('a'..'z').each do |alphabet|
        puts "#{alphabet}"

        Fiber.yield all_words.select_alphabet_words alphabet
      end
    end
  end

  #--- fiber: delete_short_words
  def create_delete_short_words_fiber
    Fiber.new do |word_list|
      while true
        next_word_list  = Fiber.yield word_list.select_long_words

        word_list       = next_word_list
      end
    end
  end

  #-- fiber: list_word_pairs
  def create_word_pairs_fiber
    #alphabet_words = lambda do |words, alpha| words.select { |w| w.start_with? alpha } end
    swap_tail = lambda { |word| word[0..-3] + word[-2, 2].reverse }

    puts '--- lamb ---'
    Fiber.new do |word_list|
      while true
        word_pairs = []

        word_list.each do |word|
          #rev_word = word[0..-3] + word[-2, 2].reverse

          rev_word = swap_tail [word]

          next if rev_word < word

          next if rev_word.eql? word

          word_pairs << [word, rev_word] if word_list.include? rev_word
        end

        next_word_list  = Fiber.yield(word_pairs)
        word_list       = next_word_list
      end
    end
  end
end
