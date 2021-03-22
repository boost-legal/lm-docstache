module LMDocstache
  class HideCustomTags
    attr_reader :document, :hide_custom_tags

    # The +hide_custom_tags+ options is an +Array+ of +Regexp+ or +String+ representing
    # the pattern you expect to keep at the document but with white font color.
    #
    # You have to remember is not acceptable to have capture groups in your +Regexp's+.
    # We don't accept because we need to find all parts of your text, split it in multiple runs
    # and add document background color or white font color to matching custom tags.
    def initialize(document:, hide_custom_tags: [])
      @document = document
      @hide_custom_tags = hide_custom_tags
    end

    # Find all run nodes matching hide custom tags +Regexp's+ options you defined, split it
    # in multiple runs and replace font color to document background color or white in the matching tag run node.
    def hide_custom_tags!
      hide_custom_tags.each do |full_pattern|
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
                replace_content(run_node_with_match, matched_tag)
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
