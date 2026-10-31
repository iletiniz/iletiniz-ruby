# Iletiniz Ruby SDK

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

Iletiniz API için resmi Ruby SDK'si. Ruby 3.0+ üzerinde çalışır, hiçbir runtime bağımlılığı yoktur (yalnızca standart kütüphane).

## Kurulum

```ruby
# Gemfile
gem "iletiniz"
```

```bash
bundle install
# veya
gem install iletiniz
```

Gereksinimler:

- Ruby `>= 3.0`

## Hızlı başlangıç

```ruby
require "iletiniz"

client = Iletiniz::Client.new(api_key: ENV["ILETINIZ_API_KEY"]) # 'iltz_live_...' veya 'iltz_test_...'

result = client.messages.send(
  to:   "+905551234567",
  body: "Merhaba!"
)

puts result["job_id"], result["status"]
```

`api_key` verilmediğinde SDK `ILETINIZ_API_KEY` ortam değişkenini okur.

## Yapılandırma

```ruby
Iletiniz::Client.new(
  api_key:        "iltz_live_...",
  base_url:       "https://api.iletiniz.com", # varsayılan
  timeout_ms:     30_000,                      # varsayılan
  max_retries:    2,                           # 408/429/5xx ve ağ hatalarında
  default_headers: { "X-Source" => "crm" },
  transport:      nil                          # özel transport (test/proxy)
)
```

## Endpoint'ler

| Metot                                         | HTTP                              |
| --------------------------------------------- | --------------------------------- |
| `client.health.check`                         | `GET /v1/health`                  |
| `client.messages.send(...)`                   | `POST /v1/messages`               |
| `client.messages.send_bulk(...)`              | `POST /v1/messages/bulk`          |
| `client.messages.retrieve(job_id)`            | `GET /v1/messages/{job_id}`       |
| `client.messages.status(job_id)` (alias)      | `GET /v1/messages/{job_id}`       |
| `client.scheduled.list(status:, limit:, offset:)` | `GET /v1/scheduled`           |
| `client.scheduled.retrieve(id)`               | `GET /v1/scheduled/{id}`          |
| `client.scheduled.cancel(id)`                 | `DELETE /v1/scheduled/{id}`       |
| `client.reminders.create(params)`             | `POST /v1/reminders`              |
| `client.reminders.list(status:, limit:, offset:)` | `GET /v1/reminders`           |
| `client.reminders.retrieve(id)`               | `GET /v1/reminders/{id}`          |
| `client.reminders.update(id, params)`         | `PATCH /v1/reminders/{id}`        |
| `client.reminders.delete(id)`                 | `DELETE /v1/reminders/{id}`       |
| `client.partner.profile`                      | `GET /v1/partner`                 |
| `client.partner.create_account(name:, external_ref:)` | `POST /v1/partner/accounts` |
| `client.partner.list_accounts(status:, limit:, offset:)` | `GET /v1/partner/accounts` |
| `client.partner.retrieve_account(id)`         | `GET /v1/partner/accounts/{id}`   |
| `client.partner.suspend_account(id)` / `unsuspend_account(id)` | `POST /v1/partner/accounts/{id}/suspend` / `unsuspend` |
| `client.partner.create_api_key(id, name:, scopes:, test:, allowed_ips:)` | `POST /v1/partner/accounts/{id}/api-keys` |
| `client.partner.list_api_keys(id)`            | `GET /v1/partner/accounts/{id}/api-keys` |
| `client.partner.revoke_api_key(id, key_id)`   | `DELETE /v1/partner/accounts/{id}/api-keys/{keyId}` |
| `client.partner.transfer_quota(id, amount)`   | `POST /v1/partner/accounts/{id}/quota-transfers` |
| `client.partner.create_whatsapp_signup_link(id)` | `POST /v1/partner/accounts/{id}/whatsapp-signup` |

### Tek mesaj göndermek

```ruby
client.messages.send(
  to:       "+905551234567",
  body:     "Sipariş kodunuz: 4821",
  sender:   "MAGAZA",     # opsiyonel
  provider: "netgsm"      # opsiyonel
)
```

### Telegram üzerinden göndermek

`provider: "telegram"` seçildiğinde `to` alanı SMS yerine Telegram alıcı tanımlayıcısı bekler:
numerik `chat_id` (örn `8409353994`, gruplar için `-1001234567890`) veya `@kullaniciadi`. `sender` Telegram için kullanılmaz — bot kimliği bağlantıdaki token'a gömülüdür.

```ruby
client.messages.send(
  to:       "8409353994",
  body:     "Merhaba!",
  provider: "telegram"
)
```

### Sağlayıcılar-arası fallback

Birincil sağlayıcı mesajı **reddederse** (hard-fail: sağlayıcı hata döner veya bağlantı kurulamaz), aynı mesaj (aynı alıcı, aynı içerik, aynı SMS kanalı) sıradaki yedek sağlayıcıyla otomatik yeniden denenir. İlk **başarıda** durur. `fallback` en fazla 3 sağlayıcı kodundan oluşan sıralı bir dizidir; hepsi müşterinin bağlı `kind: sms` sağlayıcıları olmalı ve ne birincil ile ne de birbirleriyle aynı olabilir.

