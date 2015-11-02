#This code serves strictly as example code on how to integrate value_objects in typical Rails code and the pros and cons
#It has not been tested or used as is in a real world application

class ApiCall < ActiveRecord::Base
  belongs_to :person
  has_many :input_errors

  #With ValueObjects
    def http_response_code
      @code ||= ValueObjects::HttpStatusCode.new(read_attribute(:code))
      #Advantages
        #Can serve as a good building block for a other Objects (e.g. a generic StatusPresenter[1] which translates success? to a green/red light in a View)
      #Disadvantages:
        #You need an extra method to couple the value_object, an extra class, spec, file and probably folder.
    end

    def success?
      http_response_code.success? || input_errors.empty?
    end

  #Without ValueObjects
    def success?
      http_response_success? || input_errors.empty? 
      #Disadvantages:
        #Stubbing http_response_success? in a unit test is with a boolean is very method and implementation specific, stubbing http_response_code with a HttpStatusCode.new(200) seems to be a better option
    end

    def http_response_success?
      code.between?(200,299)
      #Disadvantages:
        #This includes HTTP protocol constants which do not belong in your api_call Model
          #Knowledge is required about non-api_call constants by every developer who will change/expand/refactor api_call methods
          #The code is closely coupled to those constants. If the constants change this code will have to change
        #This code is not reusable across models (workaround could be to include it in a Module)
        #Your model needs an extra method per http code (Fat Model):
          #Increased risk of method name conflicts
          #Increased risk of developpers using other formats/names for similar methods (e.g. http_client_error? instead of http_response_client_error?)
          #Increased risk of developpers not knowing the existence of a method (hidden in a module or because the model code is too long to read)
          #Extra test per method
          #Extra time lost in reading/finding/comprehending a method
        #The method is very closely coupled to your database (if the field "code" is renamed or changed to a string you would need to change this method)
    end

  #[1] http://railscasts.com/episodes/287-presenters-from-scratch
end
