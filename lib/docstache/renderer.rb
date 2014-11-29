module Docstache
  class Renderer
    def initialize(xml, data)
      @content = xml
      @data = data
    end

    def render
      process_content
      return @content
    end

    private

    def process_content
      parse_content(@content.elements)

      content_tr = @content.xpath('//w:tr')

      cleanup_loop(content_tr)
    end

    def extract_end_row(nd, key)
      if !nd.nil?
        case nd.text.to_s
        when /\{\{\/#{key.to_s}\}\}/
          puts "Found End Row for #{key.to_s}"
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
      when /\{\{\##{key.to_s}\}\}/
        out = expand_loop(nd.next, end_nd, key, element)
      when end_nd.text.to_s
        out = []
      when /\{\{\#([a-zA-Z0-9_\.]+)\}\}/
        new_key = $1.to_sym
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
        when /\{\{\/#{key.upcase.to_s}\}\}/
          nd.unlink
        else
          remove_loop(nd.next, key)
          nd.unlink
        end
      end
    end


    def process_loop(nd, key, data)
      out = []
      puts "Found Loop #{key.to_s}"
      end_row = extract_end_row(nd, key)

      if !data.has_key?(key)
        nil # Error in the data model
        return []
      elsif data[key].empty?
        remove_loop(nd, key) # No data to put in
        return []
      else # Actual loop to process
        data_set = data[key]
        puts "Expanding Rows for loop #{key.to_s}"
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
          when /\{\{\#([a-zA-Z0-9_\.]+)\}\}/
            key = $1.to_sym
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
        when /\{\{\#([a-zA-Z0-9_\.]+)\}\}/
          nd.unlink
        when /\{\{\/([a-zA-Z0-9_\.]+)\}\}/
          nd.unlink
        when /\{\{[a-zA-Z0-9_\.]+\}\}/
          nd.unlink
        end
      end
    end

    def subst_content(nd, data)
      inner = nd.inner_html
      keys = nd.text.scan(/\{\{([a-zA-Z0-9_\.]+)\}\}/).map(&:first).map(&:to_sym)
      keys.each do |key|
        value = data[key]
        puts "Substituting {{#{key.to_s}}} with #{value}"
        inner.gsub!("{{#{key.to_s}}}", safe(value))
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
