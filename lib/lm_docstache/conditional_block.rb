module LMDocstache
  class ConditionalBlock
    attr_reader :elements, :tag_names

    def initialize(elements:, tag_names:)
      @elements = elements
      @tag_names = tag_names
    end

    def inline?
      @elements.size == 1
    end
  end
end
