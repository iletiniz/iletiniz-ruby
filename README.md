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

## Katkıda Bulunma / Contributing

Katkı sağlamak ister misiniz? Lütfen [CONTRIBUTING.md](./CONTRIBUTING.md) dosyasını inceleyin. English: [CONTRIBUTING.en.md](./CONTRIBUTING.en.md).

## Davranış Kuralları / Code of Conduct

Bu proje [Contributor Covenant](./CODE_OF_CONDUCT.md) davranış kurallarına bağlıdır. English: [CODE_OF_CONDUCT.en.md](./CODE_OF_CONDUCT.en.md).

## Güvenlik / Security

Güvenlik açığı bildirmek için lütfen [SECURITY.md](./SECURITY.md) dosyasındaki adımları izleyin — **public issue açmayın**. English: [SECURITY.en.md](./SECURITY.en.md).

## Lisans / License

MIT — bkz. / see [LICENSE](./LICENSE).
