
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :environment do
  base_path = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
  $LOAD_PATH.unshift(base_path) unless $LOAD_PATH.include?(base_path)
  require 'trade_bot'
end

desc "Open a console with all of the code preloaded"
task :console => :environment do
  require 'pry'
  pry
end

namespace :reset do
  desc "Clear all the generated statitics (source data will be left alone)"
  task :stats => :environment do
    redis = TradeBot.redis

    redis.multi do
      redis.del('trading:processed:60')
      redis.del('trading:candlestick:60')
      redis.del('trading:processed:900')
      redis.del('trading:candlestick:900')
      redis.del('trading:processed:3600')
      redis.del('trading:candlestick:3600')
      redis.del('trading:processed:86400')
      redis.del('trading:candlestick:86400')
    end
  end
end
