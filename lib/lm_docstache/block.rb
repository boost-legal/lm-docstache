module LMDocstache
  class Block
    attr_reader :name, :opening_element, :content_elements, :closing_element, :inverted, :condition
    def initialize(name:, data:, opening_element:, content_elements:, closing_element:, inverted:, condition: nil)
      @name = name
      @data = data
      @opening_element = opening_element
      @content_elements = content_elements
      @closing_element = closing_element
      @inverted = inverted
      @condition = condition
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

    def self.find_all(name:, data:, elements:, inverted:, condition: nil, ignore_missing: true)
      if elements.text.match(/\{\{#{inverted ? '\^' : '\#'}#{name}#{condition ? " when #{condition}" : ''}\}\}.+?\{\{\/#{name}\}\}/m)
        if elements.any? { |e| e.text.match(/\{\{#{inverted ? '\^' : '\#'}#{name}#{condition ? " when #{condition}" : ''}\}\}.+?\{\{\/#{name}\}\}/m) }
          matches = elements.select { |e| e.text.match(/\{\{#{inverted ? '\^' : '\#'}#{name}#{condition ? " when #{condition}" : ''}\}\}.+?\{\{\/#{name}\}\}/m) }
          finds = matches.flat_map { |match| find_all(name: name, data: data, elements: match.elements, inverted: inverted, condition: condition) }
          return finds
        else
          opening = elements.select { |e| e.text.match(/\{\{#{inverted ? '\^' : '\#'}#{name}#{condition ? " when #{condition}" : ''}\}\}/) }.first
          content = []
          next_sibling = opening.next
          while !next_sibling.text.match(/\{\{\/#{name}\}\}/)
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
  end
end
