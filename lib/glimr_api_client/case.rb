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

    # Case title is returned with each fee liability, rather than as a top-level
    # attribute of the case. If there are any unpaid fee liabilities, we want to
    # take the title from the first of these (because that is the most relevant
    # title)
    def title
      @title ||= begin
                   fee = unpaid_fees.any? ? unpaid_fees.first : all_fees.first
                   fee.nil? ? 'Missing Title' : fee.case_title
                 end
    end

    # We only care about outstanding fee liabilities, wrt what we are asking the
    # taxpayer to pay
    def fees
      unpaid_fees
    end

    private

    def unpaid_fees
      @unpaid_fees ||= all_fees.find_all {|fee| fee.amount > 0}
    end

    def all_fees
      @all_fees ||= response_body.fetch(:feeLiabilities).map do |fee|
        OpenStruct.new(
          glimr_id: Integer(fee.fetch(:feeLiabilityId)),
          description: fee.fetch(:onlineFeeTypeDescription),
          amount: Integer(fee.fetch(:payableWithUnclearedInPence)),
          case_title: fee.fetch(:caseTitle)
        )
      end
    end

    def endpoint
      '/requestcasefees'
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
