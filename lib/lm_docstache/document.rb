module LMDocstache
  class Document
    TAGS_REGEXP = /{{.+?}}/
    ROLES_REGEXP = /({{(sig|sigfirm|date|check|text|initial)\|(req|noreq)\|(.+?)}})/

    def initialize(*paths)
      raise ArgumentError if paths.empty?

      @path = paths.shift
      @zip_file = Zip::File.open(@path)
      @document = Nokogiri::XML(unzip_read(@zip_file, "word/document.xml"))
      zip_files = paths.map { |path| Zip::File.open(path) }
      documents = zip_files.map { |f| Nokogiri::XML(unzip_read(f, "word/document.xml")) }

      load_references
      documents.each do |doc|
        @document.css('w|p').last.after(page_break)
        @document.css('w|p').last.after(doc.css('w|body > *:not(w|sectPr)'))
      end

      find_documents_to_interpolate
    end

    def usable_role_tags
      @documents.values.flat_map do |document|
        document.css('w|t')
          .select { |tag| tag.text =~ ROLES_REGEXP }
          .flat_map { |tag|
            tag.text.scan(ROLES_REGEXP)
              .map {|r| r.first }
          }
      end
    end

    def tags
      @documents.values.flat_map do |document|
        document.text.strip.scan(TAGS_REGEXP)
      end
    end

    def usable_tags
      @documents.values.reduce([]) do |tags, document|
        document.css('w|t').reduce(tags) do |document_tags, text_node|
          document_tags.push(*text_node.text.scan(TAGS_REGEXP))
        end
      end
    end

    def usable_tag_names
      usable_tags.reject { |tag| tag =~ ROLES_REGEXP }.map do |tag|
        tag.scan(/\{\{[\/#^]?(.+?)(?:(\s((?:==|~=))\s?.+?))?\}\}/)
        $1
      end.compact.uniq
    end

    def unusable_tags
      unusable_tags = tags

      usable_tags.each do |usable_tag|
        index = unusable_tags.index(usable_tag)
        unusable_tags.delete_at(index) if index
      end

      unusable_tags
    end

    def fix_errors
      problem_paragraphs.each { |pg| flatten_paragraph(pg) if pg }
    end

    def errors?
      tags.length != usable_tags.length
    end

    def save(path = @path)
      buffer = zip_buffer(@documents)
      File.open(path, "w") { |f| f.write buffer.string }
    end

    def render_file(output, data = {}, render_options = {})
      buffer = zip_buffer(render_documents(data, nil, render_options))
      File.open(output, "w") { |f| f.write buffer.string }
    end

    def render_replace(output, text)
      buffer = zip_buffer(render_documents({}, text))
      File.open(output, "w") { |f| f.write buffer.string }
    end

    def render_stream(data = {})
      buffer = zip_buffer(render_documents(data))
      buffer.rewind
      buffer.sysread
    end

    def render_xml(data = {})
      render_documents(data)
    end

    private

    def render_documents(data, text = nil, render_options = {})
      Hash[
        @documents.map do |(path, document)|
          [path, render_document(document, data, text, render_options)]
        end
      ]
    end

    def render_document(document, data, text, render_options)
      renderer = LMDocstache::Renderer.new(document.dup, data, render_options)
      text ? renderer.render_replace(text) : renderer.render
    end

    def problem_paragraphs
      unusable_tags.flat_map do |tag|
        @documents.values.inject([]) do |tags, document|
          faulty_paragraphs = document
            .css('w|p')
            .select { |paragraph| paragraph.text =~ /#{Regexp.escape(tag)}/ }

          tags + faulty_paragraphs
        end
      end
    end

    def flatten_paragraph(paragraph)
      return if (run_nodes = paragraph.css('w|r')).size < 2

      while run_node = run_nodes.pop
        next if run_nodes.empty?

        style_node = run_node.at_css('w|rPr')
        style_html = style_node ? style_node.inner_html : ''
        previous_run_node = run_nodes.last
        previous_style_node = previous_run_node.at_css('w|rPr')
        previous_style_html = previous_style_node ? previous_style_node.inner_html : ''
        previous_text_node = previous_run_node.at_css('w|t')
        current_text_node = run_node.at_css('w|t')

        next if style_html != previous_style_html
        next if current_text_node.nil? || previous_text_node.nil?

        previous_text_node.content = previous_text_node.text + run_node.text
        run_node.unlink
      end
    end

    def unzip_read(zip, zip_path)
      file = zip.find_entry(zip_path)
      contents = ""
      file.get_input_stream { |f| contents = f.read }

      contents
    end

    def zip_buffer(documents)
      Zip::OutputStream.write_buffer do |output|
        @zip_file.entries.each do |entry|
          next if documents.keys.include?(entry.name)

          output.put_next_entry(entry.name)
          output.write(entry.get_input_stream.read)
        end

        documents.each do |path, document|
          output.put_next_entry(path)
          output.write(document.to_xml(indent: 0).gsub("\n", ""))
        end
      end
    end

    def page_break
      Nokogiri::XML::Node.new('p', @document).tap do |paragraph_node|
        paragraph_node.namespace = @document.at_css('w|p:last').namespace
        run_node = Nokogiri::XML::Node.new('r', @document)
        page_break_node = Nokogiri::XML::Node.new('br', @document)
        page_break_node['w:type'] = 'page'

        paragraph_node << run_node
        paragraph_node << page_break_node
      end
    end

    def load_references
      @references = {}
      ref_xml = Nokogiri::XML(unzip_read(@zip_file, "word/_rels/document.xml.rels"))

      ref_xml.css("Relationship").each do |ref|
        id = ref.attributes["Id"].value
        @references[id] = {
          id: id,
          type: ref.attributes["Type"].value.split("/")[-1].to_sym,
          target: ref.attributes["Target"].value
        }
      end
    end

    def find_documents_to_interpolate
      @documents = { "word/document.xml" => @document }

      @document.css("w|headerReference, w|footerReference").each do |header_ref|
        next unless @references.has_key?(header_ref.attributes["id"].value)

        ref = @references[header_ref.attributes["id"].value]
        document_path = "word/#{ref[:target]}"
        @documents[document_path] = Nokogiri::XML(unzip_read(@zip_file, document_path))
      end
    end
  end
end
