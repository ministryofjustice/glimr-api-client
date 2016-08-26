module GlimrApiClient
  class Update
    class RequestError < StandardError; end;
    include GlimrApiClient::Api

    def self.call(*args)
      new(*args).call
    end

    def initialize(fee)
      @fee = fee
    end

    def call
      check_request!
      post
      self
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
