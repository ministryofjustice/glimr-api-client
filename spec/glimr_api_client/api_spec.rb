require 'spec_helper'

RSpec.describe GlimrApiClient::Api, '#post' do
  let(:docpath) { '/Live_API/api/tdsapi' }
  let(:api_endpoint) { 'endpoint' }
  let(:path) { [docpath, api_endpoint].join('/') }

  # Required for run/build ordering in mutation tests.
  let(:glimr_method_class) do
    Class.new do
      include GlimrApiClient::Api

      def initialize(call = nil)
        @call = call
      end

      def call
        "called#{@call}"
      end

      def request_body
        { parameter: 'parameter' }
      end
    end.new
  end

  before do
    glimr_method_class.instance_eval do
      def endpoint
        '/endpoint'
      end
    end
  end

  describe 'excon client' do
    before do
      Excon.stub(
        {
          method: :post,
          body: { parameter: "parameter" }.to_json,
          headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        },
        path: path,
        persistent: true,
        read_timeout: 5
        },
        status: 200, body: { response: 'response' }.to_json
      )
    end

    it 'returns expected response' do
      glimr_method_class.tap do |o|
        expect { o.post }.not_to raise_error
        expect(o.response_body).to eq({ response: 'response' })
      end
    end
  end

  context 'common errors' do
    it 'raises unavailable on 404' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 404
      )
      expect { glimr_method_class.post }.to raise_error(GlimrApiClient::Unavailable, '404')
    end

    it 'raises an exception when it receives a 500' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 500
      )
      expect { glimr_method_class.post }.to raise_error(GlimrApiClient::Unavailable, '500')
    end

    it 'raises an exception when it receives a 400' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 400
      )
      expect { glimr_method_class.post }.to raise_error(GlimrApiClient::Unavailable, '400')
    end

    it 'does not raise exceptions for 3xx range codes' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 399
      )
      expect { glimr_method_class.post }.not_to raise_error
    end

    it 'does not raise exceptions for out-of-range codes' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 600
      )
      expect { glimr_method_class.post }.not_to raise_error
    end

    it 'raises an exception when it receives a 599' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 599
      )
      expect { glimr_method_class.post }.to raise_error(GlimrApiClient::Unavailable, '599')
    end
  end

  context 'the client dies without returning' do
    let(:excon) {
      class_double(Excon)
    }

    before do
      expect(excon).to receive(:post).and_raise(Excon::Error, 'it died')
    end

    it 'raises an exception if the client dies' do
      expect(glimr_method_class).to receive(:client).and_return(excon)
      expect { glimr_method_class.post }.to raise_error(GlimrApiClient::Unavailable, 'it died')
    end
  end

  context 'errors' do
    let(:excon) { class_double(Excon, post: post_response) }

    context 'from glimr'
    let(:body) {
      {
        glimrerrorcode: 123,
        message: 'Some Glimr Error'
      }
    }
    let(:post_response) { double(status: 404, body: body.to_json) }

    before do
      allow(glimr_method_class).to receive(:client).and_return(excon)
    end

    describe 'Unspecified error' do
      it 'raises an error' do
        expect { glimr_method_class.post }.to raise_error(GlimrApiClient::Unavailable, 'Some Glimr Error')
      end
    end

    context 'network errrors' do
      before do
        allow(excon).to receive(:post).and_raise(Excon::Error, 'kaboom')
      end

      it 're-raises the error' do
        expect { glimr_method_class.post }.to raise_error(GlimrApiClient::Unavailable, 'kaboom')
      end
    end
  end
end
