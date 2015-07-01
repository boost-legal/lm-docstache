module Docstache
  class DataScope

    def initialize(data, parent=EmptyDataScope.new)
      @data = data
      @parent = parent
    end

    def get(key, hash=@data, original_key=key)
      symbolize_keys!(hash)
      tokens = key.split('.')
      if tokens.length == 1
        return hash.fetch(key.to_sym) { |key| @parent.get(original_key) }
      elsif tokens.length > 1
        key = tokens.shift
        if hash.has_key?(key.to_sym)
          subhash = hash.fetch(key.to_sym)
        else
          return @parent.get(original_key)
        end
        return get(tokens.join('.'), subhash, original_key)
      end
    end

    private

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
