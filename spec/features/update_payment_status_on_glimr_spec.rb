require 'rails_helper'
require 'support/shared_examples_for_glimr'

RSpec.feature 'update GLiMR with payment status' do
  describe 'happy path' do
    include_examples 'report payment taken to glimr',
      'feeLiabilityId=12345&govpayReference=123ABC&paidAmountInPence=2000&paymentReference=ref123'

    it 'updates glimr when the fee is paid' do
      visit new_fee_path
      click_on 'Pay fee'
      expect(page.body).to have_text('Fee paid')
    end
  end

  describe 'GLiMR returns a 500' do
    include_examples 'glimr fee_paid returns a 500'

    it 'raises and exception' do
      visit new_fee_path
      expect { click_on 'Pay fee' }.
        to raise_error(GlimrApiClient::Api::PaymentNotificationFailure)
    end
  end
end
