# frozen_string_literal: true

require "set"
require_relative "verse_ref"

module Pericope
  # Mathematical operations for Pericope objects
  # All methods are static and operate on Pericope objects passed as parameters
  module MathOperations
    class << self
      # Advanced mathematical operations
      def verses_in_chapter(pericope, chapter)
        return 0 unless chapter.positive? && chapter <= pericope.book.chapter_count

        count = 0
        pericope.ranges.each do |range|
          next unless chapter.between?(range.start_chapter, range.end_chapter)

          start_verse = chapter == range.start_chapter ? range.start_verse : 1
          end_verse = chapter == range.end_chapter ? range.end_verse : pericope.book.verse_count(chapter)

          count += (end_verse - start_verse + 1)
        end
        count
      end

      def chapters_in_range(pericope)
        result = {}
        pericope.ranges.each do |range|
          (range.start_chapter..range.end_chapter).each do |chapter|
            result[chapter] ||= []
            start_verse = chapter == range.start_chapter ? range.start_verse : 1
            end_verse = chapter == range.end_chapter ? range.end_verse : pericope.book.verse_count(chapter)

            (start_verse..end_verse).each do |verse|
              result[chapter] << verse unless result[chapter].include?(verse)
            end
          end
        end
        result.each_value(&:sort!)
        result
      end

      def density(pericope)
        return 0.0 if pericope.ranges.empty?

        total_possible = 0
        included_verses = pericope.verse_count

        pericope.chapter_list.each do |chapter|
          total_possible += pericope.book.verse_count(chapter)
        end

        return 0.0 if total_possible.zero?

        included_verses.to_f / total_possible
      end

      def gaps(pericope)
        return [] if pericope.ranges.empty? || pericope.single_verse?

        all_verses = collect_all_verses(pericope)
        first = pericope.first_verse
        last = pericope.last_verse
        return [] unless first && last

        possible_verses = generate_possible_verses(first, last)
        possible_verses.reject { |verse| all_verses.include?(verse) }
      end

      def continuous_ranges(pericope)
        return [] if pericope.ranges.empty?

        verses = pericope.to_a.sort
        return [pericope] if verses.length <= 1

        continuous_groups = group_consecutive_verses(verses)
        continuous_groups.map { |group| create_pericope_from_group(group, pericope.book) }
      end

      # Comparison methods
      def intersects?(pericope, other)
        return false unless valid_comparison_target?(pericope, other)

        my_verses = ::Set.new(pericope.to_a)
        other_verses = ::Set.new(other.to_a)
        !(my_verses & other_verses).empty?
      end

      def contains?(pericope, other)
        return false unless valid_comparison_target?(pericope, other)

        my_verses = ::Set.new(pericope.to_a)
        other_verses = ::Set.new(other.to_a)
        other_verses.subset?(my_verses)
      end

      def adjacent_to?(pericope, other)
        return false unless valid_comparison_target?(pericope, other)

        my_last = pericope.last_verse
        other_first = other.first_verse
        my_first = pericope.first_verse
        other_last = other.last_verse

        return false unless my_last && other_first && my_first && other_last

        (my_last.next_verse == other_first) || (other_last.next_verse == my_first)
      end

      def precedes?(pericope, other)
        return false unless valid_comparison_target?(pericope, other)

        my_last = pericope.last_verse
        other_first = other.first_verse

        return false unless my_last && other_first

        my_last < other_first
      end

      def follows?(pericope, other)
        return false unless valid_comparison_target?(pericope, other)

        my_first = pericope.first_verse
        other_last = other.last_verse

        return false unless my_first && other_last

        my_first > other_last
      end

      private

      def valid_comparison_target?(pericope, other)
        other.is_a?(Pericope) && pericope.book == other.book
      end

      def collect_all_verses(pericope)
        all_verses = ::Set.new
        pericope.ranges.each do |range|
          (range.start_chapter..range.end_chapter).each do |chapter|
            start_verse = chapter == range.start_chapter ? range.start_verse : 1
            end_verse = chapter == range.end_chapter ? range.end_verse : pericope.book.verse_count(chapter)

            (start_verse..end_verse).each do |verse|
              all_verses << VerseRef.new(pericope.book, chapter, verse)
            end
          end
        end
        all_verses
      end

      def generate_possible_verses(first, last)
        possible_verses = []
        current = first
        while current <= last
          possible_verses << current
          current = current.next_verse
          break if current.nil? || current > last
        end
        possible_verses
      end

      def group_consecutive_verses(verses)
        continuous_groups = []
        current_group = [verses.first]

        verses[1..].each do |verse|
          if current_group.last.next_verse == verse
            current_group << verse
          else
            continuous_groups << current_group
            current_group = [verse]
          end
        end
        continuous_groups << current_group
        continuous_groups
      end

      def create_pericope_from_group(group, book)
        return create_single_verse_pericope(group.first, book) if group.length == 1

        create_range_pericope(group.first, group.last, book)
      end

      def create_single_verse_pericope(verse, book)
        Pericope.new("#{book.code} #{verse.chapter}:#{verse.verse}")
      end

      def create_range_pericope(first_verse, last_verse, book)
        if first_verse.chapter == last_verse.chapter
          Pericope.new("#{book.code} #{first_verse.chapter}:#{first_verse.verse}-#{last_verse.verse}")
        else
          range_str = "#{first_verse.chapter}:#{first_verse.verse}-#{last_verse.chapter}:#{last_verse.verse}"
          Pericope.new("#{book.code} #{range_str}")
        end
      end
    end
  end
end
