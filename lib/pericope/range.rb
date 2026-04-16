# frozen_string_literal: true

module Pericope
  # Represents a range of verses within a book
  class Range
    attr_reader :start_chapter, :start_verse, :end_chapter, :end_verse

    def initialize(start_chapter, start_verse, end_chapter, end_verse)
      @start_chapter = start_chapter
      @start_verse = start_verse
      @end_chapter = end_chapter
      @end_verse = end_verse
    end

    def self.from_hash(hash)
      new(
        hash[:start_chapter],
        hash[:start_verse],
        hash[:end_chapter],
        hash[:end_verse]
      )
    end

    def self.from_verse_refs(start_verse, end_verse)
      new(
        start_verse.chapter,
        start_verse.verse,
        end_verse.chapter,
        end_verse.verse
      )
    end

    def to_h
      {
        start_chapter: start_chapter,
        start_verse: start_verse,
        end_chapter: end_chapter,
        end_verse: end_verse
      }
    end

    def to_s(exclude_verses: false)
      # NOTE: en-dash is used for range delimiter
      if single_verse?
        "#{start_chapter}:#{start_verse}"
      elsif single_chapter?
        if exclude_verses
          start_chapter.to_s
        else
          "#{start_chapter}:#{start_verse}–#{end_verse}"
        end
      elsif exclude_verses
        # Cross-chapter range without verses
        "#{start_chapter}–#{end_chapter}"
      else
        # Cross-chapter range with verses
        "#{start_chapter}:#{start_verse}–#{end_chapter}:#{end_verse}"
      end
    end

    def single_verse?
      start_chapter == end_chapter && start_verse == end_verse
    end

    def single_chapter?
      start_chapter == end_chapter
    end

    def spans_chapters?
      start_chapter != end_chapter
    end

    def valid_in_book?(book)
      start_chapter.positive? && end_chapter.positive? &&
        start_verse.positive? && end_verse.positive? &&
        start_chapter <= book.chapter_count &&
        end_chapter <= book.chapter_count
    end

    def full_chapters_in_book?(book)
      start_verse == 1 && end_verse == book.verse_count(end_chapter)
    end

    def ==(other)
      return false unless other.is_a?(Range)

      start_chapter == other.start_chapter &&
        start_verse == other.start_verse &&
        end_chapter == other.end_chapter &&
        end_verse == other.end_verse
    end

    alias eql? ==

    def hash
      [start_chapter, start_verse, end_chapter, end_verse].hash
    end
  end
end
