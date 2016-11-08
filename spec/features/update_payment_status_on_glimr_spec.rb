require 'rails_helper'
require 'support/shared_examples_for_glimr'

RSpec.feature 'update GLiMR with payment status' do
  describe 'happy path' do
    include_examples 'report payment taken to glimr',
      # The excon stub is sensitive to the ordering of the request body order.
      { feeLiabilityId: 12345,
      paymentReference: 'ref123',
      govpayReference: '123ABC',
      paidAmountInPence: 2000 }.to_json

    it 'updates glimr when the fee is paid' do
      visit new_fee_path
      click_on 'Pay fee'
      expect(page.body).to have_text('Fee paid')
    end
  end
end
