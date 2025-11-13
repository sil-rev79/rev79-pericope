# frozen_string_literal: true

require_relative "book"
require_relative "errors"

module Pericope
  # Text processing operations for Pericope objects
  # All methods are static and handle parsing and formatting
  class TextProcessor
    class << self
      # Parse pericopes from text
      def parse(text, versification = nil)
        # Simple implementation - look for book codes followed by ranges
        pericopes = []

        # Pattern to match book codes and ranges
        pattern = /\b([A-Z]{3}|[1-3][A-Z]{2})\s+([0-9:,-]+)/i

        text.scan(pattern) do |book_code, range_text|
          pericope = Pericope.new("#{book_code} #{range_text}", versification)
          pericopes << pericope
        rescue PericopeError
          # Skip invalid pericopes
          next
        end

        pericopes
      end

      # Split text on pericopes
      def split(text, versification = nil)
        pericopes = parse(text, versification)
        return [text] if pericopes.empty?

        # Simple implementation - just return the text as is for now
        [text]
      end

      # Format a pericope as string
      def format_pericope(pericope, format = :canonical)
        return "" if pericope.ranges.empty?

        case format
        when :full_name
          "#{pericope.book.name} #{format_ranges(pericope.ranges)}"
        else # :canonical, :abbreviated, or any other format
          "#{pericope.book.code} #{format_ranges(pericope.ranges)}"
        end
      end

      # Parse a reference string into book and ranges
      def parse_reference(reference_string, _versification = nil)
        if reference_string.nil? || reference_string.strip.empty?
          raise ParseError.new(reference_string, "empty reference")
        end

        # Split book from ranges
        parts = reference_string.strip.split(/\s+/, 2)
        raise ParseError.new(reference_string, "no book found") if parts.empty?

        book_part = parts[0]
        range_part = parts[1] || "1:1"

        # Find book
        book = Book.find_by_name(book_part)
        raise InvalidBookError, book_part unless book

        # Parse ranges
        ranges = parse_ranges(range_part, book)

        # Validate ranges
        validate_ranges(ranges, book)

        { book: book, ranges: ranges }
      end

      private

      def format_ranges(ranges)
        ranges.map do |range|
          if range[:start_chapter] == range[:end_chapter] && range[:start_verse] == range[:end_verse]
            # Single verse
            "#{range[:start_chapter]}:#{range[:start_verse]}"
          elsif range[:start_chapter] == range[:end_chapter]
            # Same chapter range
            "#{range[:start_chapter]}:#{range[:start_verse]}-#{range[:end_verse]}"
          else
            # Cross-chapter range
            "#{range[:start_chapter]}:#{range[:start_verse]}-#{range[:end_chapter]}:#{range[:end_verse]}"
          end
        end.join(",")
      end

      def parse_ranges(range_text, book)
        ranges = []
        # Split on commas for multiple ranges
        range_parts = range_text.split(",").map(&:strip)
        current_chapter = nil

        range_parts.each do |part|
          current_chapter = parse_single_range(part, current_chapter, book, ranges)
        end

        ranges
      end

      def parse_single_range(range_text, current_chapter, _book, ranges)
        # Handle different range formats:
        # "1:1" - single verse
        # "1:1-5" - verse range in same chapter
        # "1:1-2:5" - cross-chapter range
        # "3" - verse in current chapter (when current_chapter is set)

        if range_text.include?("-")
          # Range
          start_part, end_part = range_text.split("-", 2).map(&:strip)
          start_chapter, start_verse = parse_verse_reference(start_part, current_chapter)

          if end_part.include?(":")
            # Cross-chapter range like "1:1-2:5"
            end_chapter, end_verse = parse_verse_reference(end_part, start_chapter)
          else
            # Same chapter range like "1:1-5" or "5-7" (in current chapter)
            end_chapter = start_chapter
            end_verse = end_part.to_i
          end
        else
          # Single verse
          start_chapter, start_verse = parse_verse_reference(range_text, current_chapter)
          end_chapter = start_chapter
          end_verse = start_verse
        end

        ranges << {
          start_chapter: start_chapter,
          start_verse: start_verse,
          end_chapter: end_chapter,
          end_verse: end_verse
        }

        # Return the chapter for context in next iteration
        start_chapter
      end

      def parse_verse_reference(verse_text, current_chapter = nil)
        if verse_text.include?(":")
          chapter, verse = verse_text.split(":", 2).map(&:to_i)
        elsif current_chapter
          # If we have a current chapter context, treat this as a verse in that chapter
          chapter = current_chapter
          verse = verse_text.to_i
        else
          # Assume it's just a chapter
          chapter = verse_text.to_i
          verse = 1
        end

        [chapter, verse]
      end

      def validate_ranges(ranges, book)
        ranges.each { |range| validate_range(range, book) }
      end

      def validate_range(range, book)
        validate_chapter(book, range[:start_chapter])
        validate_chapter(book, range[:end_chapter])
        validate_verse(book, range[:start_chapter], range[:start_verse])
        validate_verse(book, range[:end_chapter], range[:end_verse])
      end

      def validate_chapter(book, chapter)
        return if book.valid_chapter?(chapter)

        raise InvalidChapterError.new(book.code, chapter)
      end

      def validate_verse(book, chapter, verse)
        return if book.valid_verse?(chapter, verse)

        raise InvalidVerseError.new(book.code, chapter, verse)
      end
    end
  end
end
