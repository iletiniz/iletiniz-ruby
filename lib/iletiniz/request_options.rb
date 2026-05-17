# frozen_string_literal: true

module Iletiniz
  # Istek bazli opsiyonlar.
  class RequestOptions
    # @return [Integer, nil] istege ozel timeout (ms)
    attr_reader :timeout_ms
    # @return [Hash{String => String}, nil] istege ek HTTP basliklari
    attr_reader :headers

    def initialize(timeout_ms: nil, headers: nil)
      @timeout_ms = timeout_ms
      @headers = headers
    end
  end
end
