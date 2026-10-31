# frozen_string_literal: true

module Iletiniz
  module Resources
    # @api private
    module Util
      module_function

      # nil alanlari atar, ust seviyedeki Time/DateTime/Date degerlerini ISO 8601'e cevirir.
      def prepare(hash)
        (hash || {}).each_with_object({}) do |(k, v), out|
          next if v.nil?

          out[k] = v.respond_to?(:iso8601) ? v.iso8601 : v
        end
      end

      def assert_id!(id, label = "id")
        raise Error, "#{label} pozitif tam sayi olmalidir." unless id.is_a?(Integer) && id.positive?
      end

      def list_query(params)
        return nil if params.nil? || params.empty?

        p = params.transform_keys(&:to_sym)
        { status: p[:status], limit: p[:limit], offset: p[:offset] }
      end
    end
  end
end
