# frozen_string_literal: true

require "iletiniz"

client = Iletiniz::Client.new(api_key: ENV["ILETINIZ_API_KEY"])

result = client.messages.send_bulk(
  template: "low_stock_alert",
  items: [
    { to: "+905551111111", variables: { product: "Urun A", stock: 3 } },
    { to: "+905552222222", variables: { product: "Urun B", stock: 1 } }
  ]
)

puts "Toplam: #{result['total']}, Gonderilen: #{result['sent']}, Basarisiz: #{result['failed']}"
