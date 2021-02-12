require 'strscan'

module LMDocstache
  class ConditionalBlock
    BLOCK_MATCHER = LMDocstache::Parser::BLOCK_MATCHER

    attr_reader :elements, :condition, :value

    def initialize(elements:, condition:, content: nil)
      @elements = elements
      @condition = condition
      @content = content
      @evaluated = false
    end

    def content
      return @content if inline?
    end

    def evaluate_with_value!(value)
      return false if evaluated?
      return false unless inline?

      elements.first.css('w|t').each do |text_node|
        replaced_text = text_node.text.gsub(condition.original_match) do |match|
          condition.truthy?(value) ? content : ''
        end

        text_node.content = replaced_text
      end

      @evaluated = true
    end

    def evaluated?
      !!@evaluated
    end

    def inline?
      @elements.size == 1
    end

    def self.inline_blocks_from_paragraph(paragraph)
      node_set = Nokogiri::XML::NodeSet.new(paragraph.document, [paragraph])
      conditional_blocks = []
      scanner = StringScanner.new(paragraph.text)
      matches = []

      while scanner.scan_until(BLOCK_MATCHER)
        next if matches.include?(scanner.matched)

        content = scanner.captures[4]
        condition = Condition.new(
          left_term: scanner.captures[1],
          right_term: scanner.captures[3],
          operator: scanner.captures[2],
          negation: scanner.captures[0] == '^',
          original_match: scanner.matched
        )

        matches << scanner.matched
        conditional_blocks << new(
          elements: node_set,
          condition: condition,
          content: content
        )
      end

      conditional_blocks
    end
  end
end
