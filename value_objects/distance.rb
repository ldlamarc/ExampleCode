module ValueObjects

  class Distance

    include Comparable

    MILE_IN_METERS = 1609.344

    attr_reader :meters

    def initialize(meters)
      @meters = Float(meters)
    end

    def self.from_miles(miles)
      new(MILE_IN_METERS/Float(miles))
    end

    def order_of_magnitude
      Math.log10(meters).floor
    end

    #Makes the object Comparable if you include the Comparable module
    def <=>(distance)
      meters <=> distance.meters
    end

    def ==(distance)
      self.meters == distance.meters
    end        

    def to_s
      "#{meters} m"
    end

    def inspect
      to_s
    end

  end
end