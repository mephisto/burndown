begin
  require 'date'
  require 'uri'
  require 'float'
  require 'macro_development_toolkit'
  require 'burn_down_series'
  require 'burn_down_chart'
rescue
  require 'rubygems'
  require 'date'
  require 'uri'
  require 'float'
  require 'macro_development_toolkit'
  require 'burn_down_series'
  require 'burn_down_chart'
end

if defined?(RAILS_ENV) && RAILS_ENV == 'production' && defined?(MinglePlugins)
  MinglePlugins::Macros.register(BurnDown, 'burn_down')
end 
