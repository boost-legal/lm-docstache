module LMDocstache
  class DataScope

    def initialize(data, parent=EmptyDataScope.new)
      @data = data
      @parent = parent
    end

    def get(key, hash: @data, original_key: key, condition: nil)
      hash.symbolize_keys!
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

    def evaluate_condition(condition, data)
      condition = condition.match(/(.+?)\s*(==|~=)\s*(.+)/)
      case condition[2]
      when "=="
        # Equality condition
        left = evaluate_expression(condition[1], data)
        right = evaluate_expression(condition[3], data)
        return left == right
      else
        # Matches condition
        left = get(condition[1], hash: data)
        right = Regex.new(condition[3].match(/\/(.+)\//)[1])
        return left.match(right)
      end
    end

    def evaluate_expression(expression, data)
      if expression.match(/(["'“])(.+)(\k<1>|”)/)
        $2
      else
        get(expression, hash: data)
      end
    end
  end

  class EmptyDataScope
    def get(_)
      return nil
    end
  end

end
