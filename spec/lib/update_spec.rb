require 'spec_helper'

RSpec.describe GlimrApiClient::Update do
  subject do
    described_class.new('ABC')
  end

  # As noted elsewhere, the use of #send in this block to test a call contained
  # in a private method is an expediency to enable a mutant kill that would
  # otherwise involve a convoluted set of mocks/stubs.
  describe '#re_raise_error' do
    let(:body) { instance_double(Hash) }

    it 'does not break if the :message key is missing' do
      allow(body).to receive(:fetch).with(:glimrerrorcode, nil)
      expect(body).to receive(:fetch).with(:message, nil)
      expect { subject.send(:re_raise_error, body) }.to raise_error(GlimrApiClient::Unavailable)
    end

    it 'does not break if the :glimrerrorcode key is missing' do
      allow(body).to receive(:fetch).with(:message, nil)
      expect(body).to receive(:fetch).with(:glimrerrorcode, nil)
      expect { subject.send(:re_raise_error, body) }.to raise_error(GlimrApiClient::Unavailable)
    end
  end
end
