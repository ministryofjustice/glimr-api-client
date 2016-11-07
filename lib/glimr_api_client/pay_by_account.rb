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
  end
end
