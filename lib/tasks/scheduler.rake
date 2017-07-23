desc "This task is called by the Heroku scheduler add-on"

task :test_task => :environment do
  puts "Heroku test task is running..."
  Call.test_fn
  puts "Heroku test task done."
end
