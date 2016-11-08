require 'rails_helper'
require 'support/shared_examples_for_glimr'

RSpec.feature 'Request a brand new case' do
  case_number = 'TC/2012/00001'
  confirmation_code = 'ABC123'

  describe 'happy path' do
    let(:make_a_case_request) {
      visit '/'
      click_on 'Start now'
      fill_in 'case_request_case_reference', with: case_number
      fill_in 'case_request_confirmation_code', with: confirmation_code
      click_on 'Find case'
    }

    describe 'and glimr responds normally' do
      include_examples 'a case fee of £20 is due', case_number, confirmation_code

      scenario 'then we show the fee' do
        make_a_case_request
        expect(page).to have_text('You vs HM Revenue & Customs')
        expect(page).to have_text('£20.00')
        expect(page).to have_text('Lodgement Fee')
      end
    end

    describe 'and glimr times out' do
      let(:excon) {
        class_double(Excon)
      }

      before do
        expect(excon).to receive(:post).and_raise(Excon::Errors::Timeout)
        expect(Excon).to receive(:new).and_return(excon)
      end

      scenario 'we alert the user' do
        visit '/'
        expect(page).to have_text('The service is currently unavailable')
      end
    end
  end

  describe 'with a bad case reference' do
    include_examples 'case not found'

    scenario 'then tell the user the case cannot be found' do
      expect {
        visit '/'
        click_on 'Start now'
        fill_in 'case_request_case_reference', with: case_number
        fill_in 'case_request_confirmation_code', with: confirmation_code
        click_on 'Find case'
      }.to raise_error(GlimrApiClient::Case::NotFound)
    end
  end

  describe 'the case cannot be found' do
    include_examples 'case not found'

    scenario 'then tell the user the case cannot be found' do
      expect {
        visit '/'
        click_on 'Start now'
        fill_in 'case_request_case_reference', with: 'TC/2016/00001'
        fill_in 'case_request_confirmation_code', with: 'ABC123'
        click_on 'Find case'
      }.to raise_error(GlimrApiClient::Case::NotFound)
    end
  end
end
