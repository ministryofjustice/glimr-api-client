module GlimrApiClient
  class Update < Base
    def initialize(fee)
      @fee = fee
    end

    private

    def check_request!
      errors = []
      [:feeLiabilityId, :paymentReference, :govpayReference, :paidAmountInPence].each do |required|
        errors << required if request_body.fetch(required).blank?
      end
      raise RequestError, errors unless errors.blank?
    end

    def endpoint
      '/paymenttaken'
    end

    def request_body
      {
        feeLiabilityId: @fee.glimr_id,
        paymentReference: @fee.govpay_reference,
        govpayReference: @fee.govpay_payment_id,
        paidAmountInPence: @fee.amount
      }
    end
  end
end
