require 'spec_helper'

module ValueObjects
  describe Decision do

    let(:positive_decision){Decision.new("positive")}
    let(:negative_decision){Decision.new("negative")}
    let(:undecided_decision){Decision.new("undecided")}

    describe "#positive?" do
      context "positive decision" do
        it "returns true" do
          expect(positive_decision.positive?).to eq true
        end  
      end
    end

    describe "#negative?" do
      context "negative decision" do
        it "returns true" do
          expect(negative_decision.negative?).to eq true
        end  
      end
    end

    describe "#undecided?" do
      context "undecided decision" do
        it "returns true" do
          expect(undecided_decision.undecided?).to eq true
        end  
      end
    end

    describe "#decided?" do
      context "decided decision" do
        it "returns true" do
          expect(positive_decision.decided?).to eq true
        end  
      end
    end
  end
end