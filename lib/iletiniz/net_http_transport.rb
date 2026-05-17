# frozen_string_literal: true

require "net/http"
require "uri"

module Iletiniz
  # `Net::HTTP` uzerine kurulu varsayilan transport.
  #
  # Ozel transport'lar `send_request(method, url, headers, body, timeout_ms)` metodu
  # uygulayan herhangi bir nesne olabilir (duck typing).
  class NetHttpTransport
    # @param method [String]
    # @param url [String]
    # @param headers [Hash{String => String}]
    # @param body [String, nil]
    # @param timeout_ms [Integer]
    # @return [HttpResponse]
    # @raise [TimeoutError] istek timeout suresinde tamamlanamadiysa
    # @raise [ConnectionError] diger ag hatalari
    def send_request(method, url, headers, body, timeout_ms)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout_ms / 1000.0
      http.read_timeout = timeout_ms / 1000.0
      http.write_timeout = timeout_ms / 1000.0 if http.respond_to?(:write_timeout=)

      request_class = method_class(method)
      path = uri.request_uri
      request = request_class.new(path)
      headers.each { |name, value| request[name] = value }
      request.body = body if body

      response = http.request(request)

      response_headers = {}
      response.each_header { |name, value| response_headers[name] = value }

      HttpResponse.new(
        status: response.code.to_i,
        body: response.body || "",
        headers: response_headers
      )
    rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout => e
      raise TimeoutError, "Istek #{timeout_ms}ms icinde tamamlanamadi: #{e.message}"
    rescue SocketError, IOError, Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Errno::ENETUNREACH, OpenSSL::SSL::SSLError => e
      raise ConnectionError.new(e.message, cause: e)
    end

    private

    def method_class(method)
      case method.to_s.upcase
      when "GET" then Net::HTTP::Get
      when "POST" then Net::HTTP::Post
      when "PUT" then Net::HTTP::Put
      when "PATCH" then Net::HTTP::Patch
      when "DELETE" then Net::HTTP::Delete
      when "HEAD" then Net::HTTP::Head
      else
        raise ArgumentError, "Desteklenmeyen HTTP method: #{method}"
      end
    end
  end
end
