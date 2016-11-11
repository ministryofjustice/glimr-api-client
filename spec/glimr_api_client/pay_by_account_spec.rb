require 'spec_helper'
require 'support/shared_examples_for_generic_errors'

RSpec.describe GlimrApiClient::PayByAccount do
  let(:params) {
    {
      feeLiabilityId: 123456789,
      pbaAccountNumber: "PBA1234567",
      pbaConfirmationCode: "AC-D3-46", # or "ACD346" - API accepts either
      pbaTransactionReference: "Our ref: TC/2015/123",
      amountToPayInPence: 9999
    }
  }

  let(:post_response) { double(status: 200, body: {}) }
  let(:excon) { class_double(Excon, post: post_response) }

  before do
    allow_any_instance_of(described_class).to receive(:client).and_return(excon)
  end

  describe '#endpoint' do
    specify {
      # Quick-n-dirty mutant kill.
      expect(described_class.new(params).send(:endpoint)).to eq('/pbapaymentrequest')
    }
  end

  describe '#request_body' do
    it 'raises an error when no parameters are supplied' do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    context 'when feeLiabilityId is missing' do
      before do
        params.delete(:feeLiabilityId)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:feeLiabilityId]')
      end
    end

    context 'when pbaAccountNumber is missing' do
      before do
        params.delete(:pbaAccountNumber)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:pbaAccountNumber]')
      end
    end

    context 'when pbaConfirmationCode is missing' do
      before do
        params.delete(:pbaConfirmationCode)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:pbaConfirmationCode]')
      end
    end

    context 'when pbaTransactionReference is missing' do
      before do
        params.delete(:pbaTransactionReference)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:pbaTransactionReference]')
      end
    end

    describe 'pbaTransactionReference length' do
      describe 'is greater than 240' do
        before do
          params[:pbaTransactionReference] = 'x' * 241
        end

        it 'raises an error' do
          expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:pbaTransactionReferenceTooLong]')
        end
      end

      describe 'is exactly 240' do
        before do
          params[:pbaTransactionReference] = 'x' * 240
        end

        it 'does not raise an error' do
          expect { described_class.call(params) }.not_to raise_error
        end
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
          amountToPayInPence: 9999
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

    # Error codes 501 to 505 *should* be covered by the validations, so they
    # are not processed here.
    describe 'error 511 - FeeLiability not found for FeeLiabilityID' do
      let(:body) {
        {
          glimrerrorcode: 511,
          # Truncated for brevity
          message: 'Not found'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::FeeLiabilityNotFound, 'Not found')
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

    include_examples 'generic errors'

  end
end
