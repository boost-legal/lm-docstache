require 'spec_helper'
require 'nokogiri'

module LMDocstache
  module TestData
    DATA = {
      gender: 'male'
    }
  end
end

describe LMDocstache::Renderer do
  let(:data) { Marshal.load(Marshal.dump(LMDocstache::TestData::DATA)) } # deep copy
  let(:base_path) { SPEC_BASE_PATH.join('example_input') }
  let(:short_input_file) { "#{base_path}/short_inline.docx" }
  let(:output_dir) { "#{base_path}/tmp" }
  let(:output_file) { "#{output_dir}/BlockTestOutput.docx" }
  let(:short_document) { LMDocstache::Document.new(short_input_file) }

  before do
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
    Dir.mkdir(output_dir)

    @short_doc = short_document.render_file(output_file, data)
    @result_doc = LMDocstache::Document.new(output_file).render_xml(data)
    @result_text = @result_doc["word/document.xml"].text
  end

  after do
    File.delete(output_file)
  end

  it 'should handle inline conditional tags' do
    expected_text = "Refer to the matter as him please"
    puts @result_text
    expect(@result_text).to eq(expected_text)
  end
end
