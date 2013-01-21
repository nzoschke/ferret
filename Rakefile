#!/usr/bin/env rake

require "rake/testtask"

task default: :test

Rake::TestTask.new :test do |t|
  t.pattern = "./tests/unit/test_*.rb"
end

namespace :procfile do
  task :gen do
    sh "bin/create_proc.sh ./tests"
  end

  task :clean do
    sh "rm Procfile"
  end
end

namespace :config do
  task :push do
    sh  "bin/push_config.sh"
  end
end