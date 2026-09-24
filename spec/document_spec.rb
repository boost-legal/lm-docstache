require 'spec_helper'

# Counts how many times a `w:p` node has its text serialized. Serializing a
# paragraph walks and allocates its whole subtree, so it dominates the cost of
# scanning a document for broken tags.
module ParagraphTextCounter
  class << self
    attr_accessor :count, :enabled
  end
  self.count = 0
  self.enabled = false

  def text
    ParagraphTextCounter.count += 1 if ParagraphTextCounter.enabled && name == 'p'
    super
  end
end

Nokogiri::XML::Node.prepend(ParagraphTextCounter)

describe LMDocstache::Document do
  let(:input_file) { SPEC_BASE_PATH.join('example_input', 'ExampleTemplate.docx') }
  let(:document) { LMDocstache::Document.new(input_file) }

  def count_paragraph_text_serializations
    ParagraphTextCounter.count = 0
    ParagraphTextCounter.enabled = true
    yield
    ParagraphTextCounter.count
  ensure
    ParagraphTextCounter.enabled = false
  end

  describe '#problem_paragraphs' do
    it 'serializes each paragraph text at most once, whatever the broken tag count' do
      # Headers and footers are scanned alongside document.xml, so the bound is
      # every paragraph in every interpolated document.
      paragraph_count = document.instance_variable_get(:@documents)
        .values.sum { |doc| doc.css('w|p').size }
      broken_tag_count = document.send(:unusable_tags).size

      serializations = count_paragraph_text_serializations do
        document.send(:problem_paragraphs)
      end

      # Scanning must cost one pass over the paragraphs, not one pass per broken
      # tag: the latter is what makes a template with many split tags unrenderable.
      expect(broken_tag_count).to be > 1 # guards the assertion below from being vacuous
      expect(serializations).to be <= paragraph_count
    end
  end

  describe '#errors?' do
    it 'is false when every tag is reconstructable, even if the tag counts differ' do
      # A cleanly flattened template can still have tags.length != usable_tags.length:
      # #usable_tags also extracts :start_block, a population #tags never counts, and
      # neither collection dedupes. Comparing the two lengths reported such a clean
      # document as broken; #errors? must follow #unusable_tags instead.
      allow(document).to receive(:unusable_tags).and_return([])
      allow(document).to receive(:tags).and_return(Array.new(5))
      allow(document).to receive(:usable_tags).and_return(Array.new(7))

      expect(document.errors?).to be(false)
    end

    it 'is true when a tag cannot be reconstructed from a single text node' do
      allow(document).to receive(:unusable_tags).and_return(['{{split_tag}}'])

      expect(document.errors?).to be(true)
    end

    it 'reports errors on a template whose merge tags Word split across runs' do
      expect(document.errors?).to be(true)
      expect(document.send(:unusable_tags)).not_to be_empty
    end
  end
end
