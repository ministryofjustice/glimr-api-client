module GlimrApiClient
  class HwfRequested < Base
    class FeeLiabilityNotFound < StandardError; end;
    class InvalidAmount < StandardError; end

    attr_reader :request_body

    def initialize(params)
      @request_body = params
    end

    private

    def check_request!
      errors = []
      [
        :feeLiabilityId,
        :hwfRequestReference
      ].each do |required|
        errors << required if request_body.fetch(required, nil).nil?
      end
      raise RequestError, errors unless errors.empty?
    end

    def endpoint
      '/hwfrequested'
    end

    def re_raise_error(body)
      error = body.fetch(:message, nil)
      case body.fetch(:glimrerrorcode, nil)
      when 611 # FeeLiability not found for FeeLiabilityID
        raise FeeLiabilityNotFound, error
      when 612 # Invalid AmountToPay
        raise InvalidAmount, error
      end
      super(message: error)
    end
  end
end
