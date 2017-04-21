require 'spec_helper'

RSpec.describe GlimrApiClient::RegisterNewCase do
  subject do
    described_class.new({ jurisdictionId: 8, onlineMappingCode: 'something' })
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

  describe '#timeout' do
    it 'sets a long default timeout for the register new case connection' do
      expect(subject.timeout).to eq(32)
    end

    it 'allows overriding' do
      allow(ENV).to receive(:fetch).with('GLIMR_REGISTER_NEW_CASE_TIMEOUT_SECONDS', 32).and_return(60)
      expect(subject.timeout).to eq(60)
    end

    it 'does not error if override is a string' do
      allow(ENV).to receive(:fetch).with('GLIMR_REGISTER_NEW_CASE_TIMEOUT_SECONDS', 32).and_return('55')
      expect(subject.timeout).to be_kind_of(Integer)
      expect(subject.timeout).to eq(55)
    end
  end
end
