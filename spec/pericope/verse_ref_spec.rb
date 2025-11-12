# frozen_string_literal: true

RSpec.describe Pericope::VerseRef do
  let(:genesis) { Pericope::Book.find_by_code("GEN") }
  let(:matthew) { Pericope::Book.find_by_code("MAT") }

  describe "#initialize" do
    it "creates a verse reference with book object" do
      verse_ref = described_class.new(genesis, 1, 1)
      expect(verse_ref.book).to eq(genesis)
      expect(verse_ref.chapter).to eq(1)
      expect(verse_ref.verse).to eq(1)
    end

    it "creates a verse reference with book code string" do
      verse_ref = described_class.new("GEN", 1, 1)
      expect(verse_ref.book.code).to eq("GEN")
      expect(verse_ref.chapter).to eq(1)
      expect(verse_ref.verse).to eq(1)
    end

    it "converts string numbers to integers" do
      verse_ref = described_class.new(genesis, "1", "1")
      expect(verse_ref.chapter).to eq(1)
      expect(verse_ref.verse).to eq(1)
    end

    it "raises InvalidBookError for invalid book" do
      expect { described_class.new("INVALID", 1, 1) }.to raise_error(Pericope::InvalidBookError)
      expect { described_class.new(nil, 1, 1) }.to raise_error(Pericope::InvalidBookError)
    end

    it "raises InvalidChapterError for invalid chapter" do
      expect { described_class.new(genesis, 0, 1) }.to raise_error(Pericope::InvalidChapterError)
      expect { described_class.new(genesis, -1, 1) }.to raise_error(Pericope::InvalidChapterError)
    end

    it "raises InvalidVerseError for invalid verse" do
      expect { described_class.new(genesis, 1, 0) }.to raise_error(Pericope::InvalidVerseError)
      expect { described_class.new(genesis, 1, -1) }.to raise_error(Pericope::InvalidVerseError)
    end
  end

  describe "#to_s" do
    it "returns string representation" do
      verse_ref = described_class.new(genesis, 1, 1)
      expect(verse_ref.to_s).to eq("GEN 1:1")
    end

    it "handles different books" do
      verse_ref = described_class.new(matthew, 5, 3)
      expect(verse_ref.to_s).to eq("MAT 5:3")
    end
  end

  describe "#to_i" do
    it "returns BBBCCCVVV format" do
      verse_ref = described_class.new(genesis, 1, 1)
      expected = (1 * 1_000_000) + (1 * 1000) + 1 # 1001001
      expect(verse_ref.to_i).to eq(expected)
    end

    it "handles different values" do
      verse_ref = described_class.new(matthew, 5, 3)
      expected = (40 * 1_000_000) + (5 * 1000) + 3 # 40005003
      expect(verse_ref.to_i).to eq(expected)
    end
  end

  describe "#valid?" do
    it "returns true for valid references" do
      verse_ref = described_class.new(genesis, 1, 1)
      expect(verse_ref.valid?).to be true
    end

    it "returns false for invalid chapter" do
      # Create with a valid chapter first, then test validation
      verse_ref = described_class.new(genesis, 1, 1)
      # Manually set invalid chapter to test validation method
      verse_ref.instance_variable_set(:@chapter, 999)
      expect(verse_ref.valid?).to be false
    end

    it "returns false for invalid verse" do
      verse_ref = described_class.new(genesis, 1, 1)
      # Manually set invalid verse to test validation method
      verse_ref.instance_variable_set(:@verse, 999)
      expect(verse_ref.valid?).to be false
    end
  end

  describe "#==" do
    it "returns true for identical references" do
      verse_ref1 = described_class.new(genesis, 1, 1)
      verse_ref2 = described_class.new(genesis, 1, 1)
      expect(verse_ref1).to eq(verse_ref2)
    end

    it "returns false for different references" do
      verse_ref1 = described_class.new(genesis, 1, 1)
      verse_ref2 = described_class.new(genesis, 1, 2)
      expect(verse_ref1).not_to eq(verse_ref2)
    end

    it "returns false for different books" do
      verse_ref1 = described_class.new(genesis, 1, 1)
      verse_ref2 = described_class.new(matthew, 1, 1)
      expect(verse_ref1).not_to eq(verse_ref2)
    end

    it "returns false for non-VerseRef objects" do
      verse_ref = described_class.new(genesis, 1, 1)
      expect(verse_ref).not_to eq("GEN 1:1")
      expect(verse_ref).not_to be_nil
    end
  end

  describe "#<=>" do
    let(:gen_1_1) { described_class.new(genesis, 1, 1) }
    let(:gen_1_2) { described_class.new(genesis, 1, 2) }
    let(:gen_2_1) { described_class.new(genesis, 2, 1) }
    let(:mat_1_1) { described_class.new(matthew, 1, 1) }

    it "compares by book first" do
      expect(gen_1_1 <=> mat_1_1).to eq(-1)
      expect(mat_1_1 <=> gen_1_1).to eq(1)
    end

    it "compares by chapter within same book" do
      expect(gen_1_1 <=> gen_2_1).to eq(-1)
      expect(gen_2_1 <=> gen_1_1).to eq(1)
    end

    it "compares by verse within same chapter" do
      expect(gen_1_1 <=> gen_1_2).to eq(-1)
      expect(gen_1_2 <=> gen_1_1).to eq(1)
    end

    it "returns 0 for identical references" do
      verse_ref1 = described_class.new(genesis, 1, 1)
      verse_ref2 = described_class.new(genesis, 1, 1)
      expect(verse_ref1 <=> verse_ref2).to eq(0)
    end

    it "returns nil for non-VerseRef objects" do
      expect(gen_1_1 <=> "not a verse ref").to be_nil
    end
  end

  describe "#before?" do
    it "returns true when this verse comes before another" do
      verse_ref1 = described_class.new(genesis, 1, 1)
      verse_ref2 = described_class.new(genesis, 1, 2)
      expect(verse_ref1.before?(verse_ref2)).to be true
      expect(verse_ref2.before?(verse_ref1)).to be false
    end
  end

  describe "#after?" do
    it "returns true when this verse comes after another" do
      verse_ref1 = described_class.new(genesis, 1, 1)
      verse_ref2 = described_class.new(genesis, 1, 2)
      expect(verse_ref2.after?(verse_ref1)).to be true
      expect(verse_ref1.after?(verse_ref2)).to be false
    end
  end

  describe "#next_verse" do
    it "returns next verse in same chapter" do
      verse_ref = described_class.new(genesis, 1, 1)
      next_verse = verse_ref.next_verse
      expect(next_verse.chapter).to eq(1)
      expect(next_verse.verse).to eq(2)
    end

    it "returns first verse of next chapter when at end of chapter" do
      # Genesis 1 has 31 verses
      verse_ref = described_class.new(genesis, 1, 31)
      next_verse = verse_ref.next_verse
      expect(next_verse.chapter).to eq(2)
      expect(next_verse.verse).to eq(1)
    end

    it "returns nil when at end of book" do
      # Genesis 50 has 26 verses - use the actual last verse
      verse_ref = described_class.new(genesis, 50, 26)
      next_verse = verse_ref.next_verse
      expect(next_verse).to be_nil
    end
  end

  describe "#previous_verse" do
    it "returns previous verse in same chapter" do
      verse_ref = described_class.new(genesis, 1, 2)
      prev_verse = verse_ref.previous_verse
      expect(prev_verse.chapter).to eq(1)
      expect(prev_verse.verse).to eq(1)
    end

    it "returns last verse of previous chapter when at beginning of chapter" do
      verse_ref = described_class.new(genesis, 2, 1)
      prev_verse = verse_ref.previous_verse
      expect(prev_verse.chapter).to eq(1)
      expect(prev_verse.verse).to eq(31) # Genesis 1 has 31 verses in our model
    end

    it "returns nil when at beginning of book" do
      verse_ref = described_class.new(genesis, 1, 1)
      prev_verse = verse_ref.previous_verse
      expect(prev_verse).to be_nil
    end
  end

  describe "#hash" do
    it "returns same hash for identical references" do
      verse_ref1 = described_class.new(genesis, 1, 1)
      verse_ref2 = described_class.new(genesis, 1, 1)
      expect(verse_ref1.hash).to eq(verse_ref2.hash)
    end

    it "returns different hash for different references" do
      verse_ref1 = described_class.new(genesis, 1, 1)
      verse_ref2 = described_class.new(genesis, 1, 2)
      expect(verse_ref1.hash).not_to eq(verse_ref2.hash)
    end
  end
end
