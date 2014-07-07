require "bplmodels/engine"
require "bplmodels/datastream_input_funcs"
require "bplmodels/finder"
require "bplmodels/constants"
require "timeliness"

# add some formats to Timeliness gem for better parsing
Timeliness.add_formats(:date, 'm-d-yy', :before => 'd-m-yy')
Timeliness.add_formats(:date, 'mmm[\.]? d[a-z]?[a-z]?[,]? yyyy')
Timeliness.add_formats(:date, 'yyyy mmm d')

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
end
