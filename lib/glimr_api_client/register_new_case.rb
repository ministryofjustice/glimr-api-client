module GlimrApiClient
  class RegisterNewCase < Base
    attr_reader :request_body

    def initialize(params)
      @request_body = params
    end

    private

    def check_request!
      errors = []
      [
        :jurisdictionId,
        :onlineMappingCode
      ].each do |required|
        errors << required if request_body.fetch(required, nil).nil?
      end
      raise RequestError, errors unless errors.empty?
    end

    def endpoint
      '/registernewcase'
    end
  end
end
