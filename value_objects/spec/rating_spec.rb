require 'spec_helper'

module ValueObjects
  describe Rating do

    let(:rating_a){Rating.new("A")}
    let(:rating_f){Rating.new("F")}

    describe "#from_cost" do
      context "cost: 1" do
        it "returns A" do
          expect(Rating.from_cost(1)).to eq rating_a
        end  
      end

      context "cost: 17" do
        it "returns F" do
          expect(Rating.from_cost(17)).to eq rating_f
        end  
      end
    end
  end
end