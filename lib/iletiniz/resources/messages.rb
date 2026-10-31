# frozen_string_literal: true

require "uri"

module Iletiniz
  module Resources
    # `/v1/messages` endpoint ailesi.
    class Messages
      MAX_BULK_ITEMS = 200

      def initialize(http)
        @http = http
      end

      # Tek bir SMS mesaji gonderir.
      #
      # `body` veya `template` alanlarindan **tam olarak biri** verilmelidir.
      # `variables` yalnizca `template` ile birlikte kullanilabilir.
      #
      # @param to [String] Alici telefon numarasi (E.164 onerilir; 05551234567, 5551234567 ve 905551234567 gibi Turkiye yerel bicimleri de kabul edilir)
      # @param body [String, nil] Duz metin govde
      # @param template [String, nil] Template anahtari
      # @param variables [Hash, nil] Yalnizca template ile birlikte kullanilabilir
      # @param whatsapp_template [Hash, nil] Meta onayli WhatsApp sablonu:
      #   { name:, language:, components: [...] } (components Meta Cloud API bicimi).
      #   body/template ile birlikte kullanilamaz.
      # @param sender [String, nil] SMS: gonderici basligi. WhatsApp: Meta phone_number_id
      # @param provider [String, nil] Belirli bir provider secimi
      # @param scheduled_at [String, Time, nil] Ileri tarihli gonderim (saat dilimli ISO 8601).
      #   Verilirse yanit scheduled_id icerir.
      # @param iys [Boolean, nil] IYS izni. true => ticari (sağlayıcının IYS filtresi
      #   devreye girer); false/nil => bilgilendirme (IYS sorgusu yok). Yalnızca SMS
      #   sağlayıcılarında işlenir; WhatsApp/Telegram için yok sayılır.
      # @param options [RequestOptions, nil]
      # @return [Hash]
      def send(to:, body: nil, template: nil, variables: nil, whatsapp_template: nil, sender: nil, provider: nil,
               iys: nil, scheduled_at: nil, options: nil)
        params = { to: to, body: body, template: template, variables: variables, whatsappTemplate: whatsapp_template,
                   sender: sender, provider: provider, iys: iys, scheduledAt: iso_time(scheduled_at) }
        validate_send!(params)
        @http.request("POST", "/v1/messages", body: strip_nil(params), options: options)
      end

      # Tek istekte birden fazla mesaj gonderir (en fazla 200 oge).
      #
      # @param items [Array<Hash>] :to (zorunlu), :body, :variables, :whatsappComponents anahtarlarini destekler
      # @param template [String, nil]
      # @param whatsapp_template [Hash, nil] bkz. {#send}; components tum alicilar icin varsayilan
      # @param scheduled_at [String, Time, nil] bkz. {#send}
      # @param sender [String, nil]
      # @param provider [String, nil]
      # @param iys [Boolean, nil] IYS izni — bkz. {#send}. Tüm batch için tek deger.
      # @param options [RequestOptions, nil]
      # @return [Hash]
      def send_bulk(items:, template: nil, whatsapp_template: nil, sender: nil, provider: nil, iys: nil,
                    scheduled_at: nil, options: nil)
        params = { provider: provider, sender: sender, template: template, whatsappTemplate: whatsapp_template,
                   iys: iys, scheduledAt: iso_time(scheduled_at), items: items }
        validate_bulk!(params)

        cleaned_items = items.map { |item| strip_nil(item) }
        body = strip_nil(params).merge(items: cleaned_items)
        @http.request("POST", "/v1/messages/bulk", body: body, options: options)
      end

      # Daha once gonderilmis bir mesajin guncel durumunu doner.
      #
      # @param job_id [String]
      # @param options [RequestOptions, nil]
      # @return [Hash]
      def retrieve(job_id, options: nil)
        raise Error, "job_id bos olamaz." if job_id.nil? || job_id.to_s.empty?

        path = "/v1/messages/#{URI.encode_www_form_component(job_id.to_s)}"
        @http.request("GET", path, options: options)
      end

      # `retrieve` icin alias.
      def status(job_id, options: nil)
        retrieve(job_id, options: options)
      end

      private

      def validate_send!(params)
        to = params[:to]
        unless to.is_a?(String) && (7..32).cover?(to.length)
          raise Error, "'to' alani 7-32 karakter arasinda olmalidir."
        end

        has_body = params[:body].is_a?(String) && !params[:body].empty?
        has_template = params[:template].is_a?(String) && !params[:template].empty?

        has_wa = !params[:whatsappTemplate].nil?
        if [has_body, has_template, has_wa].count(true) != 1
          raise Error, "'body', 'template' veya 'whatsappTemplate' alanlarindan tam olarak biri zorunludur."
        end

        if !params[:variables].nil? && !has_template
          raise Error, "'variables' yalnizca 'template' ile birlikte kullanilabilir."
        end

        if has_body
          len = params[:body].length
          unless (1..1600).cover?(len)
            raise Error, "'body' 1-1600 karakter arasinda olmalidir."
          end
        end
      end

      def validate_bulk!(params)
        items = params[:items]
        unless items.is_a?(Array) && !items.empty?
          raise Error, "'items' en az bir oge icermelidir."
        end

        if items.length > MAX_BULK_ITEMS
          raise Error, "'items' en fazla #{MAX_BULK_ITEMS} oge icerebilir."
        end

        using_template = params[:template].is_a?(String) && !params[:template].empty?
        using_wa = !params[:whatsappTemplate].nil?
        raise Error, "'template' ve 'whatsappTemplate' birlikte kullanilamaz." if using_template && using_wa

        items.each_with_index do |item, i|
          raise Error, "items[#{i}] bir Hash olmalidir." unless item.is_a?(Hash)

          to = item[:to] || item["to"]
          unless to.is_a?(String) && (7..32).cover?(to.length)
            raise Error, "items[#{i}].to 7-32 karakter arasinda olmalidir."
          end

          has_body_key = item.key?(:body) || item.key?("body")
          has_vars_key = item.key?(:variables) || item.key?("variables")

          has_wa_key = item.key?(:whatsappComponents) || item.key?("whatsappComponents")
          if has_wa_key && !using_wa
            raise Error, "items[#{i}].whatsappComponents yalnizca 'whatsappTemplate' ile kullanilabilir."
          end

          if using_wa
            if has_body_key || has_vars_key
              raise Error, "'whatsappTemplate' verildi: items[#{i}].body ve variables kullanilamaz."
            end
          elsif using_template
            if has_body_key
              raise Error, "Ust seviye 'template' verildi: items[#{i}].body kullanilamaz."
            end
          else
            body_val = item[:body] || item["body"]
            unless body_val.is_a?(String) && !body_val.empty?
              raise Error, "'template' yok: items[#{i}].body zorunludur."
            end
            if has_vars_key
              raise Error, "'template' yok: items[#{i}].variables kullanilamaz."
            end
          end
        end
      end

      def iso_time(value)
        value.respond_to?(:iso8601) ? value.iso8601 : value
      end

      def strip_nil(hash)
        hash.reject { |_k, v| v.nil? }
      end
    end
  end
end
