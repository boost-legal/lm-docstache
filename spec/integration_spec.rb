require 'spec_helper'

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
  let(:data) { LMDocstache::TestData::DATA }
  let(:base_path) { SPEC_BASE_PATH.join('example_input') }
  let(:input_file) { "#{base_path}/ExampleTemplate.docx" }
  let(:output_dir) { "#{base_path}/tmp" }
  let(:output_file) { "#{output_dir}/IntegrationTestOutput.docx" }
  let(:document) { LMDocstache::Document.new(input_file) }
  before do
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
    Dir.mkdir(output_dir)
  end

  context 'should process in incoming docx' do
    it 'Loads the input file' do
      expect(document).to_not be_nil
    end

    it 'Generates output file with the same contents as the input file' do
      input_entries = Zip::File.open(input_file) { |z| z.map(&:name) }
      document.save(output_file)
      output_entries = Zip::File.open(output_file) { |z| z.map(&:name) }

      expect(input_entries - output_entries).to be_empty
    end
  end
end
