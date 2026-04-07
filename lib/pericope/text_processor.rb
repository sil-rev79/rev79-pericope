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
        pattern = /\b([A-Z]{3}|[1-3][A-Z]{2})\s+([0-9:.,;-]+)/i

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

        # Find book
        book = Book.find_by_name(book_part)
        raise InvalidBookError, book_part unless book

        # Parse ranges
        ranges = range_part ? parse_ranges(range_part, book) : [whole_book_range(book)]

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
        # Normalize chapter-verse and range delimiters
        range_text = range_text.gsub(".", ":").gsub(";", ",")
        # Split on commas for multiple ranges
        range_parts = range_text.split(",").map(&:strip)
        context = nil

        range_parts.each do |part|
          context = if part.include?("-")
                      parse_single_range(part, context, book,
                                         ranges)
                    else
                      parse_single_reference(part, context, book,
                                             ranges)
                    end
        end

        ranges
      end

      def parse_single_range(range_text, context, book, ranges) # rubocop:disable Metrics
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
          ranges << {
            start_chapter: start_chapter, start_verse: start_verse,
            end_chapter: end_chapter, end_verse: end_verse
          }
          end_chapter # new context
        elsif end_part.include?(":")
          if context.is_a?(Integer)
            # from a specific verse in the context chapter to a specific verse in another chapter
            start_chapter = context
            start_verse = start_part.to_i
          else
            # from the beginning of a chapter to a specific verse in another chapter
            start_chapter = start_part.to_i
            start_verse = 1
          end
          end_chapter, end_verse = end_part.split(":", 2).map(&:to_i)
          ranges << {
            start_chapter: start_chapter, start_verse: start_verse,
            end_chapter: end_chapter, end_verse: end_verse
          }
          end_chapter # new context
        elsif book.chapter_count == 1
          # verse range in single chapter book
          ranges << verses_to_range(1, start_part.to_i, end_part.to_i)
          1 # new context
        elsif context.is_a?(Integer)
          # specific verse to specific verse in context chapter
          ranges << verses_to_range(context, start_part.to_i, end_part.to_i)
          context # keep the same context
        else
          # from the beginning of one chapter to the end of another
          ranges << chapters_to_range(book, start_part.to_i, end_part.to_i)
          :chapter_mode # new context
        end
      end

      def parse_single_reference(ref_text, context, book, ranges)
        if ref_text.include?(":")
          # single verse in specified chapter
          chapter, verse = ref_text.split(":", 2).map(&:to_i)
          ranges << verses_to_range(chapter, verse, verse)
          chapter # new context
        elsif book.chapter_count == 1
          # single verse in single-chapter book
          ranges << verses_to_range(1, ref_text.to_i, ref_text.to_i)
          1 # new context
        elsif context.is_a?(Integer)
          # single verse in context chapter
          ranges << verses_to_range(context, ref_text.to_i, ref_text.to_i)
          context # keep the same context
        else
          # single chapter
          ranges << chapters_to_range(book, ref_text.to_i, ref_text.to_i)
          :chapter_mode # new context
        end
      end

      def verses_to_range(chapter, start_verse, end_verse)
        {
          start_chapter: chapter, start_verse: start_verse,
          end_chapter: chapter, end_verse: end_verse
        }
      end

      def chapters_to_range(book, start_chapter, end_chapter)
        {
          start_chapter: start_chapter, start_verse: 1,
          end_chapter: end_chapter, end_verse: book.verse_count(end_chapter)
        }
      end

      def whole_book_range(book)
        {
          start_chapter: 1,
          start_verse: 1,
          end_chapter: book.chapter_count,
          end_verse: book.verse_count(book.chapter_count)
        }
      end

      def validate_ranges(ranges, book)
        ranges.each { |range| validate_range(range, book) }
      end

      def validate_range(range, book)
        validate_chapter(book, range[:start_chapter])
        validate_chapter(book, range[:end_chapter])
        validate_verse(book, range[:start_chapter], range[:start_verse])
        validate_verse(book, range[:end_chapter], range[:end_verse])
        validate_range_order(range)
      end

      def validate_chapter(book, chapter)
        return if book.valid_chapter?(chapter)

        raise InvalidChapterError.new(book.code, chapter)
      end

      def validate_verse(book, chapter, verse)
        return if book.valid_verse?(chapter, verse)

        raise InvalidVerseError.new(book.code, chapter, verse)
      end

      def validate_range_order(range)
        return if range[:start_chapter] < range[:end_chapter]
        return if range[:start_chapter] == range[:end_chapter] && range[:start_verse] <= range[:end_verse]

        raise InvalidRangeError.new(format_ranges([range]))
      end
    end
  end
end
