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

      inline? ? evaluate_inline!(value) : evaluate_multiple_nodes!(value)

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

    private

    # Normally we expect that both starting and closing block paragraph elements
    # contain only one +<w:r />+ and one +<w:t />+ elements. Nonetheless, we try
    # to merge runs (w:r elements) together when they are direct siblings with
    # same style.
    def evaluate_multiple_nodes!(value)
      merge_text_elements_if_possible!(elements.first)
      merge_text_elements_if_possible!(elements.last)
    end

    def merge_text_elements_if_possible!(node)
      return if (run_nodes = node.css('w|r')).size < 2

      while run_node = run_nodes.pop
        next if run_nodes.empty?

        style_hash = run_node.at_css('w|rPr').inner_html.hash
        previous_run_node = run_nodes.last

        next if style_hash != previous_run_node.at_css('w|rPr').inner_html.hash

        previous_text_node = previous_run_node.at_css('w|t')
        previous_text_node.content = previous_text_node.text + run_node.text
        run_node.unlink
      end
    end

    def evaluate_inline!(value)
      elements.first.css('w|t').each do |text_node|
        replaced_text = text_node.text.gsub(condition.original_match) do |match|
          condition.truthy?(value) ? content : ''
        end

        text_node.content = replaced_text
      end
    end
  end
end
