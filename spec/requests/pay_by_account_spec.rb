require 'rails_helper'

RSpec.describe GlimrApiClient::PayByAccount do
  let(:request) {
    {
      feeLiabilityId: 123456789,
      pbaAccountNumber: "PBA1234567",
      pbaConfirmationCode: "AC-D3-46", # or "ACD346" - API accepts either
      pbaTransactionReference: "Our ref: TC/2015/123",
      amountToPayInPence: 9999
    }
  }

  let(:response) {
    {
      feeLiabilityId: 123456789,
      feeTransactionId: 123456789,
      amountToPayInPence: 9999
    }
  }
end
