desc "This task is called by the Heroku scheduler add-on"

task :test_task => :environment do
  puts "Heroku test task is running..."
  10.times do
    Call.test_fn
    puts "Heroku test task loop done."
  end
end
