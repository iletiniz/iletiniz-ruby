# frozen_string_literal: true

module Iletiniz
  module Resources
    # `scheduledAt` ile olusturulan ileri tarihli gonderimler (`/v1/scheduled`).
    class Scheduled
      def initialize(http)
        @http = http
      end

      # @param status [String, nil] scheduled | processing | sent | failed | canceled
      # @param limit [Integer, nil] 1-100, varsayilan 50
      # @param offset [Integer, nil]
      # @return [Hash] { "data" => [...], "limit" => .., "offset" => .. }
      def list(status: nil, limit: nil, offset: nil, options: nil)
        query = Util.list_query({ status: status, limit: limit, offset: offset })
        @http.request("GET", "/v1/scheduled", query: query, options: options)
      end

      # @return [Hash]
      def retrieve(id, options: nil)
        Util.assert_id!(id)
        @http.request("GET", "/v1/scheduled/#{id}", options: options)
      end

      # Bekleyen (`scheduled`) gonderimi iptal eder; aksi halde 409 `not_cancelable`.
      # @return [Hash]
      def cancel(id, options: nil)
        Util.assert_id!(id)
        @http.request("DELETE", "/v1/scheduled/#{id}", options: options)
      end
    end
  end
end
