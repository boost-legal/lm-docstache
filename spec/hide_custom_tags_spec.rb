require 'spec_helper'

describe LMDocstache::HideCustomTags do

  context '#example' do
    let(:output_dir) { "#{base_path}/tmp/" }
    let(:output_file) { File.new("#{output_dir}/BlankTestOutput.docx", 'w') }
    before do
      FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
      Dir.mkdir(output_dir)
    end

    after do
      File.delete(output_file.path)
    end

    let(:base_path) { SPEC_BASE_PATH.join('example_input') }
    let(:input_file) { "#{base_path}/sample-signature.docx" }

    let(:document) { LMDocstache::Document.new(input_file).instance_variable_get(:@document) }
    let(:regexp_tag) { /{{(?:sig|sigfirm|date|check|text|initial)\|(?:req|noreq)\|.+?}}/ }
    let(:hide_custom_tags) {
      LMDocstache::HideCustomTags.new(document: document, hide_custom_tags: [ regexp_tag ])
    }
    it 'expect to have a white background on all hide custom tags matching' do
      hide_custom_tags.hide_custom_tags!
      d = hide_custom_tags.document
      run_nodes = d.css('w|p w|r')
      while run_node = run_nodes.shift
        if run_node.text =~ regexp_tag
          expect(run_node.at_css('w|rPr w|color').first[1]).to eq(LMDocstache::HideCustomTags::HIDE_BACKGROUND_COLOR)
        end
      end
    end
  end
end
