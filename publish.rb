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

service_bus = Azure::ServiceBus::ServiceBusService.new(sb_host, { signer: signer })

# Create a topic with just the topic name
begin
  topic1 = service_bus.create_topic("test-topic-1")
rescue Azure::Core::Http::HTTPError => exception
  topic1 = service_bus.get_topic("test-topic-1")
end

# Create a subscription
subscription = Azure::ServiceBus::Subscription.new("test-subscription-1")
subscription.topic = topic1.name

begin
  subscription = service_bus.create_subscription(subscription)
rescue Azure::Core::Http::HTTPError => exception
  subscription = service_bus.get_subscription(subscription)
end

# PUBLISH

# Send a topic message with a brokered message object
message = Azure::ServiceBus::BrokeredMessage.new({ 'message' => 'test message' }.to_json)
# TODO use correlation id to make sure messages aren't processed twice
# message.correlation_id = "test-correlation-id-1"
service_bus.send_topic_message(topic1, message)
