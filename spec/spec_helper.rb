# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "iletiniz"
require "json"
require "time"

# Ag trafigi olusturmayan sahte transport.
class FakeTransport
  attr_reader :calls

  def initialize(status: 200, body: {})
    @status = status
    @body = body.is_a?(String) ? body : JSON.generate(body)
    @calls = []
  end

  def send_request(method, url, headers, body, _timeout_ms)
    @calls << { method: method, url: url, headers: headers, body: body && JSON.parse(body) }
    Iletiniz::HttpResponse.new(status: @status, body: @body, headers: {})
  end

  def routes
    @calls.map { |c| "#{c[:method]} #{c[:url]}" }
  end
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.before do
    # Yeniden deneme beklemelerini atla.
    allow_any_instance_of(Iletiniz::HttpClient).to receive(:sleep)
  end
end
