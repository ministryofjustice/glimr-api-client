module GlimrApiClient
  class RegisterNewCase < Base
    def initialize(params)
      @params = params
    end

    private

    def check_request!
      errors = []
      [
        :jurisdictionId,
        :onlineMappingCode
      ].each do |required|
        errors << required if request_body.key?(required).blank?
      end
      raise RequestError, errors unless errors.blank?
    end

    def endpoint
      '/registernewcase'
    end

    def request_body
      @params
    end
  end
end
