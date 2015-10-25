module ValueObjects

  class HttpStatusCode

    SUCCESS_RANGE = [200, 299]
    REDIRECTION_RANGE = [300, 399]
    CLIENT_ERROR_RANGE = [400, 499]
    SERVER_ERROR_RANGE = [500, 599]
    ALL_RANGE = [200, 599]

    attr_reader :code

    def initialize(code)
      if Integer(code).between?(*ALL_RANGE)
        @code = code
      else
        raise ArgumentError.new("Unknown HTTP Status Code")
      end
    end

    def success?
      between?(SUCCESS_RANGE)
    end

    def redirection?
      between?(REDIRECTION_RANGE)
    end

    def client_error?
      between?(CLIENT_ERROR_RANGE)
    end

    def server_error?
      between?(SERVER_ERROR_RANGE)
    end

    def ==(http_status_code)
      self.code == http_status_code.code
    end        

    def to_s
      "#{http_status_code}"
    end

    def inspect
      to_s
    end

    private

    def between?(range)
      code.between?(*range)
    end

  end
end