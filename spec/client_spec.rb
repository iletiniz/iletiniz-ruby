# frozen_string_literal: true

require "spec_helper"

BASE = "https://api.iletiniz.com"

RSpec.describe Iletiniz::Client do
  def make(status: 200, body: {})
    transport = FakeTransport.new(status: status, body: body)
    [described_class.new(api_key: "iltz_test_abc", transport: transport, max_retries: 2), transport]
  end

  it "User-Agent surumu 0.2.0" do
    client, t = make(body: { ok: true, db: "up" })
    client.health.check
    expect(t.calls[0][:headers]["User-Agent"]).to eq("iletiniz-ruby/0.2.0")
  end

  describe "messages" do
    it "whatsapp_template, sender ve scheduled_at govdeye yazilir" do
      client, t = make(status: 201, body: { scheduled_id: 7, status: "scheduled" })
      res = client.messages.send(
        to: "+905551234567",
        provider: "whatsapp",
        sender: "123456789012345",
        whatsapp_template: {
          name: "randevu_hatirlatma",
          language: "tr",
          components: [{ type: "body", parameters: [{ type: "text", text: "Ayşe" }] }]
        },
        scheduled_at: Time.new(2026, 11, 5, 9, 0, 0, "+03:00")
      )
      expect(res["scheduled_id"]).to eq(7)
      body = t.calls[0][:body]
      expect(t.calls[0][:url]).to eq("#{BASE}/v1/messages")
      expect(body["scheduledAt"]).to eq("2026-11-05T09:00:00+03:00")
      expect(body["sender"]).to eq("123456789012345")
      expect(body["whatsappTemplate"]["name"]).to eq("randevu_hatirlatma")
    end

    it "body ile whatsapp_template birlikte reddedilir" do
      client, = make
      expect do
        client.messages.send(to: "+905551234567", body: "x", whatsapp_template: { name: "a", language: "tr" })
      end.to raise_error(Iletiniz::Error)
    end

    it "bulk whatsappComponents yalniz whatsapp_template ile" do
      client, t = make(body: { total: 1, sent: 1, failed: 0, results: [] })
      client.messages.send_bulk(
        provider: "whatsapp",
        whatsapp_template: { name: "kargo", language: "tr" },
        items: [{ to: "+905551234567",
                  whatsappComponents: [{ type: "body", parameters: [{ type: "text", text: "TR1" }] }] }]
      )
      expect(t.calls[0][:url]).to eq("#{BASE}/v1/messages/bulk")
      expect(t.calls[0][:body]["items"][0]["whatsappComponents"][0]["type"]).to eq("body")

      expect do
        client.messages.send_bulk(items: [{ to: "+905551234567", body: "x", whatsappComponents: [] }])
      end.to raise_error(Iletiniz::Error)
      expect do
        client.messages.send_bulk(whatsapp_template: { name: "k", language: "tr" },
                                  items: [{ to: "+905551234567", body: "x" }])
      end.to raise_error(Iletiniz::Error)
    end
  end

  describe "scheduled" do
    it "list/retrieve/cancel yollari" do
      client, t = make(body: { data: [], limit: 10, offset: 0 })
      client.scheduled.list(status: "scheduled", limit: 10)
      client.scheduled.retrieve(5)
      client.scheduled.cancel(5)
      expect(t.routes).to eq([
                               "GET #{BASE}/v1/scheduled?status=scheduled&limit=10",
                               "GET #{BASE}/v1/scheduled/5",
                               "DELETE #{BASE}/v1/scheduled/5"
                             ])
      expect { client.scheduled.cancel(0) }.to raise_error(Iletiniz::Error)
    end
  end

  describe "reminders" do
    it "CRUD yollari ve tarih serilestirme" do
      client, t = make(body: { id: 3 })
      client.reminders.create(
        type: "one_time",
        name: "Randevu",
        eventAt: Time.utc(2026, 11, 10, 11, 0, 0),
        offsetsMinutes: [1440, 120],
        message: { to: "+905551234567", body: "Merhaba" }
      )
      client.reminders.list(status: "active")
      client.reminders.retrieve(3)
      client.reminders.update(3, { status: "paused" })
      client.reminders.update(3, {}, clear_ends_at: true)
      client.reminders.delete(3)
      expect(t.routes).to eq([
                               "POST #{BASE}/v1/reminders",
                               "GET #{BASE}/v1/reminders?status=active",
                               "GET #{BASE}/v1/reminders/3",
                               "PATCH #{BASE}/v1/reminders/3",
                               "PATCH #{BASE}/v1/reminders/3",
                               "DELETE #{BASE}/v1/reminders/3"
                             ])
      expect(t.calls[0][:body]["eventAt"]).to eq("2026-11-10T11:00:00Z")
      expect(t.calls[4][:body]).to eq({ "endsAt" => nil })
    end

    it "haftalik kuralda dayOfWeek zorunlu, bos guncelleme reddedilir" do
      client, = make
      expect do
        client.reminders.create(type: "recurring", name: "x", frequency: "weekly", timeOfDay: "09:30",
                                message: { to: "+905551234567", body: "y" })
      end.to raise_error(Iletiniz::Error)
      expect { client.reminders.update(3, {}) }.to raise_error(Iletiniz::Error)
    end
  end

  describe "partner" do
    it "tum yollar" do
      client, t = make
      client.partner.profile
      client.partner.create_account(name: "Klinik A", external_ref: "k-1")
      client.partner.list_accounts(status: "suspended", offset: 50)
      client.partner.retrieve_account(12)
      client.partner.suspend_account(12)
      client.partner.unsuspend_account(12)
      client.partner.create_api_key(12, name: "prod", test: true)
      client.partner.transfer_quota(12, 500)
      client.partner.create_whatsapp_signup_link(12)
      expect(t.routes).to eq([
                               "GET #{BASE}/v1/partner",
                               "POST #{BASE}/v1/partner/accounts",
                               "GET #{BASE}/v1/partner/accounts?status=suspended&offset=50",
                               "GET #{BASE}/v1/partner/accounts/12",
                               "POST #{BASE}/v1/partner/accounts/12/suspend",
                               "POST #{BASE}/v1/partner/accounts/12/unsuspend",
                               "POST #{BASE}/v1/partner/accounts/12/api-keys",
                               "POST #{BASE}/v1/partner/accounts/12/quota-transfers",
                               "POST #{BASE}/v1/partner/accounts/12/whatsapp-signup"
                             ])
      expect(t.calls[1][:body]).to eq({ "name" => "Klinik A", "externalRef" => "k-1" })
      expect(t.calls[7][:body]).to eq({ "amount" => 500 })
      expect { client.partner.transfer_quota(12, 0) }.to raise_error(Iletiniz::Error)
    end

    it "alt hesap API anahtarlarini listeler ve iptal eder" do
      key = {
        id: 7, name: "prod", key_prefix: "iltz_live_Ab", scopes: ["messages:send"], sandbox: false,
        source: "partner", status: "active", created_at: "2026-10-31T10:00:00.000Z",
        last_used_at: nil, revoked_at: nil
      }
      client, t = make(body: { data: [key] })
      res = client.partner.list_api_keys(12)
      expect(res["data"][0]["key_prefix"]).to eq("iltz_live_Ab")
      expect(t.routes).to eq(["GET #{BASE}/v1/partner/accounts/12/api-keys"])

      client, t = make(body: key.merge(status: "revoked", revoked_at: "2026-10-31T11:00:00.000Z"))
      expect(client.partner.revoke_api_key(12, 7)["status"]).to eq("revoked")
      expect(t.routes).to eq(["DELETE #{BASE}/v1/partner/accounts/12/api-keys/7"])
      expect { client.partner.revoke_api_key(12, 0) }.to raise_error(Iletiniz::Error)
    end

    it "transfer_quota 503'te yeniden denenmez ve domain hatasi cozulur" do
      client, t = make(status: 503, body: { error: { code: "billing_unavailable", message: "Gecici hata." } })
      expect { client.partner.transfer_quota(12, 500) }.to raise_error(Iletiniz::ServerError) { |e|
        expect(e.code).to eq("billing_unavailable")
        expect(e.message).to eq("Gecici hata.")
      }
      expect(t.calls.length).to eq(1)
    end
  end

  describe "hata zarfi" do
    it "GET 503'te yeniden denenir" do
      client, t = make(status: 503, body: { error: { code: "x", message: "y" } })
      expect { client.scheduled.list }.to raise_error(Iletiniz::ServerError)
      expect(t.calls.length).to eq(3)
    end

    it "duz dogrulama zarfi" do
      client, = make(status: 400, body: { error: "validation_failed", message: "Gecersiz istek govdesi" })
      expect { client.reminders.retrieve(1) }.to raise_error(Iletiniz::ValidationError) { |e|
        expect(e.code).to eq("validation_failed")
        expect(e.message).to eq("Gecersiz istek govdesi")
      }
    end

    it "404 domain zarfi" do
      client, = make(status: 404, body: { error: { code: "child_not_found", message: "Yok." } })
      expect { client.partner.retrieve_account(9) }.to raise_error(Iletiniz::NotFoundError) { |e|
        expect(e.code).to eq("child_not_found")
      }
    end
  end
end
