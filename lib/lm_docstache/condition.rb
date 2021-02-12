module LMDocstache
  class Condition
    InvalidOperator = Class.new(StandardError)

    ALLOWED_OPERATORS = %w(== ~=).freeze

    attr_reader :left_term, :right_term, :operator, :negation, :original_match

    def initialize(left_term:, right_term:, operator:, negation: false, original_match: nil)
      @left_term = left_term
      @right_term = right_term
      @operator = operator
      @negation = negation
      @original_match = original_match

      unless ALLOWED_OPERATORS.include?(operator)
        raise InvalidOperator, "Operator '#{operator}' is invalid"
      end
    end

    def evaluate(value)
      result = value.to_s.send(operator, right_term)
      negation ? !result : result
    end
  end
end
