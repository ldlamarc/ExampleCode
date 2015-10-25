require 'spec_helper'

module ValueObjects
  describe Distance do

    let(:distance){Distance.new(1500)}
    let(:smaller_distance){Distance.new(500)}
    let(:mile){Distance.from_miles(1)}
    let(:mile_in_meters){Distance.new(1609.344)}

    describe "#order_of_magnitude" do
      context "1500 m" do
        it "returns 3" do
          expect(distance.order_of_magnitude).to eq 3
        end  
      end

      context "500 m" do
        it "returns 2" do
          expect(smaller_distance.order_of_magnitude).to eq 2
        end  
      end
    end

    describe "#from_miles" do
      context "1 mile" do
        it "returns 1609 m" do
          expect(mile).to eq mile_in_meters
        end  
      end
    end

    describe "#>" do
      context "distance > smaller_distance" do
        it "returns true" do
          expect(distance > smaller_distance).to eq true
        end  
      end
    end
  end
end