require 'spec_helper'

describe LMDocstache::EmptyDataScope do
  let(:empty_data_scope) { LMDocstache::EmptyDataScope.new }
  describe '#get' do
    it "should always return nil" do
      expect(empty_data_scope.get('foo')).to be_nil
    end
  end
end
