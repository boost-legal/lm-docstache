# encoding: UTF-8

# docx_templater -- Converts Word docx files into html or LaTeX via the kramdown syntax
# Copyright (C) 2014 pl0o0f (florent@cryph.net) and don't forget GPL
#
# This software has been inspired from:
# = https://github.com/jawspeak/ruby-docx-templater
# = https://github.com/michaelfranzl/docx_converter
# 
# It is a complete rewrite however but credits are credits and everybody should be thanked for their contribution
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module DocxTemplater
  class Render
    def initialize(options)
      @data = options[:data]
      @in_filepath = options[:inputfile]
      @out_filepath = options[:outputfile]
      
      @zipfile = Zip::File.new(@in_filepath)
      document_xml = unzip_read("word/document.xml")
      footnotes_xml = unzip_read("word/footnotes.xml")

      @content = Nokogiri::XML(document_xml)
      @footnotes = Nokogiri::XML(footnotes_xml)
    end
    
    def render_file
      parse_content(@content.elements)
      parse_content(@footnotes.elements)
    
      buffer = zip_create(@content, @footnotes)
      if File.open(@out_filepath, "w") {|f| f.write(buffer.string) }
        return @out_filepath.to_s
      else
        return false
      end
    end

    def render_stream
      parse_content(@content.elements)
      parse_content(@footnotes.elements)

      buffer = zip_create(@content, @footnotes)
      buffer.rewind
      return buffer.sysread
    end
 
    private
    
    def unzip_read(zip_path)
      file = @zipfile.find_entry(zip_path)
      contents = ""
      file.get_input_stream do |f|
        contents = f.read
      end
      return contents
    end

    def zip_create(content, footnotes)
      buffer = Zip::OutputStream.write_buffer do |out|
        @zipfile.entries.each do |e|
          unless ['word/document.xml', 'word/footnotes.xml'].include?(e.name)
            out.put_next_entry(e.name)
            out.write e.get_input_stream.read
          end
        end

        out.put_next_entry('word/document.xml')
        out.write content.to_xml(:indent => 0).gsub("\n","")

        out.put_next_entry('word/footnotes.xml')
        out.write footnotes.to_xml(:indent => 0).gsub("\n","")
      end

      return buffer
    end
 
    def parse_loop(nd, key, data)
      if !data.has_key?(key)
        nil
      elsif data[key].empty?
        remove_loop(nd, key)
      else
        data_set = data[key]
        rows = extract_loop_rows(nd, key)
        puts "Rows found: #{rows.map(&:text)}"
        expand_loop(nd, rows, data_set)
      end
    end

    def expand_loop(begin_nd, rows, data_set)
      data_set.each do |data_element|
        rows.each do |nd|
          case nd.text.to_s
          when /#BEGIN_ROW:([A-Z0-9_]+)#/
            new_key = $1.downcase.to_sym
            parse_loop(nd, new_key, data_element)
          else
            new_node = nd.dup
            nd.add_next_sibling(new_node)
            parse_content(new_node.elements, data_element)
            nd.unlink
          end
        end
      end
      begin_nd.unlink
    end

    def extract_loop_rows(nd, key)
      puts "Extracting Loops for #{key}"
      if nd
        case nd.text.to_s
        when /#BEGIN_ROW:#{key.upcase.to_s}#/
          return extract_loop_rows(nd.next, key)
        when /#END_ROW:#{key.upcase.to_s}#/
          nd.unlink
          return []
        else
          puts "Adding #{nd.text} to rows"
          return [nd] + extract_loop_rows(nd.next, key)
        end
      else
        return []
      end
    end

    def remove_loop(nd, key)
      if nd
        case nd.text.to_s
        when /#END_ROW:#{key.upcase.to_s}#/
          out = nd.next
          nd.unlink
        else
          out = remove_loop(nd.next, key)
          nd.unlink
        end
        return out
      end
    end

    def parse_content(elements, data=@data)
      elements.each do |nd|
        case nd.name
        when "tr"
          case nd.text.to_s
          when /#BEGIN_ROW:([A-Z0-9_]+)#/
            key = $1.downcase.to_sym
            parse_loop(nd, key, data)
          else # it's a normal table row
            parse_content(nd.elements, data)
          end
        when "t" # It's a leaf that contains data to replace
          subst_content(nd, data) 
        else # it's neither a leaf or a loop so let's process it
          parse_content(nd.elements, data)
        end
      end
    end

    def subst_content(nd, data)
      inner = nd.inner_html
      keys = nd.text.scan(/\$([A-Z0-9_]+)\$/).map(&:first).map(&:downcase).map(&:to_sym)
      keys.each do |key|
        if data.has_key?(key)
          value = data[key]
          inner.gsub!("$#{key.to_s.upcase}$", safe(value))
        end
      end
      if !keys.empty?
        nd.inner_html = inner
      end
    end

    def safe(text)
      text.to_s
    end
    
  end
end
