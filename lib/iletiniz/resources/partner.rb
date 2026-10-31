# frozen_string_literal: true

module Iletiniz
  module Resources
    # Partner API (`/v1/partner`). Yalniz partner hesabinin `partner:manage`
    # yetkili CANLI (iltz_live_) anahtariyla calisir.
    class Partner
      def initialize(http)
        @http = http
      end

      # Partner profili: fiyatlandirma, kota bakiyesi, alt hesap sayisi.
      # @return [Hash]
      def profile(options: nil)
        @http.request("GET", "/v1/partner", options: options)
      end

      # @param name [String] alt hesap adi (2-100)
      # @param external_ref [String, nil] kendi sistemindeki musteri kimligi
      # @return [Hash]
      def create_account(name:, external_ref: nil, options: nil)
        raise Error, "'name' en az 2 karakter olmalidir." if name.to_s.strip.length < 2

        body = Util.prepare({ name: name, externalRef: external_ref })
        @http.request("POST", "/v1/partner/accounts", body: body, options: options, retryable: false)
      end

      # @param status [String, nil] active | suspended
      # @return [Hash]
      def list_accounts(status: nil, limit: nil, offset: nil, options: nil)
        query = Util.list_query({ status: status, limit: limit, offset: offset })
        @http.request("GET", "/v1/partner/accounts", query: query, options: options)
      end

      # @return [Hash]
      def retrieve_account(id, options: nil)
        Util.assert_id!(id)
        @http.request("GET", "/v1/partner/accounts/#{id}", options: options)
      end

      # @return [Hash]
      def suspend_account(id, options: nil)
        Util.assert_id!(id)
        @http.request("POST", "/v1/partner/accounts/#{id}/suspend", options: options)
      end

      # @return [Hash]
      def unsuspend_account(id, options: nil)
        Util.assert_id!(id)
        @http.request("POST", "/v1/partner/accounts/#{id}/unsuspend", options: options)
      end

      # Alt hesap icin API anahtari uretir. Duz metin "key" yalniz bu yanitta doner.
      # @param scopes [Array<String>, nil] varsayilan ["messages:send", "messages:read"]
      # @param test [Boolean, nil] true => iltz_test_ (sandbox) anahtari
      # @return [Hash]
      def create_api_key(id, name:, scopes: nil, test: nil, allowed_ips: nil, options: nil)
        Util.assert_id!(id)
        raise Error, "'name' zorunludur." if name.to_s.empty?

        body = Util.prepare({ name: name, scopes: scopes, test: test, allowedIps: allowed_ips })
        @http.request("POST", "/v1/partner/accounts/#{id}/api-keys", body: body, options: options, retryable: false)
      end

      # Alt hesabin API anahtarlarini listeler (en yeni once). Duz metin anahtar/hash donmez.
      # @return [Hash] { "data" => [ChildApiKey, ...] }
      def list_api_keys(id, options: nil)
        Util.assert_id!(id)
        @http.request("GET", "/v1/partner/accounts/#{id}/api-keys", options: options)
      end

      # Alt hesabin API anahtarini iptal eder. Idempotenttir: iptal edilmisse ayni nesne doner.
      # @return [Hash]
      def revoke_api_key(id, key_id, options: nil)
        Util.assert_id!(id)
        Util.assert_id!(key_id, "key_id")
        @http.request("DELETE", "/v1/partner/accounts/#{id}/api-keys/#{key_id}", options: options)
      end

      # Partner kotasindan alt hesaba mesaj kotasi aktarir. Yeniden denenmez (cift aktarim riski).
      # @return [Hash]
      def transfer_quota(id, amount, options: nil)
        Util.assert_id!(id)
        unless amount.is_a?(Integer) && amount.between?(1, 10_000_000)
          raise Error, "'amount' 1 ile 10.000.000 arasinda tam sayi olmalidir."
        end

        @http.request("POST", "/v1/partner/accounts/#{id}/quota-transfers",
                      body: { amount: amount }, options: options, retryable: false)
      end

      # Alt hesabin WhatsApp numarasini baglamasi icin tek kullanimlik baglanti (24 saat).
      # @return [Hash]
      def create_whatsapp_signup_link(id, options: nil)
        Util.assert_id!(id)
        @http.request("POST", "/v1/partner/accounts/#{id}/whatsapp-signup", options: options)
      end
    end
  end
end
