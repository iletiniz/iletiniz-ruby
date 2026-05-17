# frozen_string_literal: true

require "iletiniz"

client = Iletiniz::Client.new(api_key: ENV["ILETINIZ_API_KEY"])

result = client.messages.send(
  to: "+905551234567",
  body: "Merhaba! Bu Iletiniz SDK ile gonderilen test mesajidir."
)

puts "Job: #{result['job_id']} Status: #{result['status']}"
