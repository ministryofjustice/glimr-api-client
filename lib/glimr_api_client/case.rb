module GlimrApiClient
  class Case
    include GlimrApiClient::Api

    TRIBUNAL_JURISDICTION_ID = 8

    def self.find(case_reference, confirmation_code)
      new(case_reference, confirmation_code).call
    end

    # TODO: these should be required parameters
    def initialize(case_reference, confirmation_code)
      @case_reference = case_reference
      @confirmation_code = confirmation_code
    end

    def call
      post
      self
    end

    def title
      @title ||= response_body.fetch(:caseTitle)
    end

    def fees
      @fees ||= response_body.fetch(:feeLiabilities).map do |fee|
        OpenStruct.new(
          glimr_id: Integer(fee.fetch(:feeLiabilityId)),
          description: fee.fetch(:onlineFeeTypeDescription),
          amount: Integer(fee.fetch(:payableWithUnclearedInPence))
        )
      end
    end

    private

    def endpoint
      '/requestpayablecasefees'
    end

    def request_body
      {
        # jurisdictionId is in the spec for this method, but doesn't actually seem to be necessary.
        # Leaving it here, just in case a requirement is added in future
        jurisdictionId: TRIBUNAL_JURISDICTION_ID,
        caseNumber: @case_reference,
        confirmationCode: @confirmation_code
      }
    end
  end
end
