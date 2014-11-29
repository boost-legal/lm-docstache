require 'nokogiri'
require 'zip'


dir = File.dirname(__FILE__)
Dir[File.expand_path("#{dir}/docstache/*.rb")].uniq.each do |file|
  require file
end
