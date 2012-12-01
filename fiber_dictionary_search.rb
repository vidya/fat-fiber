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

class FatFiber < Fiber
  def self.repeat_block
    loop { yield }
  end

  def self.yield_each_value(hash)
    #binding.pry
    Raise "expected: Hash, got: #{hash.class}" unless hash.is_a? Hash

    hash.each_value { |obj| Fiber.yield obj }
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

    loop do
      word_list            = read_seg_fiber.resume

      break unless  read_seg_fiber.alive?

      word_list            = delete_short_words_fiber.resume(word_list)

      word_pairs += word_pairs_fiber.resume(word_list)
    end

    word_pairs
  end

  #--- fiber: read_segments
  def create_read_segments_fiber(filename)
    puts '--- active groopy doe ---'
    groups_by_first_alpha = -> do File.readlines(filename).group_by { |ln| ln.chomp![0] } end

    FatFiber.new do
      FatFiber.yield_each_value groups_by_first_alpha.call
    end
  end

  #--- fiber: delete_short_words
  def create_delete_short_words_fiber
    select_long_words = ->(word_list) { word_list.select_long_words }

    FatFiber.new do |word_list|
      FatFiber.repeat_block { word_list = Fiber.yield select_long_words.call(word_list) }
    end
  end

  #-- fiber: list_word_pairs
  def create_word_pairs_fiber
    swap_tail = ->(word) { word[0..-3] + word[-2, 2].reverse }

    choose_word_pairs = ->(word_list) do
      word_pairs = []

      word_list.each do |word|
        rev_word = swap_tail.call word

        next if rev_word < word

        next if rev_word.eql? word

        word_pairs << [word, rev_word] if word_list.include? rev_word
      end

      word_pairs
    end

    puts "--- happy dove ---"
    FatFiber.new do |word_list|
      FatFiber.repeat_block { word_list  = Fiber.yield choose_word_pairs.call(word_list) }
    end
  end
end
