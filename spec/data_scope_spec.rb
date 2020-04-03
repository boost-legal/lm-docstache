require 'spec_helper'

describe LMDocstache::DataScope do
  describe "#get" do
    context "main body" do
      let(:data_scope) {
        LMDocstache::DataScope.new({foo: "bar1", bar: {baz: "bar2", qux: {quux: "bar3"}}})
      }
      it "should resolve keys with no nesting" do
        expect(data_scope.get('foo')).to eq("bar1")
      end

      it "should resolve nested keys" do
        expect(data_scope.get('bar.baz')).to eq("bar2")
      end

      it "should resolve super nested keys" do
        expect(data_scope.get('bar.qux.quux')).to eq("bar3")
      end
    end

    context "loop" do
      let(:parent_data_scope) {
        LMDocstache::DataScope.new({
          users: [ {
            id: 1, name: "John Smith", brother: {id: 3, name: "Will Smith"}
          }], id: 2, foo: "bar", brother: {baz: "qux"}}) }

      let(:data_scope) {
        LMDocstache::DataScope.new({
          id: 1, name: "John Smith", brother: {id: 3, name: "Will Smith"}}, parent_data_scope)
      }

      it "should resolve keys with no nesting" do
        expect(data_scope.get("id")).to eq(1)
      end

      it "should resolve nested keys" do
        expect(data_scope.get("brother.id")).to eq(3)
      end

      it "should fall back to parent scope if key not found" do
        expect(data_scope.get("foo")).to eq("bar")
      end

      it "should fall back to parent even during a partial match" do
        expect(data_scope.get("brother.baz")).to eq("qux")
      end

      it "should return nil for no match" do
        expect(data_scope.get("bat")).to be_nil
        expect(data_scope.get("brother.qux")).to be_nil
      end
    end
  end
end
