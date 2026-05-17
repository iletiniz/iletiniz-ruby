# frozen_string_literal: true

require "iletiniz"

if ARGV.empty?
  warn "Kullanim: ruby status.rb <job_id>"
  exit 2
end

client = Iletiniz::Client.new(api_key: ENV["ILETINIZ_API_KEY"])

begin
  info = client.messages.retrieve(ARGV.first)
  pp info
rescue Iletiniz::NotFoundError
  warn "Mesaj bulunamadi."
  exit 1
end
