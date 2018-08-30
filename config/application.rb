require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TwilioApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/services)
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.before_initialize do
      puts "rails encrypted credentials loaded ========="
      secret =  HashWithIndifferentAccess.new(YAML.load(File.read(File.expand_path('../application.yml', __FILE__))))
      $secret = secret[Rails.env]
      # $secret =  eval("Rails.application.credentials.#{Rails.env}")
    end
    config.active_job.queue_adapter = :sidekiq

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
