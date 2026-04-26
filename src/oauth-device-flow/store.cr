module OAuth::DeviceFlow
  abstract class Store
    abstract def load : Token?
    abstract def save(token : Token) : Nil
    abstract def clear : Nil
  end

  class MemoryStore < Store
    def initialize
      @token = nil.as(Token?)
    end

    def load : Token?
      @token
    end

    def save(token : Token) : Nil
      @token = token
    end

    def clear : Nil
      @token = nil
    end
  end
end
