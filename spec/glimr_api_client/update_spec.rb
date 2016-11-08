require 'rails_helper'

RSpec.describe GlimrApiClient::Update do
  let(:params) {
    {
      feeLiabilityId: 12345,
      paymentReference: 12345,
      govpayReference: 12345,
      paidAmountInPence: 2000
    }
  }
  let(:post_response) { double(status: 200, body: params.to_json) }
  let(:excon) { class_double(Excon, post: post_response) }

  before do
    allow_any_instance_of(described_class).to receive(:client).and_return(excon)
  end

  describe '#endpoint' do
    specify {
      # Quick-n-dirty mutant kill.
      expect(described_class.new(fee).send(:endpoint)).to eq('/paymenttaken')
    }
  end

  it 'raises an error when a fee object is not supplied' do
    expect { described_class.call }.to raise_error(ArgumentError)
  end

  describe '#request_body' do
    context 'when feeLiabilityId is missing' do
      before do
        params.delete(:feeLiabilityId)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:feeLiabilityId]')
      end
    end

    context 'when paymentReference is missing' do
      before do
        params.delete(:paymentReference)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:paymentReference]')
      end
    end

    context 'when govpayReference is missing' do
      before do
        params.delete(:govpayReference)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:govpayReference]')
      end
    end

    context 'when paidAmountInPence is missing' do
      before do
        params.delete(:paidAmountInPence)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:paidAmountInPence]')
      end
    end

    it 'does not raise an error when required parameters are provided' do
      expect { described_class.call(params) }.not_to raise_error
    end
  end

  describe '#post' do
    it 'passes all the parameters to glimr' do
      post_params = { body: params.to_json }
      expect(excon).to receive(:post).with(post_params)
      described_class.call(params)
    end

    describe '#response_body' do
      let(:response) {
        {
          feeLiabilityId: 123456789,
          feeTransactionId: 123456789,
          paidAmountInPence: 9999
        }
      }
      # This overrides the double at the beginning and is returned by the
      # excon client stub, also declared at the beginning.
      let(:post_response) { double(status: 200, body: response.to_json) }

      it 'returns the response as a hash' do
        expect(described_class.call(params).response_body).to eq(response)
      end
    end
  end

  context 'errors' do
    let(:body) { { message: '' } }
    let(:post_response) { double(status: 404, body: body.to_json) }

    # Error codes 301 to 305 *should* be covered by the validations, so they
    # are not processed here.
    describe 'error 311 - FeeLiability not found for FeeLiabilityID' do
      let(:body) {
        {
          glimrerrorcode: 311,
          # Truncated for brevity
          message: 'Not found'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Case::FeeLiabilityNotFound, 'Not found')
      end
    end

    # The curly-braces are taken from the GLiMR api spec and appear to
    # represent a placeholder for an arbitrary value. I'm reproducing them here
    # to make it easier to link the descriptions with the error code table in
    # the spec.
    describe 'error 512 - PBA account {0} not found' do
      let(:body) {
        {
          glimrerrorcode: 512,
          # Truncated for brevity
          message: 'Not found'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::PayByAccount::AccountNotFound, 'Not found')
      end
    end

    describe 'error 513 - Invalid PBAAccountNumber/PBAConfirmationCode combination {0} / {1}' do
      let(:body) {
        {
          glimrerrorcode: 513,
          # Truncated for brevity
          message: 'Invalid AccountNumber'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::PayByAccount::InvalidAccountAndConfirmation, 'Invalid AccountNumber')
      end
    end

    describe 'error 514 - Invalid AmountToPay {0}' do
      let(:body) {
        {
          glimrerrorcode: 514,
          # Truncated for brevity
          message: 'Invalid Amount'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::PayByAccount::InvalidAmount, 'Invalid Amount')
      end
    end

    # 'Equivalent to Credit Clearance suspended' according to spec.
    describe 'error 521 - PBAGlobalStatus is inactive' do
      let(:body) {
        {
          glimrerrorcode: 521,
          # Truncated for brevity
          message: 'PBAGlobalStatus'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::PayByAccount::GlobalStatusInactive, 'PBAGlobalStatus')
      end
    end

    # 'Equivalent to PBA account not authorised for jurisdiction' according to spec.
    describe 'error 522 - PBAGlobalStatus is inactive' do
      let(:body) {
        {
          glimrerrorcode: 522,
          # Truncated for brevity
          message: 'Jurisdiction'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::PayByAccount::JurisdictionStatusInactive, 'Jurisdiction')
      end
    end

    describe 'Unspecified error' do
      let(:body) {
        {
          message: 'Kaboom'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Unavailable, 'Kaboom')
      end
    end
  end
end
