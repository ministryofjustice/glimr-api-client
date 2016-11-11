require 'spec_helper'
require 'support/shared_examples_for_generic_errors'

RSpec.describe GlimrApiClient::HwfRequested do
  let(:params) {
    {
      feeLiabilityId: 123456789,
      hwfRequestReference: 'l7w64bst84jwy',
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
      expect(described_class.new(params).send(:endpoint)).to eq('/hwfrequested')
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

    context 'when hwfRequestReference is missing' do
      before do
        params.delete(:hwfRequestReference)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:hwfRequestReference]')
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

    # Error codes 601 to 603 *should* be covered by the validations, so they
    # are not processed here.
    describe 'error 611 - FeeLiability not found for FeeLiabilityID' do
      let(:body) {
        {
          glimrerrorcode: 611,
          # Truncated for brevity
          message: 'Not found'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::HwfRequested::FeeLiabilityNotFound, 'Not found')
      end
    end

    describe 'error 612 - Invalid AmountToPay {0}' do
      let(:body) {
        {
          glimrerrorcode: 612,
          # Truncated for brevity
          message: 'Invalid Amount'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::HwfRequested::InvalidAmount, 'Invalid Amount')
      end
    end

    include_examples 'generic errors'
  end
end
