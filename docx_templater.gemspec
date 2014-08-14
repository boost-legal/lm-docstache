# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "docx_templater/version"

Gem::Specification.new do |s|
  s.name        = "docx_templater"
  s.version     = DocxTemplater::VERSION
  s.authors     = ["Florent Bouron"]
  s.email       = ["florent@cryph.net"]
  s.homepage    = "https://github.com/pl0o0f/docx_templater"
  s.summary     = %q{Merges Hash of Data into Word docx template files}
  s.description = %q{Integrates data into MS Word docx template files. Processing supports loops and replacement of strings of data both outside and within loops.} 

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'rubyzip'
end
