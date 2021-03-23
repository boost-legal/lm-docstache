module LMDocstache
  class HideCustomTags
    attr_reader :document, :hide_custom_tags

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
    def initialize(document:, hide_custom_tags: {})
      @document = document
      @hide_custom_tags = hide_custom_tags
    end

    # Find all run nodes matching hide custom tags +Regexp's+ options you defined, split it
    # in multiple runs and replace font color to document background color or white in the matching tag run node.
    # Replace content if you have defined any replacement value.
    def hide_custom_tags!
      hide_custom_tags.each do |full_pattern, value|
        paragraphs = document.css('w|p')
        while paragraph = paragraphs.shift do
          next unless paragraph.text =~ full_pattern
          run_nodes = paragraph.css('w|r')
          while run_node = run_nodes.shift
            next if run_node.text.to_s.strip.size == 0
            remainder_run_node = run_node.clone
            run_node.unlink
            tag_contents = split_tag_content(remainder_run_node.text, full_pattern)
            tag_contents[:content_list].each_with_index do |content, idx|
              replace_content(remainder_run_node, content)
              run_node_with_match = remainder_run_node.dup
              matched_tag = tag_contents[:matched_tags][idx]
              nodes_list = [remainder_run_node]
              if matched_tag
                replace_style(run_node_with_match)
                matched_content = matched_tag
                if value
                  matched_content = value.is_a?(Proc) ?
                       value.call(matched_tag) :
                       value.to_s
                end
                replace_content(run_node_with_match, matched_content)
                nodes_list << run_node_with_match
              end
              paragraph << Nokogiri::XML::NodeSet.new(document, nodes_list)
              remainder_run_node = remainder_run_node.clone
            end
          end
        end
      end
    end

    private

    def font_color
      @font_color ||= document.at_css('w|background')&.attr('w:color') || 'FFFFFF'
    end

    def split_tag_content(text, full_pattern)
      content_list = text.split(full_pattern)
      content_list = content_list.empty? ? [''] : content_list
      matched_tags = text.scan(full_pattern)
      { content_list: content_list, matched_tags: matched_tags}
    end

    def replace_style(run_node)
      style = run_node.at_css('w|rPr')
      if style
        w_color = style.at_css('w|color')
        w_color.unlink if w_color
        style << "<w:color w:val=\"#{font_color}\"/>"
      else
        run_node.prepend_child("<w:rPr><w:color w:val=\"#{font_color}\"/></w:rPr>")
      end
    end

    def replace_content(run_node, content)
      run_text = run_node.at_css('w|t')
      run_text['xml:space'] = 'preserve'
      run_text.content = content
    end
  end
end
