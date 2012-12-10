#!/usr/bin/env rake

require "rake/testtask"

task default: :test

Rake::TestTask.new :test do |t|
  #$:.unshift << File.expand_path(File.join(File.dirname(__FILE__), "lib"))
  #t.libs << "lib/"
  t.pattern = "./tests/unit/test_ferret.rb"
end