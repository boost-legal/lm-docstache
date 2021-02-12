module LMDocstache
  class Condition
    attr_reader :left_term, :right_term, :operator, :negation, :original_match

    def initialize(left_term:, right_term:, operator:, negation: false, original_match: nil)
      @left_term = left_term
      @right_term = right_term
      @operator = operator
      @negation = negation
      @original_match = original_match
    end
  end
end
