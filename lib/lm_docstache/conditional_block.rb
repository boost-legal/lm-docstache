module LMDocstache
  class ConditionalBlock
    attr_reader :elements, :condition

    def initialize(elements:, condition:)
      @elements = elements
      @condition = condition
    end

    def inline?
      @elements.size == 1
    end
  end
end
