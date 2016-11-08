require 'rails_helper'

RSpec.describe GlimrApiClient::Case do
  let(:case_number) { 'TC/2012/00001' }
  let(:confirmation_code) { 'ABC123' }
  let(:params) {
    {
      jurisdictionId: 8,
      caseNumber: case_number,
      confirmationCode: confirmation_code
    }
  }
  let(:fees) {
    {
      jurisdictionId: 8,
      tribunalCaseId: 60_029,
      feeLiabilities:
        [
          {
            feeLiabilityId: '7',
           caseTitle: 'First Title',
           onlineFeeTypeDescription: 'Lodgement Fee',
           payableWithUnclearedInPence: '2000'
          },
          { feeLiabilityId: '7',
            caseTitle: 'Second Title',
            onlineFeeTypeDescription: 'Another Fee',
            payableWithUnclearedInPence: '2000'
          }
        ]
    }
  }

  let(:post_response) { double(status: 200, body: '') }
  let(:excon) { class_double(Excon, post: post_response) }

  before do
    allow_any_instance_of(described_class).to receive(:client).and_return(excon)
  end

  it 'raises an error when no parameters are supplied' do
    expect { described_class.find }.to raise_error(ArgumentError)
  end

  describe '#endpoint' do
    specify {
      # Quick-n-dirty mutant kill.
      expect(described_class.new(case_number, confirmation_code).send(:endpoint)).to eq('/requestpayablecasefees')
    }
  end

  describe '#post' do
    it 'passes all the parameters to glimr' do
      post_params = { body: params.to_json }
      expect(excon).to receive(:post).with(post_params)
      described_class.find(case_number, confirmation_code)
    end
  end

  context 'errors' do
    let(:body) { { message: '' } }
    let(:post_response) { double(status: 404, body: body.to_json) }

    # The curly-braces are taken from the GLiMR api spec and appear to
    # represent a placeholder for an arbitrary value. I'm reproducing them here
    # to make it easier to link the descriptions with the error code table in
    # the spec.
    describe 'error 212 - TribunalCase for CaseNubmer {0} not found' do
      let(:body) {
        {
          glimrerrorcode: 212,
          # Truncated for brevity
          message: 'TribunalCase not found'
        }
      }

      it 'raises an error' do
        expect {
          described_class.find(case_number, confirmation_code)
        }.to raise_error(GlimrApiClient::Case::NotFound, 'TribunalCase not found')
      end
    end

    describe 'error 213 - Invalid CaseNumber/CaseConfirmationCode combination {0} / {1}' do
      let(:body) {
        {
          glimrerrorcode: 213,
          # Truncated for brevity
          message: 'Invalid CaseNumber'
        }
      }

      it 'raises an error' do
        expect {
          described_class.find(case_number, confirmation_code)
        }.to raise_error(GlimrApiClient::Case::InvalidCaseNumber, 'Invalid CaseNumber')
      end
    end

    describe 'Unspecificed error' do
      let(:body) {
        {
          message: 'Kaboom'
        }
      }

      it 'raises an Unavailable error' do
        expect {
          described_class.find(case_number, confirmation_code)
        }.to raise_error(GlimrApiClient::Unavailable, 'Kaboom')
      end
    end
  end
end
