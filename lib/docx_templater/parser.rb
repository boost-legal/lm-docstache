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

module DocxConverter
  class Parser
    def initialize(options)
      @output_dir = options[:output_dir]
      @docx_filepath = options[:inputfile]
      
      @image_subdir_filesystem = options[:image_subdir_filesystem]
      @image_subdir_kramdown = options[:image_subdir_kramdown]
      
      @relationships_hash = {}
      
      @zipfile = Zip::ZipFile.new(@docx_filepath)
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
      return output
    end

    def manage_loop(nd, key, depth, data)
      output = Array.new

      if !/#END_ROW:#{key.to_s.upcase}#/.match(nd.text.to_s)
        case nd.text.to_s
        when /#BEGIN_ROW:(.+)#/
          puts "######### NEW LOOP ##########"
          key = $1.downcase.to_sym
          puts "Key is : #{key}\nData is : #{data}"

          if data.has_key?(key)
            data[key].each do |element|
              new_data = data.dup
              new_data = data.merge(element)
              new_data.delete(key)
              puts "New #{key} is : #{new_data}"
              @loop_rows = manage_loop(nd.next_sibling, key, depth, new_data)
              output.append(@loop_rows)
            end
          end
          return output
        else
          add = parse_content(nd, depth+1, data)
          output.append(add)
          nd = nd.next_sibling
        end
      else
        return output
      end
    end

    def parse_content(node, depth=0, data=@data)
      output = []
      depth += 1
      children_count = node.children.length
      i = 0
      while i < children_count
        nd = node.children[i]
        case nd.name
        when "tr"
          case nd.text.to_s
          when /#BEGIN_ROW:(.+)#/
            key = $1.downcase.to_sym
            add = manage_loop(nd, key, depth, data)
          else
            add = parse_content(nd, depth, data)
          end
        when "t"
          add = subst_content(nd, data)
        else
          # recurse through those nodes as well
          add = parse_content(nd, depth, data)
        end
        output.append(add)
        i += 1
      end
      depth -= 1
      return output
    end

    def subst_content(nd,data)
      /\$(.+)\$/ =~ nd.text
      if !$1.nil?
        subst_key = $1.downcase.to_sym
        if data.has_key?(subst_key)
          inner = nd.inner_html
          value = data[subst_key]
          inner.gsub!("$#{subst_key.to_s.upcase}$", safe(value))
          nd.inner_html = inner
        end
      end
      return nd
    end

    def safe(text)
      text.to_s
    end
    
  end
end
