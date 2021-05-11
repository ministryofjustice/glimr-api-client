module GlimrApiClient
  class PayByAccount < Base
    class FeeLiabilityNotFound < StandardError; end

    class AccountNotFound < StandardError; end

    class InvalidAccountAndConfirmation < StandardError; end

    class InvalidAmount < StandardError; end

    class GlobalStatusInactive < StandardError; end

    class JurisdictionStatusInactive < StandardError; end

    class UnspecifiedError < StandardError; end

    attr_reader :request_body

    def initialize(params)
      @request_body = params
    end

    private

    def check_request!
      errors = []
      [
        :feeLiabilityId,
        :pbaAccountNumber,
        :pbaConfirmationCode,
        :pbaTransactionReference
      ].each do |required|
        errors << required if request_body.fetch(required, nil).nil?
      end

      if request_body.fetch(:pbaTransactionReference, '').size > 240
        errors << :pbaTransactionReferenceTooLong
      end
      raise RequestError, errors unless errors.empty?
    end

    def endpoint
      '/pbapaymentrequest'
    end

    def re_raise_error(body)
      error = body.fetch(:message, nil)
      case body.fetch(:glimrerrorcode, nil)
      when 511 # FeeLiability not found for FeeLiabilityID
        raise FeeLiabilityNotFound, error
      when 512 # PBA account \w+ not found
        raise AccountNotFound, error
      when 513 # Invalid PBAAccountNumber/PBAConfirmationCode combination
        raise InvalidAccountAndConfirmation, error
      when 514 # Invalid AmountToPay
        raise InvalidAmount, error
      when 521 # PBAGlobalStatus is inactive
        raise GlobalStatusInactive, error
      when 522 # PBAJurisdictionStatus is inactive
        raise JurisdictionStatusInactive, error
      end
      super(message: error)
    end
  end
end
