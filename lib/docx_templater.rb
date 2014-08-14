require 'nokogiri'
require 'zip'


dir = File.dirname(__FILE__)
Dir[File.expand_path("#{dir}/docx_templater/*.rb")].uniq.each do |file|
  require file
end
