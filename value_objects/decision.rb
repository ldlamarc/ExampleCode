module ValueObjects

  #A decision  can be both an entity or a value_object depending on how you model it. This example shows just a simple object with a state and nice getter methods.

  class Decision

    POSITIVE = "positive"
    NEGATIVE = "negative"
    UNDECIDED = "undecided"
    ALL = [POSITIVE, NEGATIVE, UNDECIDED]

    attr_reader :decision

    def initialize(decision)
      if ALL.include? decision
        @decision = decision
      else
        raise ArgumentError.new("Not a valid value for a decision")
      end
    end

    def positive?
      POSITIVE == decision
    end

    def negative?
      NEGATIVE == decision
    end

    def undecided?
      UNDECIDED == decision
    end    

    def decided?
      !undecided?
    end

    def ==(decision)
      self.decision == decision.decision
    end        

    def to_s
      decision
    end

    def inspect
      to_s
    end

  end
end