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
end
