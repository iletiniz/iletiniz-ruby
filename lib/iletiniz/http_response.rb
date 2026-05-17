# frozen_string_literal: true

module Iletiniz
  # Transport tarafindan donen ham HTTP yaniti.
  class HttpResponse
    # @return [Integer]
    attr_reader :status
    # @return [String]
    attr_reader :body
    # @return [Hash{String => String}] kucuk-harfe normalize edilmis basliklar
    attr_reader :headers

    def initialize(status:, body:, headers: {})
      @status = status
      @body = body || ""
      @headers = (headers || {}).each_with_object({}) do |(k, v), out|
        out[k.to_s.downcase] = v.to_s if k
      end
    end

    # @param name [String]
    # @return [String, nil]
    def header(name)
      headers[name.to_s.downcase]
    end
  end
end
