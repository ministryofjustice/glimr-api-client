require 'rails_helper'

RSpec.describe GlimrApiClient::PayByAccount do
  let(:params) { {} }
  let(:excon) { class_double(Excon, post: double(status: 200, body: '')) }

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
    let(:valid_params) {
      {
        feeLiabilityId: 123456789,
        pbaAccountNumber: "PBA1234567",
        pbaConfirmationCode: "AC-D3-46", # or "ACD346" - API accepts either
        pbaTransactionReference: "Our ref: TC/2015/123",
        amountToPayInPence: 9999
      }
    }

    it 'raises an error when no parameters are supplied' do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    context 'when feeLiabilityId is missing' do
      before do
        valid_params.delete(:feeLiabilityId)
      end

      it 'raises an error' do
        expect { described_class.call(valid_params) }.to raise_error(GlimrApiClient::RequestError, '[:feeLiabilityId]')
      end
    end

    context 'when pbaAccountNumber is missing' do
      before do
        valid_params.delete(:pbaAccountNumber)
      end

      it 'raises an error' do
        expect { described_class.call(valid_params) }.to raise_error(GlimrApiClient::RequestError, '[:pbaAccountNumber]')
      end
    end

    context 'when pbaConfirmationCode is missing' do
      before do
        valid_params.delete(:pbaConfirmationCode)
      end

      it 'raises an error' do
        expect { described_class.call(valid_params) }.to raise_error(GlimrApiClient::RequestError, '[:pbaConfirmationCode]')
      end
    end

    context 'when pbaTransactionReference is missing' do
      before do
        valid_params.delete(:pbaTransactionReference)
      end

      it 'raises an error' do
        expect { described_class.call(valid_params) }.to raise_error(GlimrApiClient::RequestError, '[:pbaTransactionReference]')
      end
    end

    describe 'pbaTransactionReference length' do
      describe 'is greater than 240' do
        before do
          valid_params[:pbaTransactionReference] = 'x' * 241
        end

        it 'raises an error' do
          expect { described_class.call(valid_params) }.to raise_error(GlimrApiClient::RequestError, '[:pbaTransactionReferenceTooLong]')
        end
      end

      describe 'is exactly 240' do
        before do
          valid_params[:pbaTransactionReference] = 'x' * 240
        end

        it 'does not raise an error' do
          expect { described_class.call(valid_params) }.not_to raise_error
        end
      end
    end

    it 'does not raise an error when required parameters are provided' do
      expect { described_class.call(valid_params) }.not_to raise_error
    end
  end

  describe '#post' do
    let(:params) {
      {
        feeLiabilityId: 123456789,
        pbaAccountNumber: "PBA1234567",
        pbaConfirmationCode: "AC-D3-46", # or "ACD346" - API accepts either
        pbaTransactionReference: "Our ref: TC/2015/123",
        amountToPayInPence: 9999
      }
    }

    it 'passes all the parameters to glimr' do
      post_params = { body: params.to_json }
      expect(excon).to receive(:post).with(post_params)
      described_class.call(params)
    end
  end
end
