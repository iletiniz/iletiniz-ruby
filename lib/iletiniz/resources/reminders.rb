# frozen_string_literal: true

module Iletiniz
  module Resources
    # Hatirlatma kurallari (`/v1/reminders`).
    #
    # one_time:  { type: "one_time", name:, message:, eventAt:, offsetsMinutes: [1440, 120] }
    # recurring: { type: "recurring", name:, message:, frequency: "daily"|"weekly"|"monthly",
    #              timeOfDay: "09:30", dayOfWeek:, dayOfMonth:, timezone:, endsAt: }
    # message:   { to:, body: | template: + variables: | whatsappTemplate:, sender:, provider:, iys: }
    # Tarihler ISO 8601 dizesi veya Time olabilir.
    class Reminders
      def initialize(http)
        @http = http
      end

      # @param params [Hash, nil] API alan adlariyla (camelCase) kural tanimi; alanlar
      #   anahtar kelime olarak da verilebilir: create(type: "one_time", ...)
      # @return [Hash]
      def create(params = nil, options: nil, **fields)
        p = (params || {}).transform_keys(&:to_sym).merge(fields)
        unless %w[one_time recurring].include?(p[:type].to_s)
          raise Error, "'type' alani 'one_time' veya 'recurring' olmalidir."
        end

        if p[:type].to_s == "recurring"
          if p[:frequency].to_s == "weekly" && p[:dayOfWeek].nil?
            raise Error, "Haftalik tekrar icin 'dayOfWeek' zorunlu."
          end
          if p[:frequency].to_s == "monthly" && p[:dayOfMonth].nil?
            raise Error, "Aylik tekrar icin 'dayOfMonth' zorunlu."
          end
        end

        @http.request("POST", "/v1/reminders", body: Util.prepare(p), options: options)
      end

      # @param status [String, nil] active | paused | completed | canceled
      # @return [Hash]
      def list(status: nil, limit: nil, offset: nil, options: nil)
        query = Util.list_query({ status: status, limit: limit, offset: offset })
        @http.request("GET", "/v1/reminders", query: query, options: options)
      end

      # @return [Hash]
      def retrieve(id, options: nil)
        Util.assert_id!(id)
        @http.request("GET", "/v1/reminders/#{id}", options: options)
      end

      # Kurali gunceller; bekleyen gonderimler yeni ayarlarla yeniden planlanir.
      # nil degerli alanlar govdeden atilir; bitis tarihini kaldirmak icin clear_ends_at: true verin.
      # @return [Hash]
      def update(id, params, clear_ends_at: false, options: nil)
        Util.assert_id!(id)
        body = Util.prepare((params || {}).transform_keys(&:to_sym))
        body[:endsAt] = nil if clear_ends_at
        raise Error, "En az bir alan guncellenmeli." if body.empty?

        @http.request("PATCH", "/v1/reminders/#{id}", body: body, options: options)
      end

      # Kurali iptal eder (`canceled`) ve bekleyen gonderimlerini siler.
      # @return [Hash]
      def delete(id, options: nil)
        Util.assert_id!(id)
        @http.request("DELETE", "/v1/reminders/#{id}", options: options)
      end
    end
  end
end
