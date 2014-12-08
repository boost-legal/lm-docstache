module Docstache
  class Document
    def initialize(*paths)
      raise ArgumentError if paths.empty?
      @path = paths.shift
      @zip_file = Zip::File.open(@path)
      @document = Nokogiri::XML(unzip_read(@zip_file, "word/document.xml"))
      zip_files = paths.map{|p| Zip::File.open(p)}
      documents = zip_files.map{|f| Nokogiri::XML(unzip_read(f, "word/document.xml"))}
      documents.each do |doc|
        @document.css('w|p').last.add_next_sibling(page_break)
        @document.css('w|p').last.add_next_sibling(doc.css('w|body > *:not(w|sectPr)'))
      end
    end

    def tags
      @document.text.gsub(/\s+/, '').scan(/\{\{[\w\.\/\#\^]+\}\}/)
    end

    def usable_tags
      @document.css('w|t').select { |tag| tag.text =~ /\{\{[\w\.\/\#]+\}\}/ }.map(&:text)
    end

    def fix_errors
      missing_tags = tags - usable_tags
      problem_paragraphs = missing_tags.map { |tag|
        @document.css('w|p').select {|t| t.text =~ /#{tag}/}.first
      }

      problem_paragraphs.each do |p|
        flatten_paragraph(p) if p
      end
    end

    def errors?
      tags.length != usable_tags.length
    end

    def save
      buffer = zip_buffer(@document)
      File.open(@path, "w") {|f| f.write buffer.string}
    end

    def render_file(output, data={})
      rendered = Docstache::Renderer.new(@document, data).render
      buffer = zip_buffer(rendered)
      File.open(output, "w") {|f| f.write buffer.string}
    end

    def render_stream(data={})
      rendered = Docstache::Renderer.new(@document, data).render
      buffer = zip_buffer(rendered)
      buffer.rewind
      return buffer.sysread
    end

    private

    def flatten_paragraph(p)
      runs = p.css('w|r')
      host_run = runs.shift
      runs.each do |run|
        host_run.at_css('w|t').content += run.text
        run.unlink
      end
    end

    def unzip_read(zip, zip_path)
      file = zip.find_entry(zip_path)
      contents = ""
      file.get_input_stream do |f|
        contents = f.read
      end
      return contents
    end

    def zip_buffer(document)
      buffer = Zip::OutputStream.write_buffer do |out|
        @zip_file.entries.each do |e|
          unless ["word/document.xml"].include?(e.name)
            out.put_next_entry(e.name)
            out.write(e.get_input_stream.read)
          end
        end
        out.put_next_entry("word/document.xml")
        out.write(@document.to_xml(indent: 0).gsub("\n", ""))
      end
      return buffer
    end

    def page_break
      p = Nokogiri::XML::Node.new("p", @document)
      p.namespace = @document.at_css('w|p:last').namespace
      r = Nokogiri::XML::Node.new("r", @document)
      p.add_child(r)
      br = Nokogiri::XML::Node.new("br", @document)
      r.add_child(br)
      br['w:type'] = "page"
      return p
    end
  end
end
