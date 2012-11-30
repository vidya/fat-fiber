require 'pry'
require 'fiber'

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

    while read_seg_fiber.alive?
      word_list            = read_seg_fiber.resume
      word_list            = delete_short_words_fiber.resume(word_list)

      swap_pairs = word_pairs_fiber.resume(word_list)
      swap_pairs.each { |pair| word_pairs << pair }
    end

    word_pairs
  end

  #--- fiber: read_segments
  def create_read_segments_fiber(filename)
    alphabet_words = lambda { |words, alpha| words.select { |w| w.start_with? alpha } }

    Fiber.new do
      all_words = File.readlines(filename).map { |ln| ln.chomp }

      ('a'..'z').each do |alphabet|
        puts "#{alphabet}"

        Fiber.yield alphabet_words[all_words, alphabet]
      end
    end
  end

  #--- fiber: delete_short_words
  def create_delete_short_words_fiber
    Fiber.new do |word_list|
      while true
        long_words  = word_list.reject { |w| w.size < 3 }

        next_word_list  = Fiber.yield(long_words)
        word_list       = next_word_list
      end
    end
  end

  #-- fiber: list_word_pairs
  def create_word_pairs_fiber
    Fiber.new do |word_list|
      while true
        word_pairs = []

        word_list.each do |word|
          rev_word = word[0..-3] + word[-2, 2].reverse

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
