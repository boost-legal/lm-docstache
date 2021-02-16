module LMDocstache
  class Renderer
    BLOCK_REGEX = /\{\{([\#\^])([\w\.]+)(?:(\s(?:==|~=)\s?.+?))?\}\}.+?\{\{\/\k<2>\}\}/m

    attr_reader :parser, :options

    def initialize(xml, data, options = {})
      @content = xml
      @options = options
      @remove_role_tags = options.fetch(:remove_role_tags, false)
      @parser = Parser.new(xml, data, options.slice(:skip_variable_patterns))
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
  end
end
