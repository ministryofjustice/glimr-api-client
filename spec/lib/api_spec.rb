require 'spec_helper'

RSpec.describe GlimrApiClient::Api do
  # Required for run/build ordering in mutation tests.
  subject do
    Class.new do
      include GlimrApiClient::Api
    end.new
  end

  describe '#timeout' do
    it 'sets a default timeout for the connection' do
      expect(subject.timeout).to eq(5)
    end

    it 'allows overriding' do
      allow(ENV).to receive(:fetch).with('GLIMR_API_TIMEOUT_SECONDS', 5).and_return(7)
      expect(subject.timeout).to eq(7)
    end

    it 'does not error if override is a string' do
      allow(ENV).to receive(:fetch).with('GLIMR_API_TIMEOUT_SECONDS', 5).and_return('7')
      expect(subject.timeout).to eq(7)
    end
  end
end
