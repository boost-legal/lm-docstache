module LMDocstache
  class ConditionalBlock
    attr_reader :element, :elements

    def initialize(element: nil, elements: [])
      @element = element
      @elements = elements
    end

    def inline?
      !@element.nil?
    end
  end
end
