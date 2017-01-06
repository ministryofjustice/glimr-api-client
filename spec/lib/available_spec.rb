require 'spec_helper'

RSpec.describe GlimrApiClient::Available do

  it 'posts an empty hash as its payload' do
    req = double(:request, body: {})
    resp = double(:response).as_null_object
    expect(req).to receive(:post).with(body: '{}').and_return(resp)
    allow(subject).to receive(:client).and_return(req)
    expect { subject.call }.not_to raise_error
  end
end
