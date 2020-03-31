module Docstache
  class DataScope

    def initialize(data, parent=EmptyDataScope.new)
      @data = data
      @parent = parent
    end

    def get(key, hash: @data, original_key: key, condition: nil)
      hash.symbolize_keys!
      tokens = key.split('.')
      if tokens.length == 1
        if key.match(/(\w+)\[(\d+)\]/)
          result = hash.fetch($1.to_sym) { |key| @parent.get(original_key) }
          if result.respond_to?(:[])
            result = result[$2.to_i]
          end
        else
          result = hash.fetch(key.to_sym) { |key| @parent.get(original_key) }
        end
        if condition.nil? || !result.respond_to?(:select)
          return result
        else
          return result.select { |el| evaluate_condition(condition, el) }
        end
      elsif tokens.length > 1
        key = tokens.shift
        if key.match(/(\w+)\[(\d+)\]/)
          if hash.has_key?($1.to_sym)
            collection = hash.fetch($1.to_sym)
            if collection.respond_to?(:[])
              subhash = collection[$2.to_i]
            else
              subhash = collection
            end
          else
            return @parent.get(original_key)
          end
        else
          if hash.has_key?(key.to_sym)
            subhash = hash.fetch(key.to_sym)
          else
            return @parent.get(original_key)
          end
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
  end

  class EmptyDataScope
    def get(_)
      return nil
    end
  end

end
