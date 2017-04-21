require 'spec_helper'

RSpec.describe GlimrApiClient::Available do
  subject { described_class.call }

  describe '#request_body' do
    it 'returns an empty hash' do
      # Simple mutation kill. Much more straightforward than trying to pick it
      # out of a mocked full GlimrApiClient::Api client call.
      expect(described_class.new.send(:request_body)).to eq({})
    end
  end

  describe '#available?' do
    context 'when the service is available' do
      before do
       stub_request(:post, /glimravailable$/).
         to_return(status: 200, body: '{"glimrAvailable": "yes"}')
      end

      it 'the call reports availability status' do
        expect(subject.available?).to be_truthy
      end
    end

    context 'when the service responds that it is not available' do
      before do
       stub_request(:post, /glimravailable$/).
         to_return(status: 200, body: '{"glimrAvailable": "no"}')
      end

      it 'the call raises an error' do
        expect{ subject.available? }.
          to raise_exception(GlimrApiClient::Unavailable)
      end
    end

    context 'when the service responds with an error' do
      before do
        stub_request(:post, /glimravailable$/).to_return(status: 500)
      end

      it 'the call raises an error' do
        expect{ subject.available? }.
          to raise_exception(GlimrApiClient::Unavailable)
      end
    end
  end
end
