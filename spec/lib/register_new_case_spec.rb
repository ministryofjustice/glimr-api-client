require 'spec_helper'

RSpec.describe GlimrApiClient::RegisterNewCase do
  subject do
    described_class.new({ jurisdictionId: 8, onlineMappingCode: 'something' })
  end

  describe '#timeout' do
    it 'sets a long default timeout for the register new case connection' do
      expect(subject.timeout).to eq(32)
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
