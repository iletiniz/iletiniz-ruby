# Changelog / Değişiklik Günlüğü

Bu projedeki önemli değişiklikler bu dosyada belgelenir.
All notable changes to this project will be documented in this file.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
Sürümleme / Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Added
- `client.partner.list_api_keys(id)` ve `client.partner.revoke_api_key(id, key_id)`: alt hesabın API anahtarlarını listeleme ve iptal etme.

## [0.2.0] - 2026-10-31

### Eklenenler / Added
- `messages.send` / `send_bulk`: `whatsapp_template:` (Meta onaylı şablon), bulk `items[].whatsappComponents`, `scheduled_at:` (dize veya Time); WhatsApp için `sender:` = `phone_number_id`.
- `client.scheduled` (list/retrieve/cancel), `client.reminders` (create/list/retrieve/update/delete), `client.partner` (alt hesap, anahtar, kota aktarma, WhatsApp bağlantı linki).
- `spec/` altında rspec testleri (sahte transport).

### Düzeltmeler / Fixed
- API domain hata zarfı `{"error": {"code", "message"}}` artık çözülüyor; `code` ve mesaj doğru geliyor.

### Değişenler / Changed
- Partner kota aktarımı, alt hesap ve anahtar oluşturma istekleri yeniden denenmez.

## [0.1.0] - 2026-05-12

### Eklenenler / Added
- Açık kaynak proje hijyen dosyaları: LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY
- İki dilli dokümantasyon (Türkçe + English)
- İlk açık kaynak yayını / Initial open-source release
