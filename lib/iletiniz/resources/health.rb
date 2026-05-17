# frozen_string_literal: true

module Iletiniz
  module Resources
    # `/v1/health` endpoint'i.
    class Health
      def initialize(http)
        @http = http
      end

      # API ve veritabaninin erisilebilirligini kontrol eder.
      #
      # @param options [RequestOptions, nil]
      # @return [Hash]
      def check(options: nil)
        @http.request("GET", "/v1/health", options: options)
      end
    end
  end
end
