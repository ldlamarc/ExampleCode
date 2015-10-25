require 'date' #Not necessary in Rails

module ValueObjects

  class AcademicYear

    FIRST_MONTH_DAY = [9,1]
    LAST_MONTH_DAY = [6,30]

    attr_reader :beginning_year, :ending_year

    def initialize(beginning_year, ending_year)
      @beginning_year = Integer(beginning_year)
      @ending_year = Integer(ending_year)
      raise ArgumentError.new("Years in academic_year must be successive") if ending_year != beginning_year+1
    end

    def self.from_begin_year(beginning_year)
      new(beginning_year, beginning_year+1)
    end

    #Format of academic_year_string e.g. "2014/2015"
    def self.from_string(academic_year_string)
      beginning_year = academic_year_string.split("/")[0].to_i
      from_begin_year(beginning_year)
    end

    #Since you have summer months that can belong to a previous academic term you have two alternatives
    def self.from_date(date)
      minus_one = (date < first_day_in_year(date.year))
      year_to_academic_year(date.year, minus_one)
    end

    def self.from_date_alternative(date)
      minus_one = (date < last_day_in_year(date.year))
      year_to_academic_year(date.year, minus_one)
    end

    def self.current
      from_date(Date.today)
    end

    def +(years)
      AcademicYear.from_begin_year(beginning_year+years)
    end

    def -(years)
      AcademicYear.from_begin_year(beginning_year-years)
    end

    def ==(academic_year)
      self.beginning_year == academic_year.beginning_year
    end

    def first_day
      first_day_of_year(beginning_year)
    end

    def last_day
      last_day_of_year(ending_year)
    end

    def to_s
      "#{beginning_year}/#{ending_year}"
    end

    def inspect
      to_s
    end

    private

    def self.year_to_academic_year(year, minus_one)
      (minus_one) ? from_begin_year(year-1) : from_begin_year(year)
    end

    def self.first_day_in_year(year)
      Date.new(year, *FIRST_MONTH_DAY)
    end

    def self.last_day_in_year(year)
      Date.new(year, *LAST_MONTH_DAY)
    end

  end
end