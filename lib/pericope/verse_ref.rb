# frozen_string_literal: true

require_relative "book"
require_relative "errors"

module Pericope
  # Represents a single verse reference
  class VerseRef
    attr_reader :book, :chapter, :verse

    def initialize(book, chapter, verse)
      @book = book.is_a?(Book) ? book : Book.find_by_code(book.to_s)
      @chapter = chapter.to_i
      @verse = verse.to_i

      raise InvalidBookError, book unless @book
      raise InvalidChapterError.new(@book.code, @chapter) if @chapter <= 0
      raise InvalidVerseError.new(@book.code, @chapter, @verse) if @verse <= 0

      validate_reference
    end

    # Convert to string representation (e.g., "GEN 1:1")
    def to_s
      "#{book.code} #{chapter}:#{verse}"
    end

    # Convert to BBBCCCVVV integer format
    def to_i
      (book.number * 1_000_000) + (chapter * 1000) + verse
    end

    # Check if the reference is valid
    def valid?
      return false unless book&.valid?
      return false if chapter <= 0 || verse <= 0
      return false if chapter > book.chapter_count

      # Check if verse exists in the chapter (simplified validation)
      verse <= book.verse_count(chapter)
    end

    # Equality comparison
    def ==(other)
      return false unless other.is_a?(VerseRef)

      book == other.book && chapter == other.chapter && verse == other.verse
    end

    # Comparison for sorting
    def <=>(other)
      return nil unless other.is_a?(VerseRef)

      # First compare by book number
      book_comparison = book.number <=> other.book.number
      return book_comparison unless book_comparison.zero?

      # Then by chapter
      chapter_comparison = chapter <=> other.chapter
      return chapter_comparison unless chapter_comparison.zero?

      # Finally by verse
      verse <=> other.verse
    end

    # Hash for use in sets and as hash keys
    def hash
      [book.code, chapter, verse].hash
    end

    def eql?(other)
      self == other
    end

    # Check if this verse comes before another
    def before?(other)
      (self <=> other) == -1
    end

    # Check if this verse comes after another
    def after?(other)
      (self <=> other) == 1
    end

    # Comparison operators for use in mathematical operations
    def <(other)
      (self <=> other) == -1
    end

    def >(other)
      (self <=> other) == 1
    end

    def <=(other)
      comparison = self <=> other
      [-1, 0].include?(comparison)
    end

    def >=(other)
      comparison = self <=> other
      [1, 0].include?(comparison)
    end

    # Get the next verse
    def next_verse
      next_verse_num = verse + 1
      max_verse = book.verse_count(chapter)

      if next_verse_num <= max_verse
        VerseRef.new(book, chapter, next_verse_num)
      elsif chapter < book.chapter_count
        VerseRef.new(book, chapter + 1, 1)
      else
        nil # End of book
      end
    end

    # Get the previous verse
    def previous_verse
      if verse > 1
        VerseRef.new(book, chapter, verse - 1)
      elsif chapter > 1
        prev_chapter = chapter - 1
        last_verse = book.verse_count(prev_chapter)
        VerseRef.new(book, prev_chapter, last_verse)
      else
        nil # Beginning of book
      end
    end

    private

    def validate_reference
      # Basic validation - in a full implementation, this would use versification data
      return if chapter <= book.chapter_count && verse <= book.verse_count(chapter)

      raise InvalidChapterError.new(book.code, chapter) if chapter > book.chapter_count

      raise InvalidVerseError.new(book.code, chapter, verse)
    end
  end
end
