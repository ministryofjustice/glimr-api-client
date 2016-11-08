module GlimrApiClient
  class Update < Base
    def initialize(fee)
      @fee = fee
    end

    private

    def check_request!
      errors = []
      [:feeLiabilityId, :paymentReference, :govpayReference, :paidAmountInPence].each do |required|
        errors << required if request_body.fetch(required).nil?
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
        raise PaymentReferenceFormatInvalid, error
      when 314 # Invalid format for GovPayReference
        raise GovPayReferenceFormatInvalid, error
      when 315 # Invalid PaidAmount
        raise AmountInvalid, error
      when 321 # GovPay reference already exists on system
        raise GovPayReferenceExistsOnSystem, error
      end
      super(message: error)
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
