require "bplmodels/engine"
require "bplmodels/datastream_input_funcs"
require "bplmodels/finder"
require "bplmodels/constants"
require "bplmodels/geographic_data_funcs"

module Bplmodels
  def self.environment
    if defined?(DERIVATIVE_CONFIG_GLOBAL) && DERIVATIVE_CONFIG_GLOBAL.present? && DERIVATIVE_CONFIG_GLOBAL['environment'].present?
      return DERIVATIVE_CONFIG_GLOBAL['environment']
    elsif defined?(Rails.env) and !Rails.env.nil?
      return Rails.env.to_s
    elsif defined?(ENV['environment']) and !(ENV['environment'].nil?)
      return ENV['environment']
    elsif defined?(ENV['RAILS_ENV']) and !(ENV['RAILS_ENV'].nil?)
      raise RuntimeError, "You're depending on RAILS_ENV for setting your environment. Please use ENV['environment'] for non-rails environment setting: 'rake foo:bar environment=test'"
    else
      ENV['environment'] = 'development'
    end
  end

  #For "Authorization" Header
  def self.avi_processor_credentials(type=:processor)
    if use_avi_rails_credentials?(type)
      auth = "#{rails_avi_credentials[type][:client]}:#{rails_avi_credentials[type][:avi_secret]}"
      return Base64.urlsafe_encode64(auth)
    elsif defined?(DERIVATIVE_CONFIG_GLOBAL)  && DERIVATIVE_CONFIG_GLOBAL.present? && DERIVATIVE_CONFIG_GLOBAL['avi_client'].present? && DERIVATIVE_CONFIG_GLOBAL['avi_secret'].present?
      auth = "#{DERIVATIVE_CONFIG_GLOBAL['avi_client']}:#{DERIVATIVE_CONFIG_GLOBAL['avi_secret']}"
      return Base64.urlsafe_encode64(auth)
    elsif ENV['AVI_CLIENT'].present? && ENV['AVI_SECRET'].present?
      auth = "#{ENV['AVI_CLIENT']}:#{ENV['AVI_SECRET']}"
      return Base64.urlsafe_encode64(auth)
    else
      raise RuntimeError, "Could Not Find Credentials for AVI Processor"
    end
  end

  def self.avi_url
    if using_rails_credentials? && rails_avi_credentials[:url].present?
      return rails_avi_credentials[:url]
    elsif defined?(DERIVATIVE_CONFIG_GLOBAL) &&  DERIVATIVE_CONFIG_GLOBAL.present?  && DERIVATIVE_CONFIG_GLOBAL['url'].present?
      return DERIVATIVE_CONFIG_GLOBAL['url']
    elsif ENV['AVI_URL'].present?
      return ENV['AVI_URL']
    else
      raise RuntimeError, "Could Not Determine Url for AVI Processor"
    end
  end

  def self.rails_avi_credentials
    Rails.application.credentials[Rails.env.to_sym][:avi]
  end


  protected
  def self.use_avi_rails_credentials?(type=:processor)
    if using_rails_credentials?
      return rails_avi_credentials[type][:client].present? &&  rails_avi_credentials[type][:secret].present?
    end
    false
  end

  def self.using_rails_credentials?
    rails_avi_credentials.present?
  end
end
