require 'spec_helper'


RSpec.describe GlimrApiClient::Base do
  let(:docpath) { '/Live_API/api/tdsapi' }
  let(:api_endpoint) { 'endpoint' }
  let(:path) { [docpath, api_endpoint].join('/') }

  describe '.call' do
    let(:base) { instance_double(described_class, call: true) }

    it 'passes all arguments on to the instance method' do
      expect(described_class).to receive(:new). with({ something: 'something' }).and_return(base)
      described_class.call(something: 'something')
    end

    it 'delegates to #call on the instance' do
      allow(described_class).to receive(:new).with({ something: 'something' }).and_return(base)
      expect(base).to receive(:call)
      described_class.call(something: 'something')
    end
  end

  describe '.new' do
    it 'superclass placeholder that sets #args equal to whatever it is passed' do
      described_class.new('dummy').tap do |base|
        expect(base.args).to eql(['dummy'])
      end
    end
  end

  describe '#call' do
    before do
      allow(subject).to receive(:post)
    end

    it 'calls #check_request!' do
      expect(subject).to receive(:check_request!)
      subject.call
    end

    it 'calls #post' do
      expect(subject).to receive(:post)
      subject.call
    end

    it 'returns itself' do
      expect(subject.call).to eq(subject)
    end
  end
end
