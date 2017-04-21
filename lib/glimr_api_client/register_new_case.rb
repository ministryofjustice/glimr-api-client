module GlimrApiClient
  class RegisterNewCase < Base
    class JurisdictionNotFound < StandardError; end
    class OnlineMappingNotFoundOrInvalid < StandardError; end
    class CaseCreationFailed < StandardError; end

    TRIBUNAL_JURISDICTION_ID = 8

    attr_reader :request_body

    def initialize(params)
      @request_body = params
    end

    # This addresses the problem that RegisterNewCase calls can take a much
    # longer time to respond than availability calls. At the time this was
    # written, the connection was periodically timing out at just over 30
    # seconds.
    def timeout
      Integer(ENV.fetch('GLIMR_REGISTER_NEW_CASE_TIMEOUT_SECONDS', 32))
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

    def re_raise_error(body)
      error = body.fetch(:message, nil)
      case body.fetch(:glimrerrorcode, nil)
      when 411 # Jusidiction not found
        raise JurisdictionNotFound, error
      when 412 # Online Mapping not found or invalid
        raise OnlineMappingNotFoundOrInvalid, error
      when 421 # Creation failed (due to a database problem)
        raise CaseCreationFailed, error
      end
      super(message: error)
    end
  end
end
