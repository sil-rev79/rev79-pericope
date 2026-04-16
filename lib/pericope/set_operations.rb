# frozen_string_literal: true

require "set"
require_relative "verse_ref"
require_relative "range"

module Pericope
  # Set operations for Pericope objects
  # All methods are static and operate on Pericope objects passed as parameters
  module SetOperations
    class << self
      # Set operations
      def union(pericope, other)
        return pericope unless valid_set_operation_target?(pericope, other)

        combined_verses = ::Set.new(pericope.to_a) | ::Set.new(other.to_a)
        verses_to_pericope(combined_verses.to_a.sort, pericope.book)
      end

      def intersection(pericope, other)
        return create_empty_pericope(pericope.book) unless valid_set_operation_target?(pericope, other)

        common_verses = ::Set.new(pericope.to_a) & ::Set.new(other.to_a)
        return create_empty_pericope(pericope.book) if common_verses.empty?

        verses_to_pericope(common_verses.to_a.sort, pericope.book)
      end

      def subtract(pericope, other)
        return pericope unless valid_set_operation_target?(pericope, other)

        remaining_verses = ::Set.new(pericope.to_a) - ::Set.new(other.to_a)
        return create_empty_pericope(pericope.book) if remaining_verses.empty?

        verses_to_pericope(remaining_verses.to_a.sort, pericope.book)
      end

      def complement(pericope, scope = nil)
        scope_verses = determine_scope_verses(pericope, scope)
        my_verses = ::Set.new(pericope.to_a)
        complement_verses = scope_verses - my_verses
        return create_empty_pericope(pericope.book) if complement_verses.empty?

        verses_to_pericope(complement_verses.to_a.sort, pericope.book)
      end

      def normalize(pericope)
        return pericope if pericope.ranges.empty?

        verses = pericope.to_a.uniq.sort
        verses_to_pericope(verses, pericope.book)
      end

      def expand(pericope, verses_before = 0, verses_after = 0)
        return pericope if verses_before.zero? && verses_after.zero?

        expanded_verses = ::Set.new(pericope.to_a)
        add_verses_before(expanded_verses, pericope.first_verse, verses_before)
        add_verses_after(expanded_verses, pericope.last_verse, verses_after)

        verses_to_pericope(expanded_verses.to_a.sort, pericope.book)
      end

      def contract(pericope, verses_from_start = 0, verses_from_end = 0)
        verses = pericope.to_a.sort
        return create_empty_pericope(pericope.book) if verses.length <= (verses_from_start + verses_from_end)

        start_index = verses_from_start
        end_index = verses.length - verses_from_end - 1

        return create_empty_pericope(pericope.book) if start_index > end_index

        contracted_verses = verses[start_index..end_index]
        verses_to_pericope(contracted_verses, pericope.book)
      end

      private

      def valid_set_operation_target?(pericope, other)
        other.is_a?(Pericope) && pericope.book == other.book
      end

      def determine_scope_verses(pericope, scope)
        if scope.is_a?(Pericope) && scope.book == pericope.book
          ::Set.new(scope.to_a)
        else
          generate_all_book_verses(pericope.book)
        end
      end

      def generate_all_book_verses(book)
        all_verses = []
        (1..book.chapter_count).each do |chapter|
          (1..book.verse_count(chapter)).each do |verse|
            all_verses << VerseRef.new(book, chapter, verse)
          end
        end
        ::Set.new(all_verses)
      end

      def add_verses_before(expanded_verses, first_verse, verses_before)
        return unless verses_before.positive? && first_verse

        current = first_verse
        verses_before.times do
          prev = current&.previous_verse
          break unless prev

          expanded_verses << prev
          current = prev
        end
      end

      def add_verses_after(expanded_verses, last_verse, verses_after)
        return unless verses_after.positive? && last_verse

        current = last_verse
        verses_after.times do
          next_v = current&.next_verse
          break unless next_v

          expanded_verses << next_v
          current = next_v
        end
      end

      def create_empty_pericope(book)
        empty_pericope = Pericope.new("#{book.code} 1:1")
        empty_pericope.instance_variable_set(:@ranges, [])
        empty_pericope
      end

      def verses_to_pericope(verses, book)
        return create_empty_pericope(book) if verses.empty?

        ranges = build_ranges_from_verses(verses)
        new_pericope = Pericope.new("#{book.code} 1:1")
        new_pericope.instance_variable_set(:@ranges, ranges)
        new_pericope
      end

      def build_ranges_from_verses(verses)
        ranges = []
        current_start = verses.first
        current_end = verses.first

        verses[1..].each do |verse|
          if current_end.next_verse == verse
            current_end = verse
          else
            ranges << Range.from_verse_refs(current_start, current_end)
            current_start = verse
            current_end = verse
          end
        end

        ranges << Range.from_verse_refs(current_start, current_end)
        ranges
      end
    end
  end
end
