require 'spec_helper'

module ValueObjects
  describe HttpStatusCode do

    let(:code_200){HttpStatusCode.new(200)}
    let(:code_500){HttpStatusCode.new(500)}

    describe "#success?" do
      context "200" do
        it "returns true" do
          expect(code_200.success?).to eq true
        end  
      end
    end

    describe "#server_error?" do
      context "200" do
        it "returns false" do
          expect(code_200.server_error?).to eq false
        end  
      end
    end
  end
end