module GlimrApiClient
  # TODO: rename so it follow api spec
  class Case
    class NotFound < StandardError; end
    class InvalidCaseNumber < StandardError; end

    include GlimrApiClient::Api

    TRIBUNAL_JURISDICTION_ID = 8

    # TODO: Case should use `#call(params)` directly, like everything else.
    def self.find(case_reference, confirmation_code)
      new(case_reference, confirmation_code).call
    end

    def initialize(case_reference, confirmation_code)
      @case_reference = case_reference
      @confirmation_code = confirmation_code
    end

    def call
      post
      self
    end

    def title
      # This should be;
      #
      #   @title ||= response_body.fetch(:caseTitle)
      #
      # But, a change in the Glimr API means that the title is
      # currently being returned with each fee liability. So,
      # for the time being, we will fetch it from there.
      # I'm leaving the "Missing Title" text so that nobody forgets
      # that this needs to be fixed, preferably by changing the
      # Glimr RequestPayableCaseFees API call back to returning
      # caseTitle at the top-level of the response data.

      @title ||= fees.any? ? fees.first.case_title : "Missing Title"
    end

    def fees
      @fees ||= response_body.fetch(:feeLiabilities).map do |fee|
        OpenStruct.new(
          glimr_id: Integer(fee.fetch(:feeLiabilityId)),
          description: fee.fetch(:onlineFeeTypeDescription),
          amount: Integer(fee.fetch(:payableWithUnclearedInPence)),
          case_title: fee.fetch(:caseTitle)
        )
      end
    end

    private

    def endpoint
      '/requestpayablecasefees'
    end

    def re_raise_error(body)
      error = body.fetch(:message, nil)
      case body.fetch(:glimrerrorcode, nil)
      when 212 # TribunalCase for CaseNumber not found
        raise NotFound, error
      when 213 # Invalid CaseNumber/CaseConfirmationCode combination
        raise InvalidCaseNumber, error
      end
      super(message: error)
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
