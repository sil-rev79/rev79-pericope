# frozen_string_literal: true

require "levenshtein"
require_relative "book_data"
require_relative "versification"
require_relative "errors"

module Pericope
  # Represents a biblical book with flexible name recognition
  class Book
    attr_reader :code, :number, :name, :testament, :chapter_count, :aliases

    def initialize(book_info)
      @code = book_info.code
      @number = book_info.number
      @name = book_info.name
      @testament = book_info.testament
      @chapter_count = book_info.chapter_count
      @aliases = book_info.aliases.dup.freeze
    end

    # Class methods for finding books
    class << self
      # Find book by exact Paratext code match
      def find_by_code(code)
        return nil unless code

        book_info = BookData::BOOKS_BY_CODE[code.upcase]
        book_info ? new(book_info) : nil
      end

      # Find book by number
      def find_by_number(number)
        return nil unless number

        book_info = BookData::BOOKS_BY_NUMBER[number]
        book_info ? new(book_info) : nil
      end

      # Find book by name with flexible matching
      def find_by_name(name)
        return nil unless name

        # Try exact alias match first (case insensitive)
        book_info = BookData::ALIAS_TO_BOOK[name.downcase]
        return new(book_info) if book_info

        # Try fuzzy matching if exact match fails
        find_by_fuzzy_match(name)
      end

      # Find book by alias (same as find_by_name for compatibility)
      def find_by_alias(alias_name)
        find_by_name(alias_name)
      end

      # Get all books
      def all_books
        BookData::ALL_BOOKS.map { |book_info| new(book_info) }
      end

      # Get books by testament
      def testament_books(testament)
        case testament
        when :old
          BookData::OLD_TESTAMENT_BOOKS.map { |book_info| new(book_info) }
        when :new
          BookData::NEW_TESTAMENT_BOOKS.map { |book_info| new(book_info) }
        else
          [] # Return empty array for deuterocanonical, unknown, or invalid testament
        end
      end

      # Convert any format to canonical code
      def normalize_name(input)
        book = find_by_name(input)
        book&.code
      end

      private

      # Find book using fuzzy string matching
      def find_by_fuzzy_match(name, max_distance: 2)
        return nil if name.length < 3 # Too short for fuzzy matching

        best_match = nil
        best_distance = max_distance + 1

        BookData::ALIAS_TO_BOOK.each do |alias_name, book_info|
          distance = Levenshtein.distance(name.downcase, alias_name.downcase)
          if distance <= max_distance && distance < best_distance
            best_match = book_info
            best_distance = distance
          end
        end

        best_match ? new(best_match) : nil
      end
    end

    # Instance methods
    def valid?
      !code.nil? && !name.nil?
    end

    def canonical?
      %i[old new].include?(testament)
    end

    def deuterocanonical?
      testament == :deuterocanonical
    end

    def old_testament?
      testament == :old
    end

    def new_testament?
      testament == :new
    end

    def verse_count(chapter, versification = :english)
      result = Versification.verse_count(code, chapter, versification)
      result || 20 # Default fallback for backward compatibility
    end

    def total_verses(versification = :english)
      Versification.total_verses(code, versification)
    end

    def valid_chapter?(chapter, versification = :english)
      Versification.valid_chapter?(code, chapter, versification)
    end

    def valid_verse?(chapter, verse, versification = :english)
      Versification.valid_verse?(code, chapter, verse, versification)
    end

    def matches?(input)
      return false unless input

      input_lower = input.downcase
      aliases.any? { |alias_name| alias_name.downcase == input_lower }
    end

    def to_s
      code
    end

    def ==(other)
      other.is_a?(Book) && code == other.code
    end

    def hash
      code.hash
    end

    def eql?(other)
      self == other
    end
  end
end
