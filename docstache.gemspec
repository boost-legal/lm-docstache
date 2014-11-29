# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "docstache/version"

Gem::Specification.new do |s|
  s.name        = "docstache"
  s.version     = Docstache::VERSION
  s.authors     = ["Will Cosgrove"]
  s.email       = ["will@willcosgrove.com"]
  s.homepage    = "https://github.com/willcosgrove/docstache"
  s.summary     = %q{Merges Hash of Data into Word docx template files using mustache syntax}
  s.description = %q{Integrates data into MS Word docx template files. Processing supports loops and replacement of strings of data both outside and within loops.}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_runtime_dependency 'rubyzip', '~> 1.1'
end
