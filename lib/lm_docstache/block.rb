module LMDocstache
  class Block
    BLOCK_START = '{{%{operator}(%{name})\s*%{condition}}}'
    BLOCK_CONTENT = '.+?'
    BLOCK_CLOSE = '{{/%{ending}}}'

    attr_reader :name, :opening_element, :content_elements, :closing_element, :inverted, :condition, :inline
    def initialize(name:, data:, opening_element:, content_elements:, closing_element:, inverted:, condition: nil, inline: false)
      @name = name
      @data = data
      @opening_element = opening_element
      @content_elements = content_elements
      @closing_element = closing_element
      @inverted = inverted
      @condition = condition
      @inline = inline
    end

    def type
      return @type if instance_variable_defined?(:@type)
      return @type = :conditional if @inverted

      @type = @data.get(@name).is_a?(Array) ? :loop : :conditional
    end

    def loop?
      type == :loop
    end

    def conditional?
      type == :conditional
    end

    def self.find_all(name:, data:, elements:, inverted:, condition: nil, ignore_missing: true, child: false)
      operator = inverted ? '\^' : '#'
      base_opts = { name: name, data: data, condition: condition, inverted: inverted }
      full_tag_regex = build_regex(:full, name, condition, operator)

      if !ignore_missing && !elements.text.match(full_tag_regex)
        raise "Block not found in given elements"
      end

      full_block_matches = elements.select { |e| e.text.match(full_tag_regex) }

      return full_block_matches.flat_map do |match|
        unless match.elements.any?
          next extract_block_from_element(name, data, match, inverted, condition)
        end

        find_all(base_opts.merge(elements: match.elements, child: true))
      end if full_block_matches.any?

      start_tag_regex = build_regex(:start, name, condition, operator)
      close_tag_regex = build_regex(:close, name)
      opening = elements.find { |e| e.text.match(start_tag_regex) }
      content = []
      next_sibling = opening.next

      while !next_sibling.text.match(close_tag_regex)
        content << next_sibling
        next_sibling = next_sibling.next
      end

      Block.new(base_opts.merge(
        opening_element: opening,
        content_elements: content,
        closing_element: next_sibling
      ))
    end

    def self.extract_block_from_element(name, data, element, inverted, condition)
      Block.new(
        name: name,
        data: data,
        inverted: inverted,
        condition: condition,
        inline: true,
        opening_element: element.parent.previous,
        content_elements: [element.parent],
        closing_element: element.parent.next
      )
    end

    class << self
      private

      def build_regex(type, name, condition = nil, operator = nil)
        case type
        when :start
          pattern_data = { name: name, operator: operator, condition: condition }

          /#{BLOCK_START % pattern_data}/m
        when :close
          /#{BLOCK_CLOSE % { ending: name }}/
        when :full
          pattern = "#{BLOCK_START}#{BLOCK_CONTENT}#{BLOCK_CLOSE}"
          pattern_data = { name: name, operator: operator, condition: condition, ending: '\k<1>' }

          /#{pattern % pattern_data}/m
        end
      end
    end
  end
end
