require 'dotenv/load'
require 'azure'

SB_NAMESPACE = ENV['SB_NAMESPACE']
SB_SAS_KEY_NAME = ENV['SB_SAS_KEY_NAME']
SB_SAS_KEY = ENV['SB_SAS_KEY']

Azure.configure do |config|
  config.sb_namespace = SB_NAMESPACE
  config.sb_sas_key_name = SB_SAS_KEY_NAME
  config.sb_sas_key = SB_SAS_KEY
end
signer = Azure::ServiceBus::Auth::SharedAccessSigner.new
sb_host = "https://#{Azure.sb_namespace}.servicebus.windows.net"

azure_service_bus_service = Azure::ServiceBus::ServiceBusService.new(sb_host, { signer: signer })

while true
  message = azure_service_bus_service.receive_queue_message("test-queue")
  puts message.body
  azure_service_bus_service.delete_queue_message(message)
end
