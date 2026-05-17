# frozen_string_literal: true

require_relative "iletiniz/version"
require_relative "iletiniz/errors"
require_relative "iletiniz/request_options"
require_relative "iletiniz/http_response"
require_relative "iletiniz/net_http_transport"
require_relative "iletiniz/http_client"
require_relative "iletiniz/resources/messages"
require_relative "iletiniz/resources/health"
require_relative "iletiniz/client"

# Iletiniz API resmi Ruby SDK'si.
#
# Hizli baslangic:
#
#   client = Iletiniz::Client.new(api_key: ENV["ILETINIZ_API_KEY"])
#   res = client.messages.send(to: "+905551234567", body: "Merhaba!")
module Iletiniz
end
