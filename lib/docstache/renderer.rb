module Docstache
  class Renderer
    BLOCK_REGEX = /\{\{([\#\^])([\w\.]+)\}\}.+?\{\{\/\k<2>\}\}/m

    def initialize(xml, data)
      @content = xml
      @data = DataScope.new(data)
    end

    def render
      find_and_expand_blocks
      replace_tags(@content, @data)
      return @content
    end

    private

    def find_and_expand_blocks
      blocks = @content.text.scan(BLOCK_REGEX)
      found_blocks = blocks.uniq.map { |block|
        inverted = block[0] == "^"
        Block.find_all(name: block[1], elements: @content.elements, data: @data, inverted: inverted)
      }.flatten
      found_blocks.each do |block|
        expand_and_replace_block(block)
      end
    end

    def expand_and_replace_block(block)
      case block.type
      when :conditional
        case condition = @data.get(block.name)
        when Array
          condition = !condition.empty?
        else
          condition = !!condition
        end
        condition = !condition if block.inverted
        unless condition
          block.content_elements.each(&:unlink)
        end
      when :loop
        set = @data.get(block.name)
        content = set.map { |item|
          data = DataScope.new(item, @data)
          elements = block.content_elements.map(&:clone)
          replace_tags(Nokogiri::XML::NodeSet.new(@content, elements), data)
        }
        content.each do |els|
          el = els[0]
          els[1..-1].each do |next_el|
            el.after(next_el)
            el = next_el
          end
          block.closing_element.before(els[0])
        end
        block.content_elements.each(&:unlink)
      end
      block.opening_element.unlink
      block.closing_element.unlink
    end

    def replace_tags(elements, data)
      elements.css('w|t').each do |text_el|
        if !(results = text_el.text.scan(/\{\{([\w\.]+)\}\}/).flatten).empty?
          rendered_string = text_el.text
          results.each do |r|
            rendered_string.gsub!(/\{\{#{r}\}\}/, text(data.get(r)))
          end
          text_el.content = rendered_string
        end
      end
      return elements
    end

    def text(obj)
      "#{obj}"
    end

  end
end
