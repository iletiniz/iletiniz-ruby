# frozen_string_literal: true

module Iletiniz
  # Tum SDK hatalarinin taban sinifi.
  class Error < StandardError; end

  # API tarafindan donen HTTP hatasi.
  class APIError < Error
    # @return [Integer] HTTP status kodu
    attr_reader :status
    # @return [String, nil] API tarafindan donen makine-okunur hata kodu
    attr_reader :code
    # @return [Hash, String, nil] API tarafindan donen ham govde
    attr_reader :body
    # @return [String, nil] Sunucu tarafinda uretilen istek kimligi
    attr_reader :request_id

    def initialize(message, status:, code: nil, body: nil, request_id: nil)
      super(message)
      @status = status
      @code = code
      @body = body
      @request_id = request_id
    end
  end

  # 401 - gecersiz veya iptal edilmis API anahtari.
  class AuthenticationError < APIError; end

  # 403 - yetki yok.
  class PermissionError < APIError; end

  # 400 / 422 - istek dogrulanamadi.
  class ValidationError < APIError; end

  # 429 - istek hiz limitini asti.
  class RateLimitError < APIError; end

  # 404.
  class NotFoundError < APIError; end

  # 5xx.
  class ServerError < APIError; end

  # Ag kaynakli baglanti hatasi.
  class ConnectionError < Error
    # @return [Exception, nil] Asil neden (varsa)
    attr_reader :cause_error

    def initialize(message, cause: nil)
      super(message)
      @cause_error = cause
    end
  end

  # Istek timeout suresinde tamamlanamadi.
  class TimeoutError < Error; end

  # @api private
  module ErrorFactory
    # HTTP status'a gore uygun APIError alt sinifini uretir.
    #
    # @param status [Integer]
    # @param body [Hash, String, nil]
    # @param request_id [String, nil]
    # @return [APIError]
    def self.build(status, body, request_id)
      code = nil
      message = nil

      case body
      when Hash
        code = body["error"] if body["error"].is_a?(String)
        message = body["message"] if body["message"].is_a?(String)
      when String
        message = body unless body.empty?
      end

      message = "HTTP #{status}" if message.nil? || message.empty?

      params = { status: status, code: code, body: body, request_id: request_id }

      case status
      when 401 then AuthenticationError.new(message, **params)
      when 403 then PermissionError.new(message, **params)
      when 404 then NotFoundError.new(message, **params)
      when 400, 422 then ValidationError.new(message, **params)
      when 429 then RateLimitError.new(message, **params)
      else
        if status >= 500
          ServerError.new(message, **params)
        else
          APIError.new(message, **params)
        end
      end
    end
  end
end
