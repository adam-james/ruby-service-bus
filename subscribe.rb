require 'dotenv/load'
require 'azure'

sub_number = ARGV[0]
fail 'No subscription number given. Try `ruby subscribe.rb 1`.' if not sub_number

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
subscription_name = "test-subscription-#{sub_number}"
puts subscription_name
subscription = Azure::ServiceBus::Subscription.new(subscription_name)
subscription.topic = topic1.name

begin
  subscription = service_bus.create_subscription(subscription)
rescue Azure::Core::Http::HTTPError => exception
  subscription = service_bus.get_subscription(subscription)
end

# SUBSCRIBE

def receive_subscription_message(service_bus, topic, subscription)
  service_bus.receive_subscription_message(topic.name, subscription.name)
rescue Faraday::TimeoutError => error
  puts 'retry'
  receive_subscription_message(service_bus, topic, subscription)
end

while true
  # Receive a subscription message
  message = receive_subscription_message(service_bus, topic1, subscription)
  puts message.body
  # Delete a subscription message
  service_bus.delete_subscription_message(message)
end
