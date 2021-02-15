module LMDocstache
  class Condition
    InvalidOperator = Class.new(StandardError)

    ALLOWED_OPERATORS = %w(== ~=).freeze
    STARTING_QUOTES = %w(' " “)
    ENDING_QUOTES = %w(' " ”)

    attr_reader :left_term, :right_term, :operator, :negation, :original_match

    def initialize(left_term:, right_term:, operator:, negation: false, original_match: nil)
      @left_term = left_term
      @right_term = remove_quotes(right_term)
      @operator = operator
      @negation = negation
      @original_match = original_match

      unless ALLOWED_OPERATORS.include?(operator)
        raise InvalidOperator, "Operator '#{operator}' is invalid"
      end
    end

    def truthy?(value)
      result = value.to_s.send(operator, right_term)
      negation ? !result : result
    end

    private

    def remove_quotes(value)
      start_position = STARTING_QUOTES.include?(value[0]) ? 1 : 0
      end_position = ENDING_QUOTES.include?(value[-1]) ? -2 : -1

      value[start_position..end_position]
    end
  end
end
