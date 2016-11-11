module GlimrApiClient
  # TODO: rename so it follow api spec
  class Update < Base
    class FeeLiabilityNotFound < StandardError; end
    class PaymentReferenceInvalidFormat < StandardError; end
    class GovPayReferenceInvalidFormat < StandardError; end
    class InvalidAmount < StandardError; end
    class GovPayReferenceExistsOnSystem < StandardError; end

    # TODO: Move this and initialize into Base. It's the same for all but Case.
    attr_reader :request_body

    def initialize(params)
      @request_body = params
    end

    private

    # TODO: Set the attributes in a constant and move this to Base.
    def check_request!
      errors = []
      [
        :feeLiabilityId,
        :paymentReference,
        :govpayReference,
        :paidAmountInPence
      ].each do |required|
        errors << required if request_body.fetch(required, nil).nil?
      end
      raise RequestError, errors unless errors.empty?
    end

    def endpoint
      '/paymenttaken'
    end

    def re_raise_error(body)
      error = body.fetch(:message, nil)
      case body.fetch(:glimrerrorcode, nil)
      when 311 # FeeLiability not found
        raise FeeLiabilityNotFound, error
      when 312 # Invalid format for PaymentReference
        raise PaymentReferenceInvalidFormat, error
      when 314 # Invalid format for GovPayReference
        raise GovPayReferenceInvalidFormat, error
      when 315 # Invalid PaidAmount
        raise InvalidAmount, error
      when 321 # GovPay reference already exists on system
        raise GovPayReferenceExistsOnSystem, error
      end
      super(message: error)
    end
  end
end
