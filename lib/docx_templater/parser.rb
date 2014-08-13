# encoding: UTF-8

# docx_converter -- Converts Word docx files into html or LaTeX via the kramdown syntax
# Copyright (C) 2013 Red (E) Tools Ltd. (www.thebigrede.net)
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
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module DocxTemplater
  class Parser
    def initialize(options)
      @output_dir = options[:output_dir]
      @docx_filepath = options[:inputfile]
      
      @image_subdir_filesystem = options[:image_subdir_filesystem]
      @image_subdir_kramdown = options[:image_subdir_kramdown]
      
      @relationships_hash = {}
      
      @zipfile = Zip::ZipFile.new(@docx_filepath)
      @out_xml = Nokogiri::XML::Document.new
    end
    
    def parse
      document_xml = unzip_read("word/document.xml")
      footnotes_xml = unzip_read("word/footnotes.xml")
      
      content = Nokogiri::XML(document_xml)
      footnotes = Nokogiri::XML(footnotes_xml)
      
      footnote_definitions = parse_footnotes(footnotes)
      output_content = parse_content(content.elements.first)
      
      return {
        :content => output_content,
        :footnote_definitions => footnote_definitions
      }
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
    
    def parse_relationships(relationships)
      output = {}
      relationships.children.first.children.each do |rel|
        rel_id = rel.attributes["Id"].value
        rel_target = rel.attributes["Target"].value
        output[rel_id] = rel_target
      end
      return output
    end
    
    def parse_footnotes(node)
      output = {}
      node.xpath("//w:footnote").each do |fnode|
        footnote_number = fnode.attributes["id"].value
        if ["-1", "0"].include?(footnote_number)
          # Word outputs -1 and 0 as 'magic' footnotes
          next
        end
        output[footnote_number] = parse_content(fnode).strip
      end
      retu output
    end

    def expand_loop(nd, key, data)
      garbage = Array.new
      if !data.has_key?(key)
        end_row = nd
        until /#END_ROW:#{key.upcase.to_s}#/.match(end_row.text.to_s)
          garbage.append(end_row)
          end_row = end_row.next
        end
        return garbage + [end_row]
      elsif data[key].empty?
        end_row = nd
        until /#END_ROW:#{key.upcase.to_s}#/.match(end_row.text.to_s)
          garbage.append(end_row)
          end_row = end_row.next
        end
        return garbage + [end_row]
      else
        rows = Array.new
        start_row = nd
        end_row = nd.next
        until /#END_ROW:#{key.upcase.to_s}#/.match(end_row.text.to_s)
          rows.append(end_row)
          end_row = end_row.next
        end
        garbage = [start_row, end_row]
        data[key].each do |element|
          rows.each do |nd| 
            case nd.text.to_s
            when /#BEGIN_ROW:([A-Z0-9_]+)#/
              new_key = $1.downcase.to_sym
              garbage += expand_loop(nd, new_key, element)
            when /#END_ROW:([A-Z0-9_]+)#/
              garbage += [nd]
            else
              garbage += [nd]
              new_node = nd.dup
              nd.add_next_sibling(new_node)
              subst_content(new_node, element)
            end
          end
        end
        return garbage.uniq
      end
    end

    def parse_content(elements, data=@data)
      garbage = Array.new
      elements.each do |nd|
        case nd.name
        when "tr"
          case nd.text.to_s
          when /#BEGIN_ROW:([A-Z0-9_]+)#/
            key = $1.downcase.to_sym
            garbage += expand_loop(nd, key, data)
          else # it's a normal table row
            garbage += parse_content(nd.elements, data)
          end
        when "t" # It's a leaf that contains data to replace
          subst_content(nd, data) 
        else # it's neither a leaf or a loop so let's process it
          garbage += parse_content(nd.elements, data)
        end
      end
      return garbage.uniq
    end

    def subst_content(nd, data)
      inner = nd.inner_html
      @keys = nd.text.scan(/\$([A-Z0-9_]+)\$/).map(&:first).map(&:downcase).map(&:to_sym)
      @keys.each do |key|
        if data.has_key?(key)
          value = data[key]
          inner.gsub!("$#{key.to_s.upcase}$", safe(value))
        end
      end
      if !@keys.empty?
        nd.inner_html = inner
      end
    end

    def safe(text)
      text.to_s
    end
    
  end
end
