require "../src/oauth-device-flow"

# Set BASE_URL and CLIENT_ID in your env. CLIENT_ID is the Doorkeeper application UID
# of a non-confidential app on the rightdocuments instance.
base_url = ENV["BASE_URL"]? || "http://localhost:3000"
client_id = ENV["CLIENT_ID"]? || abort "Set CLIENT_ID env var"

store = OAuth::DeviceFlow::MemoryStore.new
client = OAuth::DeviceFlow::Client.new(
  base_url: base_url,
  client_id: client_id,
  store: store,
)

puts "Authenticating against #{base_url}..."
client.authenticate(scope: "documents:read documents:write")
puts "Got token. Calling /api/v1/me..."

res = HTTP::Client.get(
  "#{base_url}/api/v1/me",
  headers: HTTP::Headers{"Authorization" => "Bearer #{client.access_token}"},
)
puts "HTTP #{res.status_code}"
puts res.body
