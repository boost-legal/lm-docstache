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
    let(:document) {
      doc = LMDocstache::Document.new(input_file)
      doc.fix_errors
      doc.instance_variable_get(:@document)
    }
    let(:regexp_tag) { /(?:sig|sigfirm|date|text|initial)\|(?:req|noreq)\|.+?/ }
    let(:regexp_for_replacement) { /(?:check)\|(?:req|noreq)\|.+?/ }
    let(:hide_custom_tags) {
      LMDocstache::HideCustomTags.new(document: document, hide_custom_tags: {
        /#{regexp_tag}/ => false,
        /#{regexp_for_replacement}/ => 'replaced_content'
      })
    }

    context "giving a document with blue background" do
      let(:input_file) { "#{base_path}/sample-signature-blue.docx" }

      it 'expect to have a white color on all hide custom tags matching and have first child node equal rPr tag' do
        hide_custom_tags.hide_custom_tags!
        d = hide_custom_tags.document
        run_nodes = d.css('w|p w|r')
        while run_node = run_nodes.shift
          next unless run_node.text =~ regexp_tag
          expect(run_node.at_css('w|rPr w|color').first[1]).to eq('4472C4')
          expect(run_node.children.first.name).to eq('rPr')
        end
      end
    end

    context 'giving a document with white background' do
      let(:input_file) { "#{base_path}/sample-signature.docx" }

      it 'expect to have a white color on all hide custom tags matching and have first child node equal rPr tag' do
        hide_custom_tags.hide_custom_tags!
        d = hide_custom_tags.document
        run_nodes = d.css('w|p w|r')
        while run_node = run_nodes.shift
          next unless run_node.text =~ regexp_tag
          expect(run_node.at_css('w|rPr w|color').first[1]).to eq('FFFFFF')
          expect(run_node.children.first.name).to eq('rPr')
        end
      end
    end
    context 'giving a document without rpr and block tags on the left' do
      let(:input_file) { "#{base_path}/docx-no-rpr.docx" }

      it 'expect to have a white color on all hide custom tags matching and have first child node equal rPr tag' do
        hide_custom_tags.hide_custom_tags!
        d = hide_custom_tags.document
        run_nodes = d.css('w|p w|r')
        while run_node = run_nodes.shift
          next unless run_node.text =~ regexp_tag
          expect(run_node.at_css('w|rPr w|color').first[1]).to eq('FFFFFF')
          expect(run_node.children.first.name).to eq('rPr')
        end
      end
      it 'expect to have a white color on all replacement tags and content following replacement' do
        hide_custom_tags.hide_custom_tags!
        d = hide_custom_tags.document
        run_nodes = d.css('w|p w|r')
        total_replacement = 0
        while run_node = run_nodes.shift
          next unless run_node.text =~ /replaced_content/
          total_replacement+=1
          expect(run_node.at_css('w|rPr w|color').first[1]).to eq('FFFFFF')
          expect(run_node.children.first.name).to eq('rPr')
        end
        expect(total_replacement).to eq(2)
      end
    end
  end
end
