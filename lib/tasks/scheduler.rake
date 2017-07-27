desc "This task is called by the Heroku scheduler add-on"

task :test_task => :environment do
  puts "Heroku test task is running..."
  #initialize clients out here?

  10.times do #if can't pass in args here, just have it listed 10 times
    Call.test_fn
    #should sleep go here?
    puts "Heroku test task loop done."
  end
end
