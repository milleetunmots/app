RSpec.configure do |config|
  config.before(:each, :rack_attack) do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  config.after(:each, :rack_attack) do
    Rack::Attack.cache.store.clear
    Rack::Attack.enabled = false
  end
end
