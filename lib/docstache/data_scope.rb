module Docstache
  class DataScope

    def initialize(data, parent=EmptyDataScope.new)
      @data = data
      @parent = parent
    end

    def get(key, hash: @data, original_key: key, condition: nil)
      symbolize_keys!(hash)
      tokens = key.split('.')
      if tokens.length == 1
        result = hash.fetch(key.to_sym) { |key| @parent.get(original_key) }
        if condition.nil? || !result.respond_to?(:select)
          return result
        else
          return result.select { |el| evaluate_condition(condition, el) }
        end
      elsif tokens.length > 1
        key = tokens.shift
        if hash.has_key?(key.to_sym)
          subhash = hash.fetch(key.to_sym)
        else
          return @parent.get(original_key)
        end
        return get(tokens.join('.'), hash: subhash, original_key: original_key)
      end
    end

    private

    def evaluate_condition(condition, data)
      condition = condition.match(/(.+?)\s*(==|~=)\s*(.+)/)
      if condition[2] == "=="
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

    def symbolize_keys!(hash)
      hash.keys.each do |key|
        hash[(key.to_sym rescue key)] = hash.delete(key)
      end
    end

  end

  class EmptyDataScope
    def get(_)
      return nil
    end
  end

end
