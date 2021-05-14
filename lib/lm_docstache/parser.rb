module LMDocstache
  class Parser
    BLOCK_TYPE_PATTERN = '(#|\^)\s*'
    BLOCK_VARIABLE_PATTERN = '([^\s~=]+)'
    BLOCK_OPERATOR_PATTERN = '\s*(~=|==)\s*'
    BLOCK_VALUE_PATTERN = '([^\}]+?)\s*'
    BLOCK_START_PATTERN = "{{#{BLOCK_TYPE_PATTERN}#{BLOCK_VARIABLE_PATTERN}"\
                          "#{BLOCK_OPERATOR_PATTERN}#{BLOCK_VALUE_PATTERN}}}"
    BLOCK_CONTENT_PATTERN = '(.*?)'
    BLOCK_CLOSE_PATTERN = '{{/\s*\k<2>\s*}}'
    BLOCK_NAMED_CLOSE_PATTERN = '{{/\s*%{tag_name}\s*}}'
    BLOCK_PATTERN = "#{BLOCK_START_PATTERN}#{BLOCK_CONTENT_PATTERN}"\
                    "#{BLOCK_CLOSE_PATTERN}"

    BLOCK_START_MATCHER = /#{BLOCK_START_PATTERN}/
    BLOCK_CLOSE_MATCHER = /{{\/\s*.+?\s*}}/
    BLOCK_MATCHER = /#{BLOCK_PATTERN}/
    VARIABLE_MATCHER = /{{([^#\^\/].*?)}}/

    attr_reader :document, :data, :blocks, :special_variable_replacements, :hide_custom_tags
    attr_reader :data_sequential_replacement

    # Constructor +data+ argument is a +Hash+ where the key is
    # expected to be a +String+ representing the replacement block value. +Hash+
    # key must not contain the `{{}}` part, but only the pattern characters.
    # As for the values of the +Hash+, we have options:
    #
    # * +String+  will be the value that will replace matching string.
    # * +Array<String>+ will be an ordered sequence of values that will replace the matched string following
    # document matching order.
    #
    # Example:
    # { 'full_name' => 'John Doe', 'text|req|Client' => ['John', 'Matt', 'Paul'] }
    #
    # Constructor +options+ argument is a +Hash+ where keys can be:
    #
    # The +special_variable_replacements+ option is a +Hash+ where the key is
    # expected to be either a +Regexp+ or a +String+ representing the pattern
    # of more specific type of variables that deserves a special treatment. The
    # key must not contain the `{{}}` part, but only the pattern characters
    # inside of it. As for the values of the +Hash+, it tells the replacement
    # algorithm what to do with the matched string and there are the options:
    #
    # * +false+ -> in this case the matched variable will be kept without
    #   replacement
    # * +Proc+ -> when a +Proc+ instance is provided, it's expected it to be
    #   able to receive the matched string and to return the string that will be
    #   used as replacement
    # * any other value that will be turned into a string -> in this case, this
    #   will be the value that will replace the matched string
    #
    # The +hide_custom_tags+ options is a +Hash+ of +Regexp+ or +String+ keys representing
    # the pattern you expect to keep at the document but replacing the content to use
    # font color equal to document background color or white.
    # For the +Hash+ values we can have:
    #
    # * +false+ -> In this case we don't change the text content.
    # * +Proc+ -> When a +Proc+ instance is provided, it's expected it to be
    #   able to receive the matched string and to return the string that will be
    #   used as replacement.
    # * any other value that will be turned into a string -> in this case, this
    #   will be the value that will replace the matched string
    def initialize(document, data, options = {})
      @document = document
      @data = data.transform_keys(&:to_s).select {|e, v| !v.is_a?(Array) }
      @data_sequential_replacement = data.transform_keys(&:to_s).select {|e, v| v.is_a?(Array) }
      @special_variable_replacements = add_blocks_to_regexp(options.fetch(:special_variable_replacements, {}))
      @hide_custom_tags = add_blocks_to_regexp(options.fetch(:hide_custom_tags, {}))
    end

    # Replace +Regepx+ or +String+ keys to have the enclosing blocks
    def add_blocks_to_regexp(options)
      options.inject({}) do |x, (regexp_str, value)|
        key = regexp_str.is_a?(String) ? Regexp.new("{{#{regexp_str}}}") : /{{#{regexp_str.source}}/
        x[key] = value
        x
      end
    end

    def parse_and_update_document!
      hide_custom_tags!
      find_blocks
      replace_conditional_blocks_in_document!
      replace_data_sequentially_in_document!
      replace_variables_in_document!
    end

    private

    def find_blocks
      return @blocks if instance_variable_defined?(:@blocks)
      return @blocks = [] unless document.text =~ BLOCK_MATCHER

      @blocks = []
      paragraphs = document.css('w|p')

      while paragraph = paragraphs.shift do
        content = paragraph.text
        full_match = BLOCK_MATCHER.match(content)
        start_match = !full_match && BLOCK_START_MATCHER.match(content)

        next unless full_match || start_match

        if full_match
          @blocks.push(*ConditionalBlock.inline_blocks_from_paragraph(paragraph))
        else
          condition = condition_from_match_data(start_match)
          comprised_paragraphs = all_block_elements(start_match[2], paragraph, paragraphs)

          # We'll ignore conditional blocks that have no correspondent closing tag
          next unless comprised_paragraphs

          @blocks << ConditionalBlock.new(
            elements: comprised_paragraphs,
            condition: condition
          )
        end
      end

      @blocks
    end

    def hide_custom_tags!
      custom_tags = HideCustomTags.new(document: document, hide_custom_tags: hide_custom_tags)
      custom_tags.hide_custom_tags!
    end

    # Evaluates all conditional blocks inside the given XML document and keep or
    # remove their content inside the document, depending on the truthiness of
    # the condition on each given conditional block.
    def replace_conditional_blocks_in_document!
      blocks.each do |conditional_block|
        value = data[conditional_block.condition.left_term]
        conditional_block.evaluate_with_value!(value)
      end
    end

    # It simply replaces all the referenced variables inside document by their
    # correspondent values provided in the attributes hash +data+.
    def replace_variables_in_document!
      document.css('w|t').each do |text_node|
        text = text_node.text

        next unless text =~ VARIABLE_MATCHER
        next if has_skippable_variable?(text)

        variable_replacement = special_variable_replacement(text)

        text.gsub!(VARIABLE_MATCHER) do |_match|
          next data[$1].to_s unless variable_replacement

          variable_replacement.is_a?(Proc) ?
            variable_replacement.call($1) :
            variable_replacement.to_s
        end
        text_node.content = text
      end
    end

    def replace_data_sequentially_in_document!
      data_sequential_replacement.each do |tag_key, values|

        tag = Regexp.escape("{{#{tag_key}}}")
        pattern_found = 0

        document.css('w|t').each do |text_node|
          text = text_node.text

          if text.match(tag)

            text.gsub!(/#{tag}/) do |_match|
              value = values[pattern_found]
              # if there is no more available value replace the content with empty string
              return '' unless value

              pattern_found +=1
              value
            end

            text_node.content = text
          end
        end
      end
    end

    def has_skippable_variable?(text)
      return true if hide_custom_tags.find { |(pattern, value)| text =~ pattern }
      !!special_variable_replacements.find do |(pattern, value)|
        text =~ pattern && value == false
      end
    end

    def special_variable_replacement(text)
      Array(
        special_variable_replacements.find do |(pattern, value)|
          text =~ pattern && !!value
        end
      ).last
    end

    # This method created a +Condition+ instance for a partial conditional
    # block, which in this case it's the start block part of it, represented by
    # a string like the following:
    #
    #    {{#variable == value}}
    #
    # @param match [MatchData]
    #
    # If converted into an +Array+, +match+ could be represented as follows:
    #
    #    [
    #      '{{#variable == value}}',
    #      '#',
    #      'variable',
    #      '==',
    #      'value'
    #    ]
    #
    def condition_from_match_data(match)
      Condition.new(
        left_term: match[2],
        right_term: match[4],
        operator: match[3],
        negation: match[1] == '^',
        original_match: match[0]
      )
    end

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
