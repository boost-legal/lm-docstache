module Docstache
  class Document
    def initialize(*paths)
      raise ArgumentError if paths.empty?
      @path = paths.shift
      @zip_file = Zip::File.open(@path)
      load_references
      @document = Nokogiri::XML(unzip_read(@zip_file, "word/document.xml"))
      zip_files = paths.map{|p| Zip::File.open(p)}
      documents = zip_files.map{|f| Nokogiri::XML(unzip_read(f, "word/document.xml"))}
      documents.each do |doc|
        @document.css('w|p').last.add_next_sibling(page_break)
        @document.css('w|p').last.add_next_sibling(doc.css('w|body > *:not(w|sectPr)'))
      end
      find_documents_to_interpolate
    end

    def tags
      @documents.values.flat_map { |document|
        document.text.strip.scan(/\{\{.+?\}\}/)
      }
    end

    def usable_tags
      @documents.values.flat_map { |document|
        document.css('w|t').select { |tag| tag.text =~ /\{\{.+?\}\}/ }.flat_map { |tag|
          tag.text.scan(/\{\{.+?\}\}/)
        }
      }
    end

    def unusable_tags
      unusable_tags = tags
      usable_tags.each do |usable_tag|
        index = unusable_tags.index(usable_tag)
        unusable_tags.delete_at(index) if index
      end
      return unusable_tags
    end

    def fix_errors
      problem_paragraphs.each do |p|
        flatten_paragraph(p) if p
      end
    end

    def errors?
      tags.length != usable_tags.length
    end

    def save
      buffer = zip_buffer(@documents)
      File.open(@path, "w") {|f| f.write buffer.string}
    end

    def render_file(output, data={})
      rendered_documents = Hash[
        @documents.map { |(path, document)|
          [path, Docstache::Renderer.new(document.dup, data).render]
        }
      ]
      buffer = zip_buffer(rendered_documents)
      File.open(output, "w") {|f| f.write buffer.string}
    end

    def render_stream(data={})
      rendered_documents = Hash[
        @documents.map { |(path, document)|
          [path, Docstache::Renderer.new(document.dup, data).render]
        }
      ]
      buffer = zip_buffer(rendered_documents)
      buffer.rewind
      return buffer.sysread
    end

    private

    def problem_paragraphs
      unusable_tags.flat_map { |tag|
        @documents.values.inject([]) { |tags, document|
          tags + document.css('w|p').select {|t| t.text =~ /#{Regexp.escape(tag)}/}
        }
      }
    end

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

    def zip_buffer(documents)
      buffer = Zip::OutputStream.write_buffer do |out|
        @zip_file.entries.each do |e|
          unless documents.keys.include?(e.name)
            out.put_next_entry(e.name)
            out.write(e.get_input_stream.read)
          end
        end
        documents.each do |path, document|
          out.put_next_entry(path)
          out.write(document.to_xml(indent: 0).gsub("\n", ""))
        end
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
      @documents = {"word/document.xml" => @document}
      @document.css("w|headerReference, w|footerReference").each do |header_ref|
        if @references.has_key?(header_ref.attributes["id"].value)
          ref = @references[header_ref.attributes["id"].value]
          @documents["word/#{ref[:target]}"] = Nokogiri::XML(unzip_read(@zip_file, "word/#{ref[:target]}"))
        end
      end
    end
  end
end
