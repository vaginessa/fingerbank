Apipie.configure do |config|
  config.app_name                = "Fingerbank"
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/api_doc"
  config.validate                = false
  config.default_version         = "1"
  config.app_info                = "All requests to the fingerbank API need to contain your API key in the URL parameters. You can find your key and regenerate it by accessing your account."
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/**/*.rb"
end
