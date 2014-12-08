module Docstache
  class Block
    attr_reader :name, :opening_element, :content_elements, :closing_element, :inverted
    def initialize(name:, data:, opening_element:, content_elements:, closing_element:, inverted:)
      @name = name
      @data = data
      @opening_element = opening_element
      @content_elements = content_elements
      @closing_element = closing_element
      @inverted = inverted
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

    def self.find_all(name:, data:, elements:, inverted:)
      if elements.text.match(/\{\{#{inverted ? '\^' : '\#'}#{name}\}\}.+\{\{\/#{name}\}\}/m)
        if elements.any? { |e| e.text.match(/\{\{#{inverted ? '\^' : '\#'}#{name}\}\}.+\{\{\/#{name}\}\}/m) }
          matches = elements.select { |e| e.text.match(/\{\{#{inverted ? '\^' : '\#'}#{name}\}\}.+\{\{\/#{name}\}\}/m) }
          finds = matches.map { |match| find_all(name: name, data: data, elements: match.elements, inverted: inverted) }.flatten
          return finds
        else
          opening = elements.select { |e| e.text.match(/\{\{#{inverted ? '\^' : '\#'}#{name}\}\}/) }.first
          content = []
          next_sibling = opening.next
          while !next_sibling.text.match(/\{\{\/#{name}\}\}/)
            content << next_sibling
            next_sibling = next_sibling.next
          end
          closing = next_sibling
          return Block.new(name: name, data: data, opening_element: opening, content_elements: content, closing_element: closing, inverted: inverted)
        end
      else
        raise "Block not found in given elements"
      end
    end

  end
end
