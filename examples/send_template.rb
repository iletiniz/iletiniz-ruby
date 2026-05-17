# frozen_string_literal: true

require "iletiniz"

client = Iletiniz::Client.new(api_key: ENV["ILETINIZ_API_KEY"])

result = client.messages.send(
  to: "+905551234567",
  template: "order_shipped",
  variables: { name: "Ayse", tracking_no: "TR123456789" }
)

puts "Sent via template: #{result['template_key']} -> #{result['status']}"
