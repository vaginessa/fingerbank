require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

begin
  ENV.update YAML.load_file('config/application.yml') 
rescue => e 
  puts "Failed to import app configuration"
  puts e.message
end

module RailsFingerbank
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    Sunspot.config.pagination.default_per_page = 15

    config.autoload_paths += Dir["#{config.root}/app/sweepers/**/"]

    config.matching_discoverers = nil
    config.instance_cache = {}

    config.action_mailer.raise_delivery_errors = true

    config.action_mailer.delivery_method = :smtp

    config.action_mailer.smtp_settings = {
      address:              ENV["SMTP_HOST"],
      port:                 ENV["SMTP_PORT"].to_i,
      domain:               ENV["SMTP_DOMAIN"], 
      enable_starttls_auto: true, 
      openssl_verify_mode: 'none',
    }

    if ENV["SMTP_AUTH"]
      config.action_mailer.smtp_settings["user_name"] = ENV["SMTP_USERNAME"]
      config.action_mailer.smtp_settings["password"] = ENV["SMTP_PASSWORD"]
      config.action_mailer.smtp_settings["authentication"] = ENV["SMTP_AUTH"]
    end

    #puts config.action_mailer.smtp_settings.inspect
    
    config.help = YAML.load_file('config/help.yml')

  end
end
