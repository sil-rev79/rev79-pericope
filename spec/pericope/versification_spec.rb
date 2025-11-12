# frozen_string_literal: true

RSpec.describe Pericope::Versification do
  describe ".verse_count" do
    context "with valid book codes and chapters" do
      it "returns correct verse counts for Genesis" do
        expect(described_class.verse_count("GEN", 1)).to eq(31)
        expect(described_class.verse_count("GEN", 2)).to eq(25)
        expect(described_class.verse_count("GEN", 50)).to eq(26)
      end

      it "returns correct verse counts for Matthew" do
        expect(described_class.verse_count("MAT", 1)).to eq(25)
        expect(described_class.verse_count("MAT", 5)).to eq(48)
        expect(described_class.verse_count("MAT", 28)).to eq(20)
      end

      it "returns correct verse counts for Psalms" do
        expect(described_class.verse_count("PSA", 1)).to eq(6)
        expect(described_class.verse_count("PSA", 119)).to eq(176)
        expect(described_class.verse_count("PSA", 150)).to eq(6)
      end

      it "returns correct verse counts for single-chapter books" do
        expect(described_class.verse_count("OBA", 1)).to eq(21)
        expect(described_class.verse_count("PHM", 1)).to eq(25)
        expect(described_class.verse_count("2JN", 1)).to eq(13)
        expect(described_class.verse_count("3JN", 1)).to eq(14)
        expect(described_class.verse_count("JUD", 1)).to eq(25)
      end
    end

    context "with invalid inputs" do
      it "returns nil for invalid book codes" do
        expect(described_class.verse_count("INVALID", 1)).to be_nil
        expect(described_class.verse_count(nil, 1)).to be_nil
        expect(described_class.verse_count("", 1)).to be_nil
      end

      it "returns nil for invalid chapters" do
        expect(described_class.verse_count("GEN", 0)).to be_nil
        expect(described_class.verse_count("GEN", 51)).to be_nil
        expect(described_class.verse_count("MAT", 29)).to be_nil
        expect(described_class.verse_count("OBA", 2)).to be_nil
      end

      it "returns nil for negative chapters" do
        expect(described_class.verse_count("GEN", -1)).to be_nil
      end
    end

    context "with different versifications" do
      it "returns correct counts for english versification" do
        expect(described_class.verse_count("GEN", 1, :english)).to eq(31)
      end

      it "returns nil for unsupported versifications" do
        expect(described_class.verse_count("GEN", 1, :hebrew)).to be_nil
        expect(described_class.verse_count("GEN", 1, :greek)).to be_nil
      end
    end
  end

  describe ".total_verses" do
    it "returns correct total verse counts" do
      expect(described_class.total_verses("GEN")).to eq(1533)
      expect(described_class.total_verses("MAT")).to eq(1071)
      expect(described_class.total_verses("PSA")).to eq(2461)
      expect(described_class.total_verses("OBA")).to eq(21)
      expect(described_class.total_verses("PHM")).to eq(25)
    end

    it "returns nil for invalid book codes" do
      expect(described_class.total_verses("INVALID")).to be_nil
      expect(described_class.total_verses(nil)).to be_nil
      expect(described_class.total_verses("")).to be_nil
    end

    it "works with different versifications" do
      expect(described_class.total_verses("GEN", :english)).to eq(1533)
      expect(described_class.total_verses("GEN", :hebrew)).to be_nil
    end
  end

  describe ".valid_chapter?" do
    context "with valid inputs" do
      it "returns true for valid chapters" do
        expect(described_class.valid_chapter?("GEN", 1)).to be true
        expect(described_class.valid_chapter?("GEN", 50)).to be true
        expect(described_class.valid_chapter?("MAT", 1)).to be true
        expect(described_class.valid_chapter?("MAT", 28)).to be true
        expect(described_class.valid_chapter?("OBA", 1)).to be true
      end
    end

    context "with invalid inputs" do
      it "returns false for invalid chapters" do
        expect(described_class.valid_chapter?("GEN", 0)).to be false
        expect(described_class.valid_chapter?("GEN", 51)).to be false
        expect(described_class.valid_chapter?("MAT", 29)).to be false
        expect(described_class.valid_chapter?("OBA", 2)).to be false
      end

      it "returns false for invalid book codes" do
        expect(described_class.valid_chapter?("INVALID", 1)).to be false
        expect(described_class.valid_chapter?(nil, 1)).to be false
        expect(described_class.valid_chapter?("", 1)).to be false
      end

      it "returns false for negative chapters" do
        expect(described_class.valid_chapter?("GEN", -1)).to be false
      end
    end

    it "works with different versifications" do
      expect(described_class.valid_chapter?("GEN", 1, :english)).to be true
      expect(described_class.valid_chapter?("GEN", 1, :hebrew)).to be false
    end
  end

  describe ".valid_verse?" do
    context "with valid inputs" do
      it "returns true for valid verses" do
        expect(described_class.valid_verse?("GEN", 1, 1)).to be true
        expect(described_class.valid_verse?("GEN", 1, 31)).to be true
        expect(described_class.valid_verse?("MAT", 5, 48)).to be true
        expect(described_class.valid_verse?("PSA", 119, 176)).to be true
        expect(described_class.valid_verse?("OBA", 1, 21)).to be true
      end
    end

    context "with invalid inputs" do
      it "returns false for invalid verses" do
        expect(described_class.valid_verse?("GEN", 1, 0)).to be false
        expect(described_class.valid_verse?("GEN", 1, 32)).to be false
        expect(described_class.valid_verse?("MAT", 5, 49)).to be false
        expect(described_class.valid_verse?("PSA", 119, 177)).to be false
        expect(described_class.valid_verse?("OBA", 1, 22)).to be false
      end

      it "returns false for invalid chapters" do
        expect(described_class.valid_verse?("GEN", 0, 1)).to be false
        expect(described_class.valid_verse?("GEN", 51, 1)).to be false
        expect(described_class.valid_verse?("OBA", 2, 1)).to be false
      end

      it "returns false for invalid book codes" do
        expect(described_class.valid_verse?("INVALID", 1, 1)).to be false
        expect(described_class.valid_verse?(nil, 1, 1)).to be false
        expect(described_class.valid_verse?("", 1, 1)).to be false
      end

      it "returns false for negative verses" do
        expect(described_class.valid_verse?("GEN", 1, -1)).to be false
      end
    end

    it "works with different versifications" do
      expect(described_class.valid_verse?("GEN", 1, 31, :english)).to be true
      expect(described_class.valid_verse?("GEN", 1, 31, :hebrew)).to be false
    end
  end

  describe "data integrity" do
    it "has data for all 66 canonical books" do
      expect(described_class::ENGLISH.keys.length).to eq(66)
    end

    it "has ChapterInfo for all chapters" do
      expect(described_class::ALL_CHAPTERS).not_to be_empty
      expect(described_class::ALL_CHAPTERS.length).to be > 1000
      expect(described_class::ALL_CHAPTERS.all? { |c| c.is_a?(described_class::ChapterInfo) }).to be true
    end

    it "includes all Old Testament books" do
      old_testament_codes = %w[
        GEN EXO LEV NUM DEU JOS JDG RUT 1SA 2SA 1KI 2KI 1CH 2CH EZR NEH EST JOB PSA PRO
        ECC SNG ISA JER LAM EZK DAN HOS JOL AMO OBA JON MIC NAM HAB ZEP HAG ZEC MAL
      ]
      old_testament_codes.each do |code|
        expect(described_class::ENGLISH).to have_key(code)
      end
    end

    it "includes all New Testament books" do
      new_testament_codes = %w[
        MAT MRK LUK JHN ACT ROM 1CO 2CO GAL EPH PHP COL 1TH 2TH 1TI 2TI TIT PHM HEB JAS
        1PE 2PE 1JN 2JN 3JN JUD REV
      ]
      new_testament_codes.each do |code|
        expect(described_class::ENGLISH).to have_key(code)
      end
    end

    it "has positive verse counts for all chapters" do
      described_class::ENGLISH.each do |book_code, chapters|
        chapters.each_with_index do |verse_count, chapter_index|
          expect(verse_count).to be > 0, "#{book_code} chapter #{chapter_index + 1} has #{verse_count} verses"
        end
      end
    end

    it "has reasonable verse counts (not exceeding 200)" do
      described_class::ENGLISH.each do |book_code, chapters|
        chapters.each_with_index do |verse_count, chapter_index|
          expect(verse_count).to be <= 200, "#{book_code} chapter #{chapter_index + 1} has #{verse_count} verses"
        end
      end
    end

    it "has expected chapter counts for Old Testament books" do
      expect(described_class::ENGLISH["GEN"].length).to eq(50)
      expect(described_class::ENGLISH["PSA"].length).to eq(150)
      expect(described_class::ENGLISH["OBA"].length).to eq(1)
    end

    it "has expected chapter counts for New Testament books" do
      expect(described_class::ENGLISH["MAT"].length).to eq(28)
      expect(described_class::ENGLISH["REV"].length).to eq(22)
      expect(described_class::ENGLISH["PHM"].length).to eq(1)
    end
  end

  describe ".chapter_info" do
    it "returns ChapterInfo for valid chapters" do
      chapter = described_class.chapter_info("GEN", 1)
      expect(chapter).not_to be_nil
      expect(chapter.book_code).to eq("GEN")
      expect(chapter.chapter).to eq(1)
      expect(chapter.verse_count).to eq(31)
    end

    it "returns nil for invalid chapters" do
      expect(described_class.chapter_info("GEN", 0)).to be_nil
      expect(described_class.chapter_info("GEN", 51)).to be_nil
      expect(described_class.chapter_info("INVALID", 1)).to be_nil
    end
  end

  describe ".book_chapters" do
    it "returns all chapters for a book" do
      chapters = described_class.book_chapters("GEN")
      expect(chapters.length).to eq(50)
      expect(chapters.first.chapter).to eq(1)
      expect(chapters.last.chapter).to eq(50)
    end

    it "returns empty array for invalid books" do
      expect(described_class.book_chapters("INVALID")).to eq([])
    end

    it "works with single-chapter books" do
      chapters = described_class.book_chapters("OBA")
      expect(chapters.length).to eq(1)
      expect(chapters.first.verse_count).to eq(21)
    end
  end

  describe "edge cases" do
    it "handles longest chapter (Psalm 119)" do
      expect(described_class.verse_count("PSA", 119)).to eq(176)
      expect(described_class.valid_verse?("PSA", 119, 176)).to be true
      expect(described_class.valid_verse?("PSA", 119, 177)).to be false
    end

    it "handles shortest chapters" do
      expect(described_class.verse_count("PSA", 117)).to eq(2)
      expect(described_class.verse_count("PSA", 134)).to eq(3)
    end

    it "handles books with many chapters" do
      expect(described_class::ENGLISH["PSA"].length).to eq(150)
      expect(described_class.valid_chapter?("PSA", 150)).to be true
      expect(described_class.valid_chapter?("PSA", 151)).to be false
    end

    it "handles single-chapter books correctly" do
      single_chapter_books = %w[OBA PHM 2JN 3JN JUD]
      single_chapter_books.each do |book_code|
        expect(described_class::ENGLISH[book_code].length).to eq(1)
        expect(described_class.valid_chapter?(book_code, 1)).to be true
        expect(described_class.valid_chapter?(book_code, 2)).to be false
      end
    end
  end
end
