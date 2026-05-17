# frozen_string_literal: true

require "json"

module Iletiniz
  # @api private
  #
  # Yuksek seviye HTTP istemcisi: retry, backoff, JSON encode/decode, hata haritalama.
  class HttpClient
    RETRYABLE_STATUSES = [408, 429].freeze

    def initialize(base_url:, api_key:, timeout_ms:, max_retries:, default_headers:, transport:)
      @base_url = base_url.to_s.sub(%r{/+\z}, "")
      @api_key = api_key
      @timeout_ms = timeout_ms
      @max_retries = max_retries
      @default_headers = default_headers || {}
      @transport = transport
    end

    # @param method [String]
    # @param path [String]
    # @param query [Hash, nil]
    # @param body [Object, nil]
    # @param options [RequestOptions, nil]
    # @return [Hash, Array, nil] decoded JSON
    def request(method, path, query: nil, body: nil, options: nil)
      url = build_url(path, query)

      headers = @default_headers.dup
      headers["Authorization"] = "Bearer #{@api_key}"
      headers["Accept"] = "application/json"
      options&.headers&.each { |k, v| headers[k] = v }

      payload = nil
      if body
        headers["Content-Type"] = "application/json"
        payload = JSON.generate(body)
      end

      timeout_ms = options&.timeout_ms || @timeout_ms

      attempt = 0
      loop do
        response =
          begin
            @transport.send_request(method, url, headers, payload, timeout_ms)
          rescue TimeoutError, ConnectionError
            if should_retry?(nil, attempt)
              attempt += 1
              sleep(backoff_ms(attempt, nil) / 1000.0)
              next
            end
            raise
          end

        status = response.status
        if status >= 200 && status < 300
          return nil if status == 204 || response.body.empty?

          begin
            return JSON.parse(response.body)
          rescue JSON::ParserError => e
            raise ConnectionError.new("Sunucudan gecersiz JSON dondu", cause: e)
          end
        end

        if should_retry?(status, attempt)
          attempt += 1
          sleep(backoff_ms(attempt, response.header("retry-after")) / 1000.0)
          next
        end

        raise ErrorFactory.build(status, parse_error_body(response.body), response.header("x-request-id"))
      end
    end

    private

    def build_url(path, query)
      p = path.start_with?("/") ? path : "/#{path}"
      url = "#{@base_url}#{p}"
      return url unless query && !query.empty?

      params = query.reject { |_k, v| v.nil? }
      return url if params.empty?

      url + "?" + URI.encode_www_form(params)
    end

    def should_retry?(status, attempt)
      return false if attempt >= @max_retries
      return true if status.nil?
      return true if RETRYABLE_STATUSES.include?(status)

      status >= 500 && status <= 599
    end

    def backoff_ms(attempt, retry_after)
      if retry_after
        sec = Float(retry_after) rescue nil
        return [sec * 1000.0, 30_000.0].min.to_i if sec && sec.positive?
      end

      base = [(2**attempt) * 250, 4000].min
      base + rand(0..100)
    end

    def parse_error_body(raw)
      return nil if raw.nil? || raw.empty?

      JSON.parse(raw)
    rescue JSON::ParserError
      raw
    end
  end
end
