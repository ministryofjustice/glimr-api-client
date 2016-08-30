module GlimrApiClient
  class Case
    include GlimrApiClient::Api

    def self.find(case_reference = nil)
      new(case_reference).call
    end

    def initialize(case_reference = nil)
      @case_reference = case_reference
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
          glimrId: Integer(fee.fetch(:feeLiabilityId)),
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
        jurisdictionId: 8, # TODO: Remove when no longer required in API
        caseNumber: @case_reference
      }
    end
  end
end
