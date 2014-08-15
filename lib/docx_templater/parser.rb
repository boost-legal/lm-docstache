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
      process_content()
 
      buffer = zip_create(@content, @footnotes)
      if File.open(@out_filepath, "w") {|f| f.write(buffer.string) }
        return @out_filepath.to_s
      else
        return false
      end
    end

    def render_stream
      process_content()

      buffer = zip_create(@content, @footnotes)
      buffer.rewind
      return buffer.sysread
    end
 
    private

    def process_content()
      parse_content(@content.elements)
      parse_content(@footnotes.elements)

      content_tr = @content.xpath('//w:tr')
      footnote_tr = @footnotes.xpath('//w:tr')

      cleanup_loop(content_tr)
      cleanup_loop(footnote_tr)
    end
 
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
 
    def extract_end_row(nd, key)
      if !nd.nil?
        case nd.text.to_s
        when /#END_ROW:#{key.upcase.to_s}#/
          puts "Found End Row for #{key.upcase.to_s}"
          return nd
        else
          return extract_end_row(nd.next, key)
        end
      else
        return nil
      end
    end

    def expand_loop(nd, end_nd, key, element)
      out = []
      case nd.text.to_s
      when /#BEGIN_ROW:#{key.upcase.to_s}#/
        out = expand_loop(nd.next, end_nd, key, element)
      when end_nd.text.to_s
        out = []
      when /#BEGIN_ROW:([A-Z0-9_]+)#/
        new_key = $1.downcase.to_sym
        out += process_loop(nd, new_key, element)
      else
        new_node = nd.dup
        puts "Adding Row #{nd.text} to list"
        parse_content(new_node.elements, element)
        out << new_node
        puts "Next Node is: #{nd.next.text.to_s}"
        out += expand_loop(nd.next, end_nd, key, element)
      end
      return out
    end


    def remove_loop(nd, key)
      if nd
        case nd.text.to_s
        when /#END_ROW:#{key.upcase.to_s}#/
          nd.unlink
        else
          remove_loop(nd.next, key)
          nd.unlink
        end
      end
    end


    def process_loop(nd, key, data)
      out = []
      puts "Found Loop #{key.upcase.to_s}"
      end_row = extract_end_row(nd, key)

      if !data.has_key?(key)
        nil # Error in the data model
        return []
      elsif data[key].empty?
        remove_loop(nd, key) # No data to put in
        return []
      else # Actual loop to process
        data_set = data[key]
        puts "Expanding Rows for loop #{key.upcase.to_s}"
        puts "Data count is #{data_set.count}"
        puts "Data is #{data_set}"
        
        data_set.each do |element|
          out += expand_loop(nd, end_row, key, element)
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
            # Get elements to add
            elements = process_loop(nd, key, data)
            # Add elements
            elements.reverse.each do |e|
              puts "Adding Row to file: #{e.text.to_s}"
              nd.add_next_sibling(e)
            end
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

    def cleanup_loop(nodeset) # Acts in w/tr only as loops are based on these
      nodeset.each do |nd|
        case nd.text.to_s
        when /#BEGIN_ROW:([A-Z0-9_]+)#/
          nd.unlink
        when /#END_ROW:([A-Z0-9_]+)#/
          nd.unlink
        when /\$[A-Z0-9_]+\$/
          nd.unlink
        end
      end
    end

    def subst_content(nd, data)
      inner = nd.inner_html
      keys = nd.text.scan(/\$([A-Z0-9_]+)\$/).map(&:first).map(&:downcase).map(&:to_sym)
      keys.each do |key|
        if data.has_key?(key)
          value = data[key]
          puts "Substituting $#{key.to_s.upcase}$ with #{value}"
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
