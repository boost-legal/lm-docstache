module LMDocstache
  class Renderer
    BLOCK_REGEX = /\{\{([\#\^])([\w\.]+)(?:(\s(?:==|~=)\s?.+?))?\}\}.+?\{\{\/\k<2>\}\}/m

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
      found_blocks = blocks.uniq.flat_map do |block|
        inverted = block[0] == "^"
        Block.find_all(name: block[1], elements: @content.elements, data: @data, inverted: inverted, condition: block[2])
      end
      found_blocks.each do |block|
        if block.inline
          handle_inline_conditional(block) if block.present?
        else
          expand_and_replace_block(block) if block.present?
        end
      end
    end

    def handle_inline_conditional(block)
      replace_conditional(block, "HEY!!")
# binding.pry
#       block.content_elements.css('w|t').each do |text_el|
#         if !(results = text_el.text.scan(/\{\{([\w\.]+)\}\}/).flatten).empty?
#           rendered_string = text_el.text
#           results.each do |r|
#             rendered_string.gsub!("{{#{r}}}", "boo")
#           end
#           text_el.content = rendered_string
#         end
#       end
#       return elements

      # case block.type
      # when :conditional
      #   case condition = @data.get(block.name, condition: block.condition)
      #   when Array
      #     condition = !condition.empty?
      #   else
      #     condition = !!condition
      #   end
      #   condition = !condition if block.inverted
      #   unless condition
      #     block.content_elements.each(&:unlink) # instead of unlinking, replace the text!
      #   end
      # when :loop
      #   # TODO handle inline loops
      # end
    end

    def expand_and_replace_block(block)
      case block.type
      when :conditional
        case condition = @data.get(block.name, condition: block.condition)
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
        set = @data.get(block.name, condition: block.condition)
        content = set.map do |item|
          data = DataScope.new(item, @data)
          elements = block.content_elements.map(&:clone)
          replace_tags(Nokogiri::XML::NodeSet.new(@content, elements), data)
        end
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

    def replace_conditional(block, data)
      @content.css('w|t').each do |text_el|
        start_tag = "##{block.name}#{block.condition}"
        end_tag = "/#{block.name}"

        rendered_string = text_el.text

        if !(results = rendered_string.scan(/\{\{\#(.*?)\}\}/).flatten).empty?
          results.each do |r|
            rendered_string.sub!("{{##{r}}}", "")
            rendered_string.sub!("{{/#{block.name}}}", "")
          end
        end

        if !(results1 = rendered_string.scan(/\{\{\^(.*?)\}\}/).flatten).empty?
          results1.each do |r|
            rendered_string.sub!("{{^#{r}}}", "")
            rendered_string.sub!("{{/#{block.name}}}", "")
          end
        end

        text_el.content = rendered_string

        # if !(results = text_el.text.scan(/\{\{([\w\.]+)\}\}/).flatten).empty?
        #   rendered_string = text_el.text
        #   results.each do |r|
        #     rendered_string.gsub!("{{#{r}}}", data.get(r).to_s)
        #   end
        #   text_el.content = rendered_string
        # end
      end
    end

    def replace_tags(elements, data)
      elements.css('w|t').each do |text_el|
        if !(results = text_el.text.scan(/\{\{([\w\.]+)\}\}/).flatten).empty?
          rendered_string = text_el.text
          results.each do |r|
            rendered_string.gsub!("{{#{r}}}", data.get(r).to_s)
          end
          text_el.content = rendered_string
        end
      end
      return elements
    end
  end
end
