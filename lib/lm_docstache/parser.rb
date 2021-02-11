module LMDocstache
  class Parser
    BLOCK_TYPE_PATTERN = '(#|\^)\s*'
    BLOCK_VARIABLE_PATTERN = '([^\s~=]+)'
    BLOCK_OPERATOR_PATTERN = '\s*(~=|==)\s*'
    BLOCK_VALUE_PATTERN = '([^\}]+?)\s*'
    BLOCK_START_PATTERN = "{{#{BLOCK_TYPE_PATTERN}#{BLOCK_VARIABLE_PATTERN}"\
                          "#{BLOCK_OPERATOR_PATTERN}#{BLOCK_VALUE_PATTERN}}}"
    BLOCK_CONTENT_PATTERN = '\s*(.*?)\s*'
    BLOCK_CLOSE_PATTERN = '{{/\s*\k<2>\s*}}'
    BLOCK_NAMED_CLOSE_PATTERN = '{{/\s*%{tag_name}\s*}}'
    BLOCK_PATTERN = "#{BLOCK_START_PATTERN}#{BLOCK_CONTENT_PATTERN}"\
                    "#{BLOCK_CLOSE_PATTERN}"

    BLOCK_START_MATCHER = /#{BLOCK_START_PATTERN}/
    BLOCK_CLOSE_MATCHER = /{{\/\s*.+?\s*}}/
    BLOCK_MATCHER = /#{BLOCK_PATTERN}/


    attr_reader :document, :data, :blocks

    def initialize(document, data)
      @document = document
      @data = data
      @blocks = []
    end

    def find_blocks
      return unless document.text =~ BLOCK_MATCHER

      paragraphs = document.css('w|t')

      while paragraph = paragraphs.shift do
        content = paragraph.text
        full_match = BLOCK_MATCHER.match(content)
        start_match = !full_match && BLOCK_START_MATCHER.match(content)

        next unless full_match || start_match

        if full_match
          blocks << ConditionalBlock.new(element: paragraph)
        else
          tag_name = start_match[2]
          block_elements = all_block_elements(tag_name, paragraph, paragraphs)

          # We'll ignore conditional blocks that have no correspondent closing tag
          next unless block_elements

          blocks << ConditionalBlock.new(elements: block_elements)
        end
      end
    end

    private

    # Gets all the XML nodes that involve a non-inline conditonal block,
    # starting from the element that contains the conditional block start up
    # to the element containing the conditional block ending
    def all_block_elements(tag_name, initial_element, next_elements)
      closing_block_pattern = BLOCK_NAMED_CLOSE_PATTERN % { tag_name: tag_name }
      closing_block_matcher = /#{closing_block_pattern}/
      paragraphs = Nokogiri::XML::NodeSet.new(document, [initial_element])

      return unless next_elements.text =~ closing_block_matcher

      until (paragraph = next_elements.shift).text =~ closing_block_matcher do
        paragraphs << paragraph
      end

      paragraphs << paragraph
    end
  end
end