```ruby
result = client.messages.send(
  to:       "+905551234567",
  body:     "Sipariş kodunuz: 4821",
  provider: "netgsm",                       # birincil
  fallback: ["verimor", "iletimerkezi"]     # sıralı yedekler (max 3)
)

# result["provider"]  → mesajı KABUL eden sağlayıcı
# result["attempts"]  → denenen her sağlayıcı + sonucu (opsiyonel)
```

> **Kota tek sayım:** Bir mantıksal mesaj, kaç sağlayıcı denenirse denensin **tek** kota harcar; hepsi başarısız olursa hiç kota harcanmaz.
>
> **Kapsam:** Yalnızca **reddte (hard-fail)** tetiklenir ve yalnızca **SMS→SMS**'tir (kanallar arası değil, örn. WhatsApp→SMS yok). "Teslim edilemedi / timeout" için otomatik fallback henüz yoktur (gelecek sürüm).

`send_bulk` yanıtında kabul eden sağlayıcı, öğe bazında `delivered_via` alanında döner.

### Template ile göndermek

```ruby
client.messages.send(
  to:        "+905551234567",
  template:  "order_shipped",
  variables: { name: "Ayşe", tracking_no: "TR123" }
)
```

`body` ve `template` aynı anda kullanılamaz; tam olarak biri zorunludur. `variables` yalnızca `template` ile birlikte verilebilir.

### Toplu gönderim

Tek istekte en fazla 200 öğe gönderebilirsiniz.

```ruby
# Düz metin modu — her item'da body zorunlu, variables yok
client.messages.send_bulk(
  items: [
    { to: "+905551111111", body: "Mesaj 1" },
    { to: "+905552222222", body: "Mesaj 2" }
  ]
)

# Template modu — items'ta body olmamalı
client.messages.send_bulk(
  template: "low_stock_alert",
  items: [
    { to: "+905551111111", variables: { product: "Ürün A", stock: 3 } },
    { to: "+905552222222", variables: { product: "Ürün B", stock: 1 } }
  ]
)
```

### Onaylı WhatsApp şablonu göndermek

Meta'da onaylanmış (APPROVED) bir şablonu `whatsapp_template:` ile gönderin. `components`, Meta Cloud API'nin `template.components` biçimini izler. `sender:`, WhatsApp'ta gönderici numaranın Meta `phone_number_id` değeridir (verilmezse bağlantının numarası kullanılır).

```ruby
res = client.messages.send(
  to: "+905551234567",
  provider: "whatsapp",
  sender: "123456789012345",
  whatsapp_template: {
    name: "randevu_hatirlatma",
    language: "tr",
    components: [
      { type: "body", parameters: [{ type: "text", text: "Ayşe" }, { type: "text", text: "5 Kasım 10:00" }] }
    ]
  }
)
puts res["whatsapp_template"] # "randevu_hatirlatma"
```

Toplu gönderimde alıcı başına değişkenleri `items[].whatsappComponents` ile verin (üst seviye `components` varsayılandır):

```ruby
client.messages.send_bulk(
  provider: "whatsapp",
  whatsapp_template: { name: "kargo_cikti", language: "tr" },
  items: [
    { to: "+905551112233", whatsappComponents: [{ type: "body", parameters: [{ type: "text", text: "TR123" }] }] },
    { to: "+905554445566", whatsappComponents: [{ type: "body", parameters: [{ type: "text", text: "TR456" }] }] }
  ]
)
```

### Zamanlanmış gönderim

`scheduled_at:` verilirse mesaj şimdi gönderilmez; yanıt `scheduled_id` içerir. Saat dilimli ISO 8601 dizesi veya `Time` kabul edilir (en az 30 sn, en fazla 90 gün sonrası).

```ruby
job = client.messages.send(
  to: "+905551234567",
  body: "Yarınki randevunuzu hatırlatırız.",
  scheduled_at: Time.new(2026, 11, 5, 9, 0, 0, "+03:00")
)

pending = client.scheduled.list(status: "scheduled")
client.scheduled.cancel(job["scheduled_id"])
```

### Hatırlatma kuralları

Kural alanları API ile aynı adlarla (camelCase) verilir:

```ruby
# Randevudan 24 saat ve 2 saat önce
client.reminders.create(
  type: "one_time",
  name: "Randevu #4411",
  eventAt: "2026-11-10T14:00:00+03:00",
  offsetsMinutes: [1440, 120],
  message: { to: "+905551234567", body: "Randevunuz 10 Kasım 14:00." }
)

# Her pazartesi 09:30 (Europe/Istanbul)
rule = client.reminders.create(
  type: "recurring",
  name: "Haftalık bülten",
  frequency: "weekly",
  dayOfWeek: 1,
  timeOfDay: "09:30",
  message: { to: "+905551234567", template: "haftalik_bulten" }
)

client.reminders.update(rule["id"], { status: "paused" })
client.reminders.update(rule["id"], {}, clear_ends_at: true) # bitiş tarihini kaldır
client.reminders.delete(rule["id"])
```

