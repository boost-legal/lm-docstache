module LMDocstache
  class Renderer
    BLOCK_REGEX = /\{\{([\#\^])([\w\.]+)(?:(\s(?:==|~=)\s?.+?))?\}\}.+?\{\{\/\k<2>\}\}/m

    attr_reader :parser

    def initialize(xml, data, options = {})
      @content = xml
      option_types = [:special_variable_replacements, :hide_custom_tags]
      @parser = Parser.new(xml, data, options.slice(*option_types))
    end

    def render
      parser.parse_and_update_document!
      @content
    end

    def render_replace(text)
      @content.css('w|t').each do |text_el|
        if !(text_el.text.scan(/\|-Lawmatics Test-\|/)).empty?
          text_el.content = text
        end
      end
      @content
    end
  end
end
