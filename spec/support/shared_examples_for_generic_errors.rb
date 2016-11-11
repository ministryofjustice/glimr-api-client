RSpec.shared_examples 'generic errors' do
    describe 'Unspecified error' do
      let(:body) {
        {
          message: 'Kaboom'
        }
      }

      it 'raises an Unavailable error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Unavailable, 'Kaboom')
      end
    end

    describe 'Missing error message' do
      let(:body) {{}}

      it 'raises an Unavailable error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Unavailable)
      end
    end
end
