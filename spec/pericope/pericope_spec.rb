# frozen_string_literal: true

RSpec.describe Pericope::Pericope do
  describe "#initialize" do
    it "parses a simple verse reference" do
      pericope = described_class.new("GEN 1:1")
      expect(pericope.book.code).to eq("GEN")
      expect(pericope.to_s).to eq("GEN 1:1")
    end

    it "parses a verse range" do
      pericope = described_class.new("GEN 1:1-3")
      expect(pericope.to_s).to eq("GEN 1:1-3")
    end

    it "parses a cross-chapter range" do
      pericope = described_class.new("GEN 1:1-2:3")
      expect(pericope.to_s).to eq("GEN 1:1-2:3")
    end

    it "parses multiple ranges" do
      pericope = described_class.new("GEN 1:1,3,5")
      expect(pericope.range_count).to eq(3)
    end

    it "raises ParseError for empty reference" do
      expect { described_class.new("") }.to raise_error(Pericope::ParseError)
      expect { described_class.new(nil) }.to raise_error(Pericope::ParseError)
    end

    it "raises InvalidBookError for invalid book" do
      expect { described_class.new("INVALID 1:1") }.to raise_error(Pericope::InvalidBookError)
    end

    it "raises InvalidChapterError for invalid chapter" do
      expect { described_class.new("GEN 999:1") }.to raise_error(Pericope::InvalidChapterError)
    end

    it "raises InvalidVerseError for invalid verse" do
      expect { described_class.new("GEN 1:999") }.to raise_error(Pericope::InvalidVerseError)
    end

    it "handles book names with flexible matching" do
      pericope = described_class.new("Genesis 1:1")
      expect(pericope.book.code).to eq("GEN")
    end

    it "defaults to chapter 1 verse 1 if no range provided" do
      pericope = described_class.new("GEN")
      expect(pericope.to_s).to eq("GEN 1:1")
    end
  end

  describe ".parse" do
    it "extracts pericopes from text" do
      text = "See GEN 1:1 and MAT 5:3-12 for examples"
      pericopes = described_class.parse(text)

      expect(pericopes.length).to eq(2)
      expect(pericopes[0].to_s).to eq("GEN 1:1")
      expect(pericopes[1].to_s).to eq("MAT 5:3-12")
    end

    it "returns empty array for text with no pericopes" do
      text = "This text has no biblical references"
      pericopes = described_class.parse(text)
      expect(pericopes).to be_empty
    end

    it "skips invalid references" do
      text = "See GEN 1:1 and INVALID 1:1"
      pericopes = described_class.parse(text)

      expect(pericopes.length).to eq(1)
      expect(pericopes[0].to_s).to eq("GEN 1:1")
    end
  end

  describe "#to_s" do
    let(:pericope) { described_class.new("GEN 1:1-3") }

    it "returns canonical format by default" do
      expect(pericope.to_s).to eq("GEN 1:1-3")
    end

    it "returns canonical format when specified" do
      expect(pericope.to_s(:canonical)).to eq("GEN 1:1-3")
    end

    it "returns full name format when specified" do
      expect(pericope.to_s(:full_name)).to eq("Genesis 1:1-3")
    end

    it "returns abbreviated format when specified" do
      expect(pericope.to_s(:abbreviated)).to eq("GEN 1:1-3")
    end

    it "returns empty string for empty pericope" do
      pericope = described_class.new("GEN 1:1")
      pericope.instance_variable_set(:@ranges, [])
      expect(pericope.to_s).to eq("")
    end
  end

  describe "#to_a" do
    it "returns array of VerseRef objects for single verse" do
      pericope = described_class.new("GEN 1:1")
      verses = pericope.to_a

      expect(verses.length).to eq(1)
      expect(verses[0]).to be_a(Pericope::VerseRef)
      expect(verses[0].to_s).to eq("GEN 1:1")
    end

    it "returns array of VerseRef objects for verse range" do
      pericope = described_class.new("GEN 1:1-3")
      verses = pericope.to_a

      expect(verses.length).to eq(3)
      expect(verses.map(&:to_s)).to eq(["GEN 1:1", "GEN 1:2", "GEN 1:3"])
    end

    it "handles cross-chapter ranges" do
      pericope = described_class.new("GEN 1:30-2:2")
      verses = pericope.to_a

      expect(verses.length).to be > 3 # Should include verses from both chapters
      expect(verses.first.to_s).to eq("GEN 1:30")
      expect(verses.last.to_s).to eq("GEN 2:2")
    end
  end

  describe "validation methods" do
    let(:valid_pericope) { described_class.new("GEN 1:1") }
    let(:empty_pericope) do
      pericope = described_class.new("GEN 1:1")
      pericope.instance_variable_set(:@ranges, [])
      pericope
    end

    describe "#valid?" do
      it "returns true for valid pericope" do
        expect(valid_pericope.valid?).to be true
      end

      it "returns false for empty pericope" do
        expect(empty_pericope.valid?).to be false
      end
    end

    describe "#empty?" do
      it "returns false for non-empty pericope" do
        expect(valid_pericope.empty?).to be false
      end

      it "returns true for empty pericope" do
        expect(empty_pericope.empty?).to be true
      end
    end

    describe "#single_verse?" do
      it "returns true for single verse" do
        pericope = described_class.new("GEN 1:1")
        expect(pericope.single_verse?).to be true
      end

      it "returns false for verse range" do
        pericope = described_class.new("GEN 1:1-3")
        expect(pericope.single_verse?).to be false
      end
    end

    describe "#single_chapter?" do
      it "returns true for single chapter" do
        pericope = described_class.new("GEN 1:1-3")
        expect(pericope.single_chapter?).to be true
      end

      it "returns false for cross-chapter range" do
        pericope = described_class.new("GEN 1:1-2:3")
        expect(pericope.single_chapter?).to be false
      end
    end

    describe "#spans_chapters?" do
      it "returns false for single chapter" do
        pericope = described_class.new("GEN 1:1-3")
        expect(pericope.spans_chapters?).to be false
      end

      it "returns true for cross-chapter range" do
        pericope = described_class.new("GEN 1:1-2:3")
        expect(pericope.spans_chapters?).to be true
      end
    end

    describe "#spans_books?" do
      it "returns false (single book implementation)" do
        pericope = described_class.new("GEN 1:1")
        expect(pericope.spans_books?).to be false
      end
    end
  end

  describe "counting methods" do
    describe "#verse_count" do
      it "returns 1 for single verse" do
        pericope = described_class.new("GEN 1:1")
        expect(pericope.verse_count).to eq(1)
      end

      it "returns correct count for verse range" do
        pericope = described_class.new("GEN 1:1-3")
        expect(pericope.verse_count).to eq(3)
      end
    end

    describe "#chapter_count" do
      it "returns 1 for single chapter" do
        pericope = described_class.new("GEN 1:1-3")
        expect(pericope.chapter_count).to eq(1)
      end

      it "returns correct count for cross-chapter range" do
        pericope = described_class.new("GEN 1:1-3:1")
        expect(pericope.chapter_count).to eq(3)
      end
    end

    describe "#chapter_list" do
      it "returns array of chapters" do
        pericope = described_class.new("GEN 1:1-3:1")
        expect(pericope.chapter_list).to eq([1, 2, 3])
      end
    end

    describe "#range_count" do
      it "returns number of ranges" do
        pericope = described_class.new("GEN 1:1,3,5")
        expect(pericope.range_count).to eq(3)
      end
    end
  end

  describe "verse access methods" do
    describe "#first_verse" do
      it "returns first verse" do
        pericope = described_class.new("GEN 2:5-10")
        first = pericope.first_verse
        expect(first.to_s).to eq("GEN 2:5")
      end

      it "returns nil for empty pericope" do
        pericope = described_class.new("GEN 1:1")
        pericope.instance_variable_set(:@ranges, [])
        expect(pericope.first_verse).to be_nil
      end
    end

    describe "#last_verse" do
      it "returns last verse" do
        pericope = described_class.new("GEN 2:5-10")
        last = pericope.last_verse
        expect(last.to_s).to eq("GEN 2:10")
      end

      it "returns nil for empty pericope" do
        pericope = described_class.new("GEN 1:1")
        pericope.instance_variable_set(:@ranges, [])
        expect(pericope.last_verse).to be_nil
      end
    end
  end

  describe "#==" do
    it "returns true for identical pericopes" do
      pericope1 = described_class.new("GEN 1:1-3")
      pericope2 = described_class.new("GEN 1:1-3")
      expect(pericope1).to eq(pericope2)
    end

    it "returns false for different pericopes" do
      pericope1 = described_class.new("GEN 1:1-3")
      pericope2 = described_class.new("GEN 1:4-6")
      expect(pericope1).not_to eq(pericope2)
    end

    it "returns false for different books" do
      pericope1 = described_class.new("GEN 1:1")
      pericope2 = described_class.new("MAT 1:1")
      expect(pericope1).not_to eq(pericope2)
    end

    it "returns false for non-Pericope objects" do
      pericope = described_class.new("GEN 1:1")
      expect(pericope).not_to eq("GEN 1:1")
    end
  end

  describe "advanced mathematical operations" do
    describe "#verses_in_chapter" do
      it "returns correct count for single chapter pericope" do
        pericope = described_class.new("GEN 1:1-5")
        expect(pericope.verses_in_chapter(1)).to eq(5)
        expect(pericope.verses_in_chapter(2)).to eq(0)
      end

      it "returns correct count for cross-chapter pericope" do
        pericope = described_class.new("GEN 1:30-2:5")
        expect(pericope.verses_in_chapter(1)).to eq(2) # verses 30-31
        expect(pericope.verses_in_chapter(2)).to eq(5) # verses 1-5
        expect(pericope.verses_in_chapter(3)).to eq(0)
      end

      it "returns 0 for invalid chapter" do
        pericope = described_class.new("GEN 1:1-5")
        expect(pericope.verses_in_chapter(0)).to eq(0)
        expect(pericope.verses_in_chapter(100)).to eq(0)
      end

      it "handles multiple ranges in same chapter" do
        pericope = described_class.new("GEN 1:1-3,5-7")
        expect(pericope.verses_in_chapter(1)).to eq(6) # verses 1,2,3,5,6,7
      end
    end

    describe "#chapters_in_range" do
      it "returns correct breakdown for single chapter" do
        pericope = described_class.new("GEN 1:1,3,5-7")
        result = pericope.chapters_in_range
        expect(result).to eq({ 1 => [1, 3, 5, 6, 7] })
      end

      it "returns correct breakdown for cross-chapter range" do
        pericope = described_class.new("GEN 1:30-2:3")
        result = pericope.chapters_in_range
        expect(result[1]).to eq([30, 31])
        expect(result[2]).to eq([1, 2, 3])
      end

      it "handles multiple ranges across chapters" do
        pericope = described_class.new("GEN 1:1-2,2:5-6")
        result = pericope.chapters_in_range
        expect(result[1]).to eq([1, 2])
        expect(result[2]).to eq([5, 6])
      end
    end

    describe "#density" do
      it "returns 1.0 for complete chapter" do
        # Assuming GEN 1 has 31 verses
        pericope = described_class.new("GEN 1:1-31")
        expect(pericope.density).to eq(1.0)
      end

      it "returns correct fraction for partial chapter" do
        pericope = described_class.new("GEN 1:1-10")
        # 10 out of 31 verses in Genesis 1
        expect(pericope.density).to be_within(0.01).of(10.0 / 31.0)
      end

      it "returns 0.0 for empty pericope" do
        pericope = described_class.new("GEN 1:1")
        pericope.instance_variable_set(:@ranges, [])
        expect(pericope.density).to eq(0.0)
      end
    end

    describe "#gaps" do
      it "returns empty array for continuous range" do
        pericope = described_class.new("GEN 1:1-5")
        expect(pericope.gaps).to be_empty
      end

      it "returns empty array for single verse" do
        pericope = described_class.new("GEN 1:1")
        expect(pericope.gaps).to be_empty
      end

      it "identifies gaps in discontinuous ranges" do
        pericope = described_class.new("GEN 1:1,3,5")
        gaps = pericope.gaps
        expect(gaps.map(&:to_s)).to include("GEN 1:2", "GEN 1:4")
      end

      it "identifies gaps in cross-chapter ranges" do
        pericope = described_class.new("GEN 1:30,2:2")
        gaps = pericope.gaps
        gap_strings = gaps.map(&:to_s)
        expect(gap_strings).to include("GEN 1:31", "GEN 2:1")
      end
    end

    describe "#continuous_ranges" do
      it "returns single range for continuous verses" do
        pericope = described_class.new("GEN 1:1-5")
        ranges = pericope.continuous_ranges
        expect(ranges.length).to eq(1)
        expect(ranges.first.to_s).to eq("GEN 1:1-5")
      end

      it "breaks discontinuous ranges into continuous parts" do
        pericope = described_class.new("GEN 1:1-3,5-7,10")
        ranges = pericope.continuous_ranges
        expect(ranges.length).to eq(3)
        expect(ranges.map(&:to_s)).to contain_exactly("GEN 1:1-3", "GEN 1:5-7", "GEN 1:10")
      end

      it "handles cross-chapter continuous ranges" do
        pericope = described_class.new("GEN 1:30-2:2")
        ranges = pericope.continuous_ranges
        expect(ranges.length).to eq(1)
        expect(ranges.first.to_s).to eq("GEN 1:30-2:2")
      end
    end
  end

  describe "comparison methods" do
    describe "#intersects?" do
      it "returns true for overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("GEN 1:5-15")
        expect(pericope1.intersects?(pericope2)).to be true
        expect(pericope2.intersects?(pericope1)).to be true
      end

      it "returns false for non-overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:10-15")
        expect(pericope1.intersects?(pericope2)).to be false
      end

      it "returns false for different books" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("MAT 1:1-5")
        expect(pericope1.intersects?(pericope2)).to be false
      end

      it "returns true for identical ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:1-5")
        expect(pericope1.intersects?(pericope2)).to be true
      end
    end

    describe "#contains?" do
      it "returns true when containing a smaller range" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("GEN 1:3-7")
        expect(pericope1.contains?(pericope2)).to be true
        expect(pericope2.contains?(pericope1)).to be false
      end

      it "returns true for identical ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:1-5")
        expect(pericope1.contains?(pericope2)).to be true
      end

      it "returns false for partially overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("GEN 1:5-15")
        expect(pericope1.contains?(pericope2)).to be false
      end

      it "returns false for different books" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("MAT 1:1-5")
        expect(pericope1.contains?(pericope2)).to be false
      end
    end

    describe "#overlaps?" do
      it "is an alias for intersects?" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("GEN 1:5-15")
        expect(pericope1.overlaps?(pericope2)).to eq(pericope1.intersects?(pericope2))
      end
    end

    describe "#adjacent_to?" do
      it "returns true for adjacent ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:6-10")
        expect(pericope1.adjacent_to?(pericope2)).to be true
        expect(pericope2.adjacent_to?(pericope1)).to be true
      end

      it "returns false for overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:5-10")
        expect(pericope1.adjacent_to?(pericope2)).to be false
      end

      it "returns false for non-adjacent ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:8-10")
        expect(pericope1.adjacent_to?(pericope2)).to be false
      end

      it "returns false for different books" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("MAT 1:1-5")
        expect(pericope1.adjacent_to?(pericope2)).to be false
      end
    end

    describe "#precedes?" do
      it "returns true when this pericope comes before another" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:10-15")
        expect(pericope1.precedes?(pericope2)).to be true
        expect(pericope2.precedes?(pericope1)).to be false
      end

      it "returns false for overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("GEN 1:5-15")
        expect(pericope1.precedes?(pericope2)).to be false
      end

      it "returns false for different books" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("MAT 1:1-5")
        expect(pericope1.precedes?(pericope2)).to be false
      end
    end

    describe "#follows?" do
      it "returns true when this pericope comes after another" do
        pericope1 = described_class.new("GEN 1:10-15")
        pericope2 = described_class.new("GEN 1:1-5")
        expect(pericope1.follows?(pericope2)).to be true
        expect(pericope2.follows?(pericope1)).to be false
      end

      it "returns false for overlapping ranges" do
        pericope1 = described_class.new("GEN 1:5-15")
        pericope2 = described_class.new("GEN 1:1-10")
        expect(pericope1.follows?(pericope2)).to be false
      end

      it "returns false for different books" do
        pericope1 = described_class.new("MAT 1:1-5")
        pericope2 = described_class.new("GEN 1:1-5")
        expect(pericope1.follows?(pericope2)).to be false
      end
    end
  end

  describe "set operations" do
    describe "#union" do
      it "combines two overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("GEN 1:5-15")
        result = pericope1.union(pericope2)
        expect(result.to_s).to eq("GEN 1:1-15")
      end

      it "combines two non-overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:10-15")
        result = pericope1.union(pericope2)
        expect(result.verse_count).to eq(11) # 5 + 6 verses
      end

      it "returns self when other is different book" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("MAT 1:1-5")
        result = pericope1.union(pericope2)
        expect(result).to eq(pericope1)
      end

      it "handles identical ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:1-5")
        result = pericope1.union(pericope2)
        expect(result.to_s).to eq("GEN 1:1-5")
      end
    end

    describe "#intersection" do
      it "finds common verses in overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("GEN 1:5-15")
        result = pericope1.intersection(pericope2)
        expect(result.to_s).to eq("GEN 1:5-10")
      end

      it "returns empty for non-overlapping ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:10-15")
        result = pericope1.intersection(pericope2)
        expect(result.empty?).to be true
      end

      it "returns empty for different books" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("MAT 1:1-5")
        result = pericope1.intersection(pericope2)
        expect(result.empty?).to be true
      end

      it "handles identical ranges" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:1-5")
        result = pericope1.intersection(pericope2)
        expect(result.to_s).to eq("GEN 1:1-5")
      end
    end

    describe "#subtract" do
      it "removes overlapping verses" do
        pericope1 = described_class.new("GEN 1:1-10")
        pericope2 = described_class.new("GEN 1:5-15")
        result = pericope1.subtract(pericope2)
        expect(result.to_s).to eq("GEN 1:1-4")
      end

      it "returns self when no overlap" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:10-15")
        result = pericope1.subtract(pericope2)
        expect(result.to_s).to eq("GEN 1:1-5")
      end

      it "returns self for different books" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("MAT 1:1-5")
        result = pericope1.subtract(pericope2)
        expect(result).to eq(pericope1)
      end

      it "returns empty when subtracting identical range" do
        pericope1 = described_class.new("GEN 1:1-5")
        pericope2 = described_class.new("GEN 1:1-5")
        result = pericope1.subtract(pericope2)
        expect(result.empty?).to be true
      end
    end

    describe "#normalize" do
      it "combines adjacent ranges" do
        pericope = described_class.new("GEN 1:1-3,4-6")
        result = pericope.normalize
        expect(result.to_s).to eq("GEN 1:1-6")
      end

      it "sorts and combines overlapping ranges" do
        pericope = described_class.new("GEN 1:5-10,1-7")
        result = pericope.normalize
        expect(result.to_s).to eq("GEN 1:1-10")
      end

      it "returns self for already normalized range" do
        pericope = described_class.new("GEN 1:1-5")
        result = pericope.normalize
        expect(result.to_s).to eq("GEN 1:1-5")
      end
    end

    describe "#expand" do
      it "expands range by specified verses" do
        pericope = described_class.new("GEN 1:5-10")
        result = pericope.expand(2, 3)
        expect(result.verse_count).to be > pericope.verse_count
        expect(result.first_verse.verse).to eq(3) # 5 - 2
        expect(result.last_verse.verse).to eq(13) # 10 + 3
      end

      it "handles expansion at book boundaries" do
        pericope = described_class.new("GEN 1:1-2")
        result = pericope.expand(5, 0) # Try to expand before verse 1
        expect(result.first_verse.verse).to eq(1) # Can't go before verse 1
      end

      it "returns self when no expansion requested" do
        pericope = described_class.new("GEN 1:5-10")
        result = pericope.expand(0, 0)
        expect(result.to_s).to eq(pericope.to_s)
      end
    end

    describe "#contract" do
      it "contracts range by removing verses from ends" do
        pericope = described_class.new("GEN 1:1-10")
        result = pericope.contract(2, 3)
        expect(result.to_s).to eq("GEN 1:3-7") # Remove 2 from start, 3 from end
      end

      it "returns empty when contracting too much" do
        pericope = described_class.new("GEN 1:1-5")
        result = pericope.contract(3, 3) # Remove more than available
        expect(result.empty?).to be true
      end

      it "returns self when no contraction requested" do
        pericope = described_class.new("GEN 1:1-10")
        result = pericope.contract(0, 0)
        expect(result.to_s).to eq(pericope.to_s)
      end
    end
  end
end
