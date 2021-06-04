require 'spec_helper'
require 'active_support/core_ext/object/blank.rb'

module LMDocstache
  module TestData
    DATA = {
      teacher: 'Johhny Bissel',
      building: 'Building #14',
      classroom: 'Rm 202'.to_sym,
      district: 'San Deigo Unified School District',
      seniority: 12.25,
      roster: [
        { name: 'Sally', age: 12, attendance: '100%' },
        { name: :Xiao, age: 10, attendance: '94%' },
        { name: 'Bryan', age: 13, attendance: '100%' },
        { name: 'Larry', age: 11, attendance: '90%' },
        { name: 'Kumar', age: 12, attendance: '76%' },
        { name: 'Amber', age: 11, attendance: '100%' },
        { name: 'Isaiah', age: 12, attendance: '89%' },
        { name: 'Omar', age: 12, attendance: '99%' },
        { name: 'Xi', age: 11, attendance: '20%' },
        { name: 'Noushin', age: 12, attendance: '100%' }
      ],
      event_reports: [
        { name: 'Science Museum Field Trip', notes: 'PTA sponsored event. Spoke to Astronaut with HAM radio.' },
        { name: 'Wilderness Center Retreat', notes: '2 days hiking for charity:water fundraiser, $10,200 raised.' }
      ],
      created_at: '11-12-20 02:01',
      true_cond: true,
        false_cond: false
    }
  end
end

describe 'integration test', integration: true do
  let(:base_path) { SPEC_BASE_PATH.join('example_input') }
  let(:output_dir) { "#{base_path}/tmp" }

  context 'should process that incoming docx' do
    let(:data) { LMDocstache::TestData::DATA }
    let(:input_file) { "#{base_path}/ExampleTemplate.docx" }
    let(:output_file) { "#{output_dir}/IntegrationTestOutput.docx" }
    let(:document) { LMDocstache::Document.new(input_file) }

    before do
      FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
      Dir.mkdir(output_dir)
    end

    it 'loads the input file' do
      expect(document).to_not be_nil
    end

    it 'generates output file with the same contents as the input file' do
      input_entries = Zip::File.open(input_file) { |z| z.map(&:name) }
      document.save(output_file)
      output_entries = Zip::File.open(output_file) { |z| z.map(&:name) }

      expect(input_entries - output_entries).to be_empty
    end

    it 'fixes nested xml errors breaking tags' do
      expect { document.fix_errors }.to change {
        document.send(:problem_paragraphs).size
      }.from(6).to(1)

      expect(document.send(:problem_paragraphs).first.text).to eq(
        '{{TAG123-\\-//WITH WE👻IRD CHARS}}'
      )
    end

    it 'has the expected amount of usable tags' do
      expect(document.usable_tags.count).to eq(21)
    end

    it 'has the expected amount of usable roles tags' do
      document.fix_errors
      expect(document.usable_role_tags.count).to eq(6)
    end

    it 'has the expected amount of unique tag names' do
      expect(document.usable_tag_names.count).to eq(13)
    end

    it 'renders file using data' do
      document.render_file(output_file, data)
    end
  end
  context "testing hide custom tags" do
    before do
      FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
      Dir.mkdir(output_dir)
    end

    let(:render_options) {
      {
        hide_custom_tags: ['(?:sig|sigfirm|date|check|text|initial)\|(?:req|noreq)\|.+?']
      }
    }
    let(:document) { LMDocstache::Document.new(input_file) }

    context "witth document with blue background" do
      let(:input_file) { "#{base_path}/sample-signature-blue.docx" }

      it 'should have content replacement aligned with hide custom tags' do
        doc = document
        doc.fix_errors
        noko = doc.render_xml({}, render_options)
        output = noko['word/document.xml'].to_xml
        expect(output).to include('<w:r>
        <w:rPr>
          <w:rFonts w:cstheme="minorHAnsi"/>
          <w:lang w:val="en-US"/>
          <w:color w:val="4472C4"/>
        </w:rPr>
        <w:t xml:space="preserve">{{sig|req|client}}</w:t>
      </w:r>')
        expect(output).to include('<w:t xml:space="preserve">Test Multiple text in the same line </w:t>')
      end
    end

    context "with document without backgorund" do
      let(:input_file) { "#{base_path}/sample-signature.docx" }
      let(:document) { LMDocstache::Document.new(input_file) }

      it 'should have content replacement aligned with hide custom tags' do
        doc = document
        doc.fix_errors
        noko = doc.render_xml({}, render_options)
        output = noko['word/document.xml'].to_xml
        expect(output).to include('<w:r>
        <w:rPr>
          <w:rFonts w:cstheme="minorHAnsi"/>
          <w:lang w:val="en-US"/>
          <w:color w:val="FFFFFF"/>
        </w:rPr>
        <w:t xml:space="preserve">{{sig|req|client}}</w:t>
      </w:r>')
        expect(output).to include('<w:t xml:space="preserve">Test Multiple text in the same line </w:t>')
      end
    end
  end
end