### Partner API

Partner hesabının `partner:manage` yetkili canlı anahtarıyla:

```ruby
partner = Iletiniz::Client.new(api_key: ENV.fetch("ILETINIZ_PARTNER_KEY"))

child = partner.partner.create_account(name: "Klinik Ankara", external_ref: "klinik-42")
key = partner.partner.create_api_key(child["id"], name: "prod")
# key["key"] yalnız bu yanıtta döner; güvenli şekilde saklayın.

# Alt hesabın anahtarlarını listeleyin (düz metin anahtar dönmez, yalnız key_prefix) ve gerekirse iptal edin:
keys = partner.partner.list_api_keys(child["id"])["data"]
partner.partner.revoke_api_key(child["id"], keys[0]["id"]) # idempotent: iptal edilmişse aynı nesne döner

partner.partner.transfer_quota(child["id"], 5000)
link = partner.partner.create_whatsapp_signup_link(child["id"])
# link["url"] müşterinize iletilir (24 saat geçerli, tek kullanımlık).

# Alt hesap adına gönderim, alt hesabın anahtarıyla yapılır:
child_client = Iletiniz::Client.new(api_key: key["key"])
```

`transfer_quota`, `create_account` ve `create_api_key` istekleri hata durumunda otomatik yeniden denenmez (çift aktarım/çift kayıt riskine karşı).

### Mesaj durumunu sorgulamak

```ruby
info = client.messages.retrieve(job_id)
# info["status"]: "sent" | "queued" | "failed" | "delivered" | "expired" | "rejected" | "unknown"
```

### Sağlık kontrolü

```ruby
health = client.health.check
# { "ok" => true, "db" => "up" }
```

## Hata yönetimi

Tüm hatalar `Iletiniz::Error` sınıfından türetilir. HTTP status'a göre uygun alt sınıf fırlatılır:

```ruby
begin
  client.messages.send(to: "+905551234567", body: "test")
rescue Iletiniz::AuthenticationError
  # 401 — geçersiz veya iptal edilmiş anahtar
rescue Iletiniz::ValidationError => e
  # 400 / 422
  warn e.body
rescue Iletiniz::RateLimitError
  # 429
rescue Iletiniz::NotFoundError
  # 404
rescue Iletiniz::ServerError
  # 5xx
rescue Iletiniz::APIError => e
  warn "#{e.status} #{e.code} #{e.message} [#{e.request_id}]"
rescue Iletiniz::TimeoutError
  # istek timeout'a takıldı
rescue Iletiniz::ConnectionError
  # ağ hatası
end
```

## Yeniden deneme stratejisi

SDK, aşağıdaki durumlarda otomatik olarak `max_retries` defa yeniden dener (varsayılan: 2):

- Ağ kaynaklı bağlantı hataları
- HTTP 408, 429, 500–599

`Retry-After` başlığı varsa beklenir; aksi halde exponential backoff (jitter ile) uygulanır. Yeniden denemeyi kapatmak için `max_retries: 0` verin.

## Timeout

İstek bazlı timeout:

```ruby
options = Iletiniz::RequestOptions.new(timeout_ms: 10_000)
client.messages.send(to: "+905551234567", body: "merhaba", options: options)
```

## Test

SDK, transport'u dışarı açar (duck typing: `send_request(method, url, headers, body, timeout_ms)` metodunu uygulayan herhangi bir nesne). Testlerinizde gerçek ağ trafiği oluşturmadan SDK'yı kullanabilirsiniz:

```ruby
class FakeTransport
  def send_request(method, url, headers, body, timeout_ms)
    Iletiniz::HttpResponse.new(status: 200, body: '{"ok":true,"db":"up"}', headers: {})
  end
end

client = Iletiniz::Client.new(api_key: "iltz_test_xxx", transport: FakeTransport.new)
```

SDK'nın kendi testleri: `bundle exec rspec` (veya `rspec`).

## Katkıda Bulunma / Contributing

Katkı sağlamak ister misiniz? Lütfen [CONTRIBUTING.md](./CONTRIBUTING.md) dosyasını inceleyin. English: [CONTRIBUTING.en.md](./CONTRIBUTING.en.md).

## Davranış Kuralları / Code of Conduct

Bu proje [Contributor Covenant](./CODE_OF_CONDUCT.md) davranış kurallarına bağlıdır. English: [CODE_OF_CONDUCT.en.md](./CODE_OF_CONDUCT.en.md).

## Güvenlik / Security

Güvenlik açığı bildirmek için lütfen [SECURITY.md](./SECURITY.md) dosyasındaki adımları izleyin — **public issue açmayın**. English: [SECURITY.en.md](./SECURITY.en.md).

## Lisans / License

MIT — bkz. / see [LICENSE](./LICENSE).
