module LMDocstache
  class HideCustomTags
    HIDE_BACKGROUND_COLOR = 'FFFFFF'

    attr_reader :document, :hide_custom_tags
    def initialize(document:, hide_custom_tags: [])
      @document = document
      @hide_custom_tags = hide_custom_tags
    end

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
              matched_tags = tag_contents[:matched_tags][idx]
              nodes_list = [remainder_run_node]
              if matched_tags
                replace_style(run_node_with_match)
                replace_content(run_node_with_match, matched_tags)
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
    def split_tag_content(text, full_pattern)
      content_list = text.split(full_pattern)
      content_list = content_list.empty? ? [''] : content_list
      matched_tags = text.scan(full_pattern)
      { content_list: content_list, matched_tags: matched_tags}
    end

    def replace_style(run_node)
      style = run_node.at_css('w|rPr')
      w_color = style.at_css('w|color')
      w_color.unlink if w_color
      if style
        style << "<w:color w:val=\"#{HIDE_BACKGROUND_COLOR}\"/>"
      else
        run_node << "<w:rPr><w:color w:val=\"#{HIDE_BACKGROUND_COLOR}\"/></w:rPr>"
      end
    end

    def replace_content(run_node, content)
      run_text = run_node.at_css('w|t')
      run_text['xml:space'] = 'preserve'
      run_text.content = content
    end
  end
end
