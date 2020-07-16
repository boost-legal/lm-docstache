module LMDocstache
  class Block
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
      @type ||= if @inverted
        :conditional
      else
        if @data.get(@name).is_a? Array
          :loop
        else
          :conditional
        end
      end
    end

    def loop?
      type == :loop
    end

    def conditional?
      type == :conditional
    end

    def self.find_all(name:, data:, elements:, inverted:, condition: nil, ignore_missing: true, child: false)
      inverted_op = inverted ? '\^' : '\#'
      full_tag_regex = /\{\{#{inverted_op}(#{name})\s?#{condition}\}\}.+?\{\{\/\k<1>\}\}/m
      start_tag_regex = /\{\{#{inverted_op}#{name}\s?#{condition}\}\}/m
      close_tag_regex = /\{\{\/#{name}\}\}/s

      if elements.text.match(full_tag_regex)
        if elements.any? { |e| e.text.match(full_tag_regex) }
          matches = elements.select { |e| e.text.match(full_tag_regex) }
          return matches.flat_map do |match|
            if match.elements.any?
              find_all(name: name, data: data, elements: match.elements, inverted: inverted, condition: condition, child: true)
            else
              extract_block_from_element(name, data, match, inverted, condition)
            end
          end
        else
          opening = elements.find { |e| e.text.match(start_tag_regex) }
          content = []
          next_sibling = opening.next
          while !next_sibling.text.match(close_tag_regex)
            content << next_sibling
            next_sibling = next_sibling.next
          end
          closing = next_sibling
          return Block.new(name: name, data: data, opening_element: opening, content_elements: content, closing_element: closing, inverted: inverted, condition: condition)
        end
      else
        raise "Block not found in given elements" unless ignore_missing
      end
    end

    def self.extract_block_from_element(name, data, element, inverted, condition)
      return Block.new(name: name, data: data, opening_element: element.parent.previous, content_elements: [element.parent], closing_element: element.parent.next, inverted: inverted, condition: condition, inline: true)
    end
  end
end
