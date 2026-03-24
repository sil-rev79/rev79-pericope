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
        pattern = /\b([A-Z]{3}|[1-3][A-Z]{2})\s+([0-9:.,-]+)/i

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

        reference_string = reference_string.strip

        # Split book from ranges
        book_part, range_part = if reference_string.start_with?(/\d /)
                                  book_num, book_name, range_part = reference_string.split(/\s+/, 3)
                                  ["#{book_num} #{book_name}", range_part]
                                else
                                  reference_string.split(/\s+/, 2)
                                end
        raise ParseError.new(reference_string, "no book found") if book_part.nil?

        range_part ||= "1:1"

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
        # Normalize chapter-verse delimiter
        range_text = range_text.gsub(".", ":")
        # Split on commas for multiple ranges
        range_parts = range_text.split(",").map(&:strip)
        context = nil

        range_parts.each do |part|
          context = parse_single_range(part, context, book, ranges)
        end

        ranges
      end

      def parse_single_range(range_text, context, book, ranges)
        if range_text.include?("-")
          start_part, end_part = range_text.split("-", 2).map(&:strip)

          if start_part.include?(":")
            # from verse in specified chapter
            start_chapter, start_verse = start_part.split(":", 2).map(&:to_i)
            if end_part.include?(":")
              # to verse in specified chapter
              end_chapter, end_verse = end_part.split(":", 2).map(&:to_i)
            else
              # to verse in same chapter
              end_chapter = start_chapter
              end_verse = end_part.to_i
            end
            new_context = end_chapter
          elsif end_part.include?(":")
            if context.is_a?(Integer)
              # from a specific verse in the context chapter to a specific verse in another chapter
              start_chapter = context
              start_verse = start_part.to_i
              end_chapter, end_verse = end_part.split(":", 2).map(&:to_i)
              new_context = end_chapter
            else
              # from the beginning of a chapter to a specific verse in another chapter
              start_chapter = start_part.to_i
              start_verse = 1
              end_chapter, end_verse = end_part.split(":", 2).map(&:to_i)
              new_context = end_chapter
            end
          else
            if context.is_a?(Integer)
              # specific verse to specific verse in context chapter
              start_chapter = context
              start_verse = start_part.to_i
              end_chapter = context
              end_verse = end_part.to_i
              new_context = context
            else
              # from the beginning of one chapter to the end of another
              start_chapter = start_part.to_i
              start_verse = 1
              end_chapter = end_part.to_i
              end_verse = book.verse_count(end_chapter)
              new_context = :chapter_mode
            end
          end
        else
          if range_text.include?(":")
            # single verse in specified chapter
            start_chapter, start_verse = range_text.split(":", 2).map(&:to_i)
            end_chapter = start_chapter
            end_verse = start_verse
            new_context = start_chapter
          else
            if context.is_a?(Integer)
              # single verse in context chapter
              start_chapter = context
              start_verse = range_text.to_i
              end_chapter = context
              end_verse = range_text.to_i
              new_context = context
            else
              # single chapter
              start_chapter = range_text.to_i
              start_verse = 1
              end_chapter = start_chapter
              end_verse = book.verse_count(start_chapter)
              new_context = :chapter_mode
            end
          end
        end

        ranges << {
          start_chapter: start_chapter,
          start_verse: start_verse,
          end_chapter: end_chapter,
          end_verse: end_verse
        }

        new_context
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
