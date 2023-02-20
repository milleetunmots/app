require 'sidekiq/api'

namespace :sidekiq do
  desc 'clear sidekiq'
  task clear_queues: :environment do
    Sidekiq::Queue.all.each(&:clear)
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
    Sidekiq::DeadSet.new.clear
    Sidekiq::Stats.new.reset
  end
end
