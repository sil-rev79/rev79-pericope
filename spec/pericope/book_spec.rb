# frozen_string_literal: true

RSpec.describe Pericope::Book do
  describe ".find_by_code" do
    it "finds book by exact Paratext code" do
      book = described_class.find_by_code("GEN")
      expect(book).not_to be_nil
      expect(book.code).to eq("GEN")
      expect(book.name).to eq("Genesis")
    end

    it "is case insensitive" do
      book = described_class.find_by_code("gen")
      expect(book).not_to be_nil
      expect(book.code).to eq("GEN")
    end

    it "returns nil for invalid codes" do
      expect(described_class.find_by_code("INVALID")).to be_nil
      expect(described_class.find_by_code(nil)).to be_nil
      expect(described_class.find_by_code("")).to be_nil
    end

    it "finds New Testament books" do
      book = described_class.find_by_code("MAT")
      expect(book).not_to be_nil
      expect(book.code).to eq("MAT")
      expect(book.name).to eq("Matthew")
      expect(book.testament).to eq(:new)
    end
  end

  describe ".find_by_number" do
    it "finds book by number" do
      book = described_class.find_by_number(1)
      expect(book).not_to be_nil
      expect(book.code).to eq("GEN")
      expect(book.number).to eq(1)
    end

    it "finds New Testament books by number" do
      book = described_class.find_by_number(40)
      expect(book).not_to be_nil
      expect(book.code).to eq("MAT")
      expect(book.number).to eq(40)
    end

    it "returns nil for invalid numbers" do
      expect(described_class.find_by_number(0)).to be_nil
      expect(described_class.find_by_number(100)).to be_nil
      expect(described_class.find_by_number(nil)).to be_nil
    end
  end

  describe ".find_by_name" do
    it "finds book by full name" do
      book = described_class.find_by_name("Genesis")
      expect(book).not_to be_nil
      expect(book.code).to eq("GEN")
    end

    it "finds book by common abbreviation" do
      book = described_class.find_by_name("Gen")
      expect(book).not_to be_nil
      expect(book.code).to eq("GEN")
    end

    it "is case insensitive" do
      book = described_class.find_by_name("genesis")
      expect(book).not_to be_nil
      expect(book.code).to eq("GEN")
    end

    it "finds book by Paratext code" do
      book = described_class.find_by_name("GEN")
      expect(book).not_to be_nil
      expect(book.code).to eq("GEN")
    end

    it "handles complex book names" do
      book = described_class.find_by_name("1 Corinthians")
      expect(book).not_to be_nil
      expect(book.code).to eq("1CO")
    end

    it "handles alternative spellings" do
      book = described_class.find_by_name("Mathew")
      expect(book).not_to be_nil
      expect(book.code).to eq("MAT")
    end

    it "handles numeric variations" do
      book = described_class.find_by_name("First Corinthians")
      expect(book).not_to be_nil
      expect(book.code).to eq("1CO")
    end

    it "returns nil for invalid names" do
      expect(described_class.find_by_name("Invalid Book")).to be_nil
      expect(described_class.find_by_name(nil)).to be_nil
      expect(described_class.find_by_name("")).to be_nil
    end
  end

  describe ".find_by_alias" do
    it "works the same as find_by_name" do
      book1 = described_class.find_by_alias("Genesis")
      book2 = described_class.find_by_name("Genesis")
      expect(book1).to eq(book2)
    end
  end

  describe ".all_books" do
    it "returns all 66 canonical books" do
      books = described_class.all_books
      expect(books.length).to eq(66)
      expect(books.first.code).to eq("GEN")
      expect(books.last.code).to eq("REV")
    end

    it "returns Book instances" do
      books = described_class.all_books
      expect(books.all? { |book| book.is_a?(described_class) }).to be true
    end
  end

  describe ".testament_books" do
    it "returns Old Testament books" do
      books = described_class.testament_books(:old)
      expect(books.length).to eq(39)
      expect(books.first.code).to eq("GEN")
      expect(books.last.code).to eq("MAL")
      expect(books.all?(&:old_testament?)).to be true
    end

    it "returns New Testament books" do
      books = described_class.testament_books(:new)
      expect(books.length).to eq(27)
      expect(books.first.code).to eq("MAT")
      expect(books.last.code).to eq("REV")
      expect(books.all?(&:new_testament?)).to be true
    end

    it "returns empty array for deuterocanonical (not implemented)" do
      books = described_class.testament_books(:deuterocanonical)
      expect(books).to eq([])
    end

    it "returns empty array for invalid testament" do
      books = described_class.testament_books(:invalid)
      expect(books).to eq([])
    end
  end

  describe ".normalize_name" do
    it "converts various formats to canonical code" do
      expect(described_class.normalize_name("Genesis")).to eq("GEN")
      expect(described_class.normalize_name("Gen")).to eq("GEN")
      expect(described_class.normalize_name("GEN")).to eq("GEN")
      expect(described_class.normalize_name("Matthew")).to eq("MAT")
      expect(described_class.normalize_name("1 Corinthians")).to eq("1CO")
    end

    it "returns nil for invalid names" do
      expect(described_class.normalize_name("Invalid")).to be_nil
      expect(described_class.normalize_name(nil)).to be_nil
    end
  end

  describe "instance methods" do
    let(:genesis) { described_class.find_by_code("GEN") }
    let(:matthew) { described_class.find_by_code("MAT") }

    describe "#valid?" do
      it "returns true for valid books" do
        expect(genesis.valid?).to be true
        expect(matthew.valid?).to be true
      end
    end

    describe "#canonical?" do
      it "returns true for canonical books" do
        expect(genesis.canonical?).to be true
        expect(matthew.canonical?).to be true
      end
    end

    describe "#deuterocanonical?" do
      it "returns false for canonical books" do
        expect(genesis.deuterocanonical?).to be false
        expect(matthew.deuterocanonical?).to be false
      end
    end

    describe "#old_testament?" do
      it "returns true for Old Testament books" do
        expect(genesis.old_testament?).to be true
      end

      it "returns false for New Testament books" do
        expect(matthew.old_testament?).to be false
      end
    end

    describe "#new_testament?" do
      it "returns false for Old Testament books" do
        expect(genesis.new_testament?).to be false
      end

      it "returns true for New Testament books" do
        expect(matthew.new_testament?).to be true
      end
    end

    describe "#matches?" do
      it "matches against aliases" do
        expect(genesis.matches?("Genesis")).to be true
        expect(genesis.matches?("Gen")).to be true
        expect(genesis.matches?("GEN")).to be true
        expect(genesis.matches?("genesis")).to be true
      end

      it "returns false for non-matching input" do
        expect(genesis.matches?("Matthew")).to be false
        expect(genesis.matches?("Invalid")).to be false
        expect(genesis.matches?(nil)).to be false
      end
    end

    describe "#to_s" do
      it "returns the book code" do
        expect(genesis.to_s).to eq("GEN")
        expect(matthew.to_s).to eq("MAT")
      end
    end

    describe "#==" do
      it "compares books by code" do
        genesis1 = described_class.find_by_code("GEN")
        genesis2 = described_class.find_by_name("Genesis")
        expect(genesis1).to eq(genesis2)
        expect(genesis1).not_to eq(matthew)
      end
    end

    describe "#verse_count" do
      it "returns verse count for a chapter" do
        expect(genesis.verse_count(1)).to eq(31)
        expect(genesis.verse_count(2)).to eq(25)
        expect(matthew.verse_count(1)).to eq(25)
      end

      it "returns default for unknown chapters" do
        expect(genesis.verse_count(999)).to eq(20)
      end
    end
  end
end
