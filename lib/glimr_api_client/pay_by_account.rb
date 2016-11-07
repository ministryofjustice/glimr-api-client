module GlimrApiClient
  class PayByAccount < Base
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

    # rubocop:disable Metrics/CyclomaticComplexity:
    def re_raise_error(_docpath, _error, body)
      body = {} unless body.instance_of?(Hash)
      case body.fetch(:glimrerrorcode, nil)
      when 511 #/FeeLiability not found for FeeLiabilityID/
        raise FeeLiabilityNotFound
      when 512 #/PBA account \w+ not found/
        raise PBAAccountNotFound
      when 513 #/Invalid PBAAccountNumber\/PBAConfirmationCode combination/
        raise InvalidPBAAccountAndConfirmation
      when 514 #/Invalid AmountToPay/
        raise PBAInvalidAmount
      when 521 #/PBAGlobalStatus is inactive/
        raise PBAGlobalStatusInactive
      when 522  #/PBAJurisdictionStatus is inactive/
        raise PBAJurisdictionStatusInactive
      else
        raise PBAUnspecifiedError
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity:
  end
end
