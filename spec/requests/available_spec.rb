require 'rails_helper'
require 'support/shared_examples_for_glimr'
require 'pry'

RSpec.describe GlimrApiClient::Available do
  subject { described_class.call }

  describe '#available?' do
    context 'when the service is available' do
      include_examples 'glimr availability request', { glimrAvailable: 'yes' }

      it 'the call reports availability status' do
        expect(subject.available?).to be_truthy
      end
    end

    context 'when the service responds that it is not available' do
      include_examples 'glimr availability request', { glimrAvailable: 'no' }

      it 'the call raises an error' do
        expect{ subject.available? }.
          to raise_exception(GlimrApiClient::Api::Unavailable)
      end
    end

    context 'when the service responds with an error' do
      include_examples 'glimr availability request returns a 500'

      it 'the call raises an error' do
        expect{ subject.available? }.
          to raise_exception(GlimrApiClient::Api::Unavailable)
      end
    end
  end
end
