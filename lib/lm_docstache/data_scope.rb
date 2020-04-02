module LMDocstache
  class DataScope

    def initialize(data, parent=EmptyDataScope.new)
      @data = data
      @parent = parent
    end

    def get(key, hash: @data, original_key: key, condition: nil)
      symbolize_keys!(hash)
      tokens = key.split('.')
      if tokens.length == 1
        result = hash.fetch(key.to_sym) { |_| @parent.get(original_key) }
        unless result.respond_to?(:select)
          return result if evaluate_condition(condition, result)
        else
          return result.select { |el| evaluate_condition(condition, el) }
        end
      elsif tokens.length > 1
        key = tokens.shift
        subhash = hash.fetch(key.to_sym) { |_| @parent.get(original_key) }
        return get(tokens.join('.'), hash: subhash, original_key: original_key)
      end
    end

    private

    def symbolize_keys!(hash)
      hash.transform_keys!{ |key| key.to_sym rescue key }
    end

    def evaluate_condition(condition, data)
      return true if condition.nil?
      condition = condition.match(/(==|~=)\s*(.+)/)
      operator = condition[1]
      expression = condition[2]
      case condition[1]
      when "=="
        # Equality condition
        expression = evaluate_expression(expression, data)
        return data == expression
      else
        # Matches condition
        expression = evaluate_expression(expression, data)
        right = Regex.new(expression.match(/\/(.+)\//)[1])
        binding.pry
        return data.match(right)
      end
    end

    def evaluate_expression(expression, data)
      if expression.match(/(["'“]?)(.+)(\k<1>|”)/)
        $2
      elsif data.respond_to?(:select)
        get(expression, hash: data)
      else
        false
      end
    end
  end

  class EmptyDataScope
    def get(_)
      return nil
    end
  end

end
