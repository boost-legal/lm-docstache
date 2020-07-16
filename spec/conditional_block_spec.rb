require 'spec_helper'
require 'nokogiri'

module LMDocstache
  module TestData
    DATA = {
      gender: 'Male',
      first_name: 'Hector',
      last_name: 'Jones'
    }
  end
end

describe LMDocstache::Renderer do
  let(:data) { Marshal.load(Marshal.dump(LMDocstache::TestData::DATA)) } # deep copy
  let(:base_path) { SPEC_BASE_PATH.join('example_input') }
  let(:blank_doc_path) { "#{base_path}/blank.docx" }
  let(:blank_doc) { LMDocstache::Document.new(blank_doc_path) }
  let(:output_dir) { "#{base_path}/tmp" }
  let(:temp_file) { "#{output_dir}/temp.docx" }
  let(:result_file) { "#{output_dir}/result.docx" }

  def render_docx(doc_text)
    # create doc from blank
    blank_doc.render_replace(temp_file, doc_text)

    doc = LMDocstache::Document.new(temp_file).render_file(result_file, data)

    result_doc = LMDocstache::Document.new(result_file).render_xml(data)
    result_doc["word/document.xml"].text
  end

  before do
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
    Dir.mkdir(output_dir)
  end

  after do
    File.delete(temp_file)
    File.delete(result_file)
  end

  it 'should handle inline conditional tags' do
    result_text = render_docx("Refer to the matter as {{#gender == Male}}he{{/gender}}{{^gender == Male}}she{{/gender}} please")
    expected_text = "Refer to the matter as he please"
    expect(result_text).to eq(expected_text)
  end

  it 'should handle else statements with inline conditional tags' do
    result_text = render_docx("Refer to the matter as {{#gender == 'Female'}}he{{/gender}}{{^gender == 'Female'}}she{{/gender}} please")
    expected_text = "Refer to the matter as she please"
    expect(result_text).to eq(expected_text)
  end

  it 'should handle inline conditional tags with no matches' do
    result_text = render_docx("Refer to the matter as {{#gender == 'none'}}he{{/gender}} please")
    expected_text = "Refer to the matter as  please"
    expect(result_text).to eq(expected_text)
  end

  it 'should handle inline conditional tags with tags inside' do
    result_text = render_docx("Refer to the matter as {{#gender == 'Male'}}{{first_name}}{{/gender}}{{^gender == 'Male'}}{{last_name}}{{/gender}} please")
    expected_text = "Refer to the matter as Hector please"
    expect(result_text).to eq(expected_text)
  end

  it 'should handle multiple positive checks in one line' do
    result_text = render_docx("Refer to the matter as {{#gender == 'Male'}}him{{/gender}}{{#gender == 'Female'}}her{{/gender}} please")
    expected_text = "Refer to the matter as him please"
    expect(result_text).to eq(expected_text)
  end

  it 'should handle multiline conditional tags' do
    text = [
      "Refer to the matter as",
      "{{#gender == 'Male'}}",
      "{{first_name}}",
      "{{/gender}}",
      "{{^gender == 'Male'}}",
      "{{last_name}}",
      "{{/gender}}Thank you"
    ].join("\r\n")

    result_text = render_docx(text)
    expected_text = "Refer to the matter as\r\rHector\r\rThank you"
    expect(result_text).to eq(expected_text)
  end
end
