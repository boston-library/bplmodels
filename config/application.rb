module Bplmodels
  class Application < Rails::Application

    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}')]
  end
end