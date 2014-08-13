require 'nokogiri'
require 'zip/zipfilesystem'


module DocxTemplater
  module_function

  def log(str)
    # braindead logging
    puts str if ENV['DEBUG']
  end
end

require 'docx_templater/parser'
require 'docx_templater/docx_templater'
