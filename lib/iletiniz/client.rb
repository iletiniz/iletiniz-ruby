# frozen_string_literal: true

module Iletiniz
  # Iletiniz API'sine erisim saglayan ana istemci.
  #
  # @example
  #   client = Iletiniz::Client.new(api_key: ENV["ILETINIZ_API_KEY"])
  #   res = client.messages.send(to: "+905551234567", body: "Merhaba!")
  class Client
    DEFAULT_BASE_URL = "https://api.iletiniz.com"
    DEFAULT_TIMEOUT_MS = 30_000
    DEFAULT_MAX_RETRIES = 2
    API_KEY_RE = /\Ailtz_(?:live|test)_[A-Za-z0-9_-]+\z/.freeze

    # @return [Resources::Messages]
    attr_reader :messages
    # @return [Resources::Health]
    attr_reader :health

    # @param api_key [String, nil] iltz_live_... veya iltz_test_... formatinda anahtar
    # @param base_url [String, nil] varsayilan https://api.iletiniz.com
    # @param timeout_ms [Integer] varsayilan 30_000
    # @param max_retries [Integer] varsayilan 2
    # @param default_headers [Hash{String => String}, nil]
    # @param transport [#send_request, nil] test veya proxy icin ozel transport
    def initialize(api_key: nil, base_url: nil, timeout_ms: DEFAULT_TIMEOUT_MS,
                   max_retries: DEFAULT_MAX_RETRIES, default_headers: nil, transport: nil)
      resolved_key = api_key || ENV.fetch("ILETINIZ_API_KEY", nil)
      raise Error, "API anahtari gerekli. Iletiniz::Client.new(api_key: ...) veya ILETINIZ_API_KEY ortam degiskeni kullanin." if resolved_key.nil? || resolved_key.empty?
      raise Error, "Gecersiz API anahtar formati. Beklenen: 'iltz_live_...' veya 'iltz_test_...'." unless API_KEY_RE.match?(resolved_key)

      resolved_base_url = base_url || ENV.fetch("ILETINIZ_BASE_URL", nil) || DEFAULT_BASE_URL

      headers = { "User-Agent" => "iletiniz-ruby/#{Iletiniz::VERSION}" }
      headers.merge!(default_headers) if default_headers

      transport ||= NetHttpTransport.new

      http = HttpClient.new(
        base_url: resolved_base_url,
        api_key: resolved_key,
        timeout_ms: timeout_ms,
        max_retries: max_retries,
        default_headers: headers,
        transport: transport
      )

      @messages = Resources::Messages.new(http)
      @health = Resources::Health.new(http)
    end
  end
end
