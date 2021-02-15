module LMDocstache
  class Renderer
    BLOCK_REGEX = /\{\{([\#\^])([\w\.]+)(?:(\s(?:==|~=)\s?.+?))?\}\}.+?\{\{\/\k<2>\}\}/m

    attr_reader :parser

    def initialize(xml, data, remove_role_tags = false)
      @content = xml
      @data = DataScope.new(data)
      @remove_role_tags = remove_role_tags
      @parser = Parser.new(xml, data)
    end

    def render
      parser.parse_and_update_document!
      remove_role_tags if @remove_role_tags
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

    private

    def remove_role_tags
      @content.css('w|t').each do |text_el|
        results = text_el.text.scan(Document::ROLES_REGEXP).map {|r| r.first }
        unless results.empty?
          rendered_string = text_el.text
          results.each do |result|
            padding = "".ljust(result.size, " ")
            rendered_string.gsub!(result, padding)
          end
          text_el.content = rendered_string
        end
      end
    end

    private

    def get_condition(name, condition, inverted = false)
      case condition = @data.get(name, condition: condition)
      when Array
        condition = !condition.empty?
      else
        condition = !!condition
      end
      condition = !condition if inverted

      condition
    end
  end
end
