require 'spec_helper'

module ValueObjects
  describe AcademicYear do
    let(:summer_day_of_academic_year){Date.new(2015, 7, 30)}
    let(:day_of_academic_year){Date.new(2015, 5, 30)}
    let(:academic_year_2014){AcademicYear.from_string("2014/2015")}
    let(:academic_year_2015){AcademicYear.from_string("2015/2016")}


    describe "#beginning_year" do
      context "2014/2015" do
        it "returns 2014" do
          expect(academic_year_2014.beginning_year).to eq 2014
        end
      end     
    end

    describe "#ending_year" do
      context "2015/2016" do
        it "returns 2016" do
          expect(academic_year_2015.ending_year).to eq 2016
        end
      end     
    end

    describe "#+" do
      context "academic year in 5 years starting from 2014/2015" do
        it "returns 2019/2020" do
          expect((academic_year_2014+5).to_s).to eq "2019/2020"
        end
      end     
    end

    describe "#-" do
      context "previous academic year of 2014/2015" do
        it "returns 2013/2014" do
          expect((academic_year_2014-1).to_s).to eq "2013/2014"
        end
      end     
    end

    describe "#from_date" do
      context "30th of July, 2015" do
        it "falls in '2014/2015'" do
          expect(AcademicYear.from_date(summer_day_of_academic_year)).to eq academic_year_2014
        end
      end     
    end

    describe "#from_date_alternative" do
      context "30th of July, 2015" do
        it "falls in '2015/2016'" do
          expect(AcademicYear.from_date_alternative(summer_day_of_academic_year)).to eq academic_year_2015
        end
      end     
    end      
  end
end