require 'spec_helper'

RSpec.describe GlimrApiClient::Api do
  let(:docpath) { '/Live_API/api/tdsapi' }
  let(:api_endpoint) { 'endpoint' }
  let(:path) { [docpath, api_endpoint].join('/') }

  # Required for run/build ordering in mutation tests.
  subject do
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
    subject.instance_eval do
      def endpoint
        '/endpoint'
      end
    end
  end

  describe '#post' do
    let(:body) { { response: 'response' } }

    before do
      stub_request(:post, /endpoint$/).
        to_return(status: 200, body: body.to_json)
    end

    context '#request_body' do
      it 'is always sent as JSON' do
        expect(subject).to receive(:make_request).with(anything, { parameter: 'parameter' }.to_json)
        subject.post
      end
    end

    context '#response_body' do
      it 'gets set from the #post call' do
        subject.tap do |o|
          o.post
          expect(o.response_body).to eq({ response: 'response' })
        end
      end
    end

    context '#make_request' do
      # Other tests fail if this call is wrong. Mutant does not target them,
      # though, as they are outside its understood hierarchy.
      it 'calls the correct endpoint' do
        allow(subject).to receive(:api_url).and_return('https://api')
        expect(subject).to receive(:make_request).with('https://api/endpoint', anything)
        subject.post
      end

      it 'send the #request_body from the including class' do
        expect(subject).to receive(:make_request).with(anything, { parameter: 'parameter' }.to_json)
        subject.post
      end
    end

    context "with GLIMR_API_DEBUG = true" do
      before do
        stub_const('ENV', ENV.to_h.merge('GLIMR_API_DEBUG' => true))
        allow($stdout).to receive(:write)
      end

      it "logs the request" do
        subject.tap do |o|
          expect($stdout).to receive(:write).with(%[GLIMR POST: /endpoint - {"parameter":"parameter"}])
          o.post
        end
      end
    end

    context "without GLIMR_API_DEBUG" do
      before do
        allow($stdout).to receive(:write)
      end

      it "does not log the request" do
        subject.tap do |o|
          expect($stdout).to_not receive(:write).with(%[GLIMR POST: /endpoint - {"parameter":"parameter"}])
          o.post
        end
      end
    end

    context 'timeout' do
      before do
        stub_request(:post, /endpoint$/).to_timeout
      end

      it 'raises Unavailable "timed out"' do
        expect{ subject.post }.to raise_error(GlimrApiClient::Unavailable, 'timed out')
      end
    end

    context 'glimr errors' do
      context 'with :glimererrorcode' do
        let(:body) { { glimrerrorcode: 123, message: 'Some Glimr Error' } }

        it 'raises Unavailable with the glimr error message' do
          expect { subject.post }.to raise_error(GlimrApiClient::Unavailable, 'Some Glimr Error')
        end
      end

      context 'without :glimrerrorcode' do
        let(:body) { { message: 'Error without code' } }

        it 'raises Unavailable with the glimr error message' do
          expect { subject.post }.to raise_error(GlimrApiClient::Unavailable, 'Error without code')
        end
      end
    end

    context 'network errors' do
      it 'raises Unavailable on 404' do
        stub_request(:post, /endpoint$/).to_return(status: 404)
        expect { subject.post }.to raise_error(GlimrApiClient::Unavailable, '404')
      end

      it 'raises Unavailable when it receives a 400' do
        stub_request(:post, /endpoint$/).to_return(status: 400)
        expect { subject.post }.to raise_error(GlimrApiClient::Unavailable, '400')
      end

      it 'raises Unavailable when it receives a 500' do
        stub_request(:post, /endpoint$/).to_return(status: 500)
        expect { subject.post }.to raise_error(GlimrApiClient::Unavailable, '500')
      end

      it 'raises Unavailable when it receives a 599' do
        stub_request(:post, /endpoint$/).to_return(status: 599)
        expect { subject.post }.to raise_error(GlimrApiClient::Unavailable, '599')
      end

      it 'does not raise exceptions for 3xx range codes' do
        stub_request(:post, /endpoint$/).to_return(status: 399)
        expect { subject.post }.not_to raise_error
      end

      it 'does not raise exceptions for out-of-range codes' do
        stub_request(:post, /endpoint$/).to_return(status: 600)
        expect { subject.post }.not_to raise_error
      end
    end
  end

  it 'passes an api endpoint and the request body to the REST client' do
    allow(subject).to receive(:api_url).and_return('some_url')
    expect(subject).to receive(:client).
      with('some_url/endpoint', { parameter: 'parameter' }.to_json).
      and_return(double.as_null_object)
    subject.post
  end

  describe 'configuration' do
    it 'fetches the glimr api endpoint from ENV, sets default if not available' do
      expect(ENV).to receive(:fetch).
        with('GLIMR_API_URL', 'https://glimr-api.taxtribunals.dsd.io/Live_API/api/tdsapi')

      # This is a mutant kill. If I call `.post`, then I have to stub most of
      # the ENV variables (several fail with dummy objects) and webmock
      # the response. Calling the private method seems like a good tradeoff for
      # reducing the spec complexity.
      subject.send(:api_url)
    end
  end

  describe 'REST client' do
    before do
      stub_request(:post, /endpoint$/).
        to_return(status: 200, body: {response: 'response'}.to_json)
    end

    # Begin Typhoeus-specific mutant kills.
    it 'sets the :body attribute of the client' do
      expect(Typhoeus::Request).to receive(:new).
        with(anything, hash_including(body: { parameter: 'parameter' }.to_json)).
        and_return(double.as_null_object)
      subject.post
    end

    it 'sets JSON request headers' do
      expect(Typhoeus::Request).to receive(:new).
        with(anything, hash_including(headers: { "Content-Type" => "application/json", "Accept" => "application/json" })).
        and_return(double.as_null_object)
      subject.post
    end

    # Typhoeus can set :connect_timeout and :read_timeout if more granularity is required.
    it 'sets the client timeout' do
      expect(Typhoeus::Request).to receive(:new).
        with(anything, hash_including(timeout: kind_of(Numeric))).
        and_return(double.as_null_object)
      subject.post
    end
    # End Typhoeus-specific mutant kills.

    context "without GLIMR_API_DEBUG" do
      before do
        allow($stdout).to receive(:write)
      end

      it "does not log the request" do
        subject.tap do |o|
          expect($stdout).to_not receive(:write).with(%[GLIMR POST: /endpoint - {"parameter":"parameter"}])
          expect($stdout).to_not receive(:write).with(%[GLIMR RESPONSE: {"response":"response"}])
          o.post
        end
      end
    end

    context "with GLIMR_API_DEBUG = true" do
      before do
        stub_const('ENV', ENV.to_h.merge('GLIMR_API_DEBUG' => true))
        allow($stdout).to receive(:write)
      end

      it "logs the request" do
        subject.tap do |o|
          expect($stdout).to receive(:write).with(%[GLIMR RESPONSE: {"response":"response"}])
          o.post
        end
      end
    end
  end

  describe 'parsing the JSON response' do
    let(:parsed_response) { instance_double(Hash, key?: false, empty?: false) }

    before do
      stub_request(:post, /endpoint$/).
        to_return(status: 200, body: {response: 'response'}.to_json)
      allow(JSON).to receive(:parse).and_return(parsed_response)
    end

    it 'symbolizes the keys' do
      expect(JSON).to receive(:parse).with(anything, symbolize_names: true)
      subject.post
    end

    it 'checks the response for a :glimrerrorcode key' do
      expect(parsed_response).to receive(:key?).with(:glimrerrorcode)
      subject.post
    end

    it 'raises an error if there is a :glimrerrorcode key' do
      allow(parsed_response).to receive(:key?).with(:glimrerrorcode).and_return(true)
      expect(subject).to receive(:re_raise_error)
      subject.post
    end

    it 'checks the response for an error :message key' do
      expect(parsed_response).to receive(:key?).with(:message)
      subject.post
    end

    it 'raises an error if there is an error :message key' do
      allow(parsed_response).to receive(:key?).with(:message).and_return(true)
      expect(subject).to receive(:re_raise_error)
      subject.post
    end
  end
end
