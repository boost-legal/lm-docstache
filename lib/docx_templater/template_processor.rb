require 'nokogiri'

module DocxTemplater
  class TemplateProcessor
    attr_reader :data, :document, :escape_html

    # data is expected to be a hash of symbols => string or arrays of hashes.
    def initialize(data, document, escape_html = true)
      @data = data
      @xml = Nokogiri::XML(document)
      @escape_html = escape_html
    end

    def render
      document.force_encoding(Encoding::UTF_8) if document.respond_to?(:force_encoding)

      expanded_xml = expand_document(@xml, data)
      out_xml = replace_data(expanded_xml, data)

      return out_xml
    end

    private

    def expand_document()

      rows = @xml.xpath('//w:tr', @xml.root.namespaces)
      expanded = process_rows(rows)

      cells = @xml.xpath('//w:t', @xml.root.namespaces)
      out_xml = process_cells(cells)
      return @xml
    end

    def process_rows(rows)
      rows.each do |row|

        puts "Row Text: #{row.text}"
        # Process Row
        if !/BEGIN_ROW:/.match(row.text).nil?
          loop_start = row
          /#BEGIN_ROW:(?<key>[[:upper:]]+)#/ =~ row.text
          loop_end = @xml.xpath("//w:tr[contains(., '#END_ROW:#{key.to_s.upcase}#')]", @xml.root.namespaces).first

          loop_content = create_loop_list(loop_start,loop_end)
          process_loop(loop_content)
        elsif !/END_ROW/.match(row.text).nil?
          puts "skip and out of loop: #{row.text}"
          return row.next_sibling
        else
          @begin.add_next_sibling(replace_row(@row))
          puts "replace: #{row.text}"
          rows_for_key = replace_row(row, key)
        end
      end
    end

    def create_loop_list(loop_start, loop_end)
      out = []
      row = loop_start.next_sibling
      until row.next_sibling == loop_end
        out.append(row)
        row = row.next_sibling
      end
      return out
    end

    def process_loop(row)
    end

    def replace_row(row, loop_key)
      @out_rows = Array.new
      @elements = @data[key.downcase]
      innards = row.inner_html
      matches = innards.scan(/\$EACH:([^\$]+)\$/)
      unless matches.empty?
        @elements.each do |element|
          if element.keys.map(&:to_sym) == matches.map(&:first).map(&:downcase).map(&:to_sym)
            new_row = row.dup

            matches.map(&:first).each do |each_key|
              new_inner_html = new_row.inner_html.gsub!("$EACH:#{each_key}$", element[each_key.downcase.to_sym]))
              new_row.inner_html = new_inner_html
            end

            @out_rows.append(new_row)
          end
        end
      end

      new_row.inner_html = innards
      return new_row
    end

    def safe(text)
      if escape_html
        text.to_s.gsub('&', '&amp;').gsub('>', '&gt;').gsub('<', '&lt;')
      else
        text.to_s
      end
    end

    def parse_row(xml, key, values)
      # Manage Substitution of Rows
      begin_row = "#BEGIN_ROW:#{key.to_s.upcase}#"
      end_row = "#END_ROW:#{key.to_s.upcase}#"
      begin_row_template = xml.xpath("//w:tr[contains(., '#{begin_row}')]", xml.root.namespaces).first
      end_row_template = xml.xpath("//w:tr[contains(., '#{end_row}')]", xml.root.namespaces).first
      DocxTemplater.log("begin_row_template: #{begin_row_template}")
      DocxTemplater.log("end_row_template: #{end_row_template}")
      fail "unmatched template markers: #{begin_row} nil: #{begin_row_template.nil?}, #{end_row} nil: #{end_row_template.nil?}. This could be because word broke up tags with it's own xml entries. See README." unless begin_row_template && end_row_template
    end

    def subst_row(xml, values)
      DocxTemplater.log("enter_multiple_values for: #{key}")
      # TODO: ideally we would not re-parse xml doc every time

      begin_row = "#BEGIN_ROW:#{key.to_s.upcase}#"
      end_row = "#END_ROW:#{key.to_s.upcase}#"
      begin_row_template = xml.xpath("//w:tr[contains(., '#{begin_row}')]", xml.root.namespaces).first
      end_row_template = xml.xpath("//w:tr[contains(., '#{end_row}')]", xml.root.namespaces).first
      DocxTemplater.log("begin_row_template: #{begin_row_template}")
      DocxTemplater.log("end_row_template: #{end_row_template}")
      fail "unmatched template markers: #{begin_row} nil: #{begin_row_template.nil?}, #{end_row} nil: #{end_row_template.nil?}. This could be because word broke up tags with it's own xml entries. See README." unless begin_row_template && end_row_template

      row_templates = []
      row = begin_row_template.next_sibling
      while row != end_row_template
        row_templates.unshift(row)
        row = row.next_sibling
      end
      DocxTemplater.log("row_templates: (#{row_templates.count}) #{row_templates.map(&:to_s).inspect}")

      # for each data, reversed so they come out in the right order
      data[key].reverse.each do |each_data|
        DocxTemplater.log("each_data: #{each_data.inspect}")

        # dup so we have new nodes to append
        row_templates.map(&:dup).each do |new_row|
          DocxTemplater.log("   new_row: #{new_row}")
          innards = new_row.inner_html
          matches = innards.scan(/\$EACH:([^\$]+)\$/)
          unless matches.empty?
            DocxTemplater.log("   matches: #{matches.inspect}")
            matches.map(&:first).each do |each_key|
              DocxTemplater.log("      each_key: #{each_key}")
              innards.gsub!("$EACH:#{each_key}$", safe(each_data[each_key.downcase.to_sym]))
            end
          end
          # change all the internals of the new node, even if we did not template
          new_row.inner_html = innards
          # DocxTemplater::log("new_row new innards: #{new_row.inner_html}")

          begin_row_template.add_next_sibling(new_row)
        end
      end
      (row_templates + [begin_row_template, end_row_template]).map(&:unlink)
      xml.to_s
    end
  end
end
