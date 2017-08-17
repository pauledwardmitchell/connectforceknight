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


task :sf_to_bk_task => :environment do
  puts "Sync task is running..."

  sf_client = Call.sf_authenticate_live
  bk_client = Call.create_live_bk_client_with_static_ip
  start_time = Time.now

  15.times do
    puts "Process running for : " + ((Time.now - start_time) / 60).round(2).to_s + " minutes..."
    if Time.now - start_time > 560
      break
    end
    Call.big_one(sf_client, bk_client)
    sleep 10
    puts "Update loop done."
  end
  puts "Sync task finished"
end


task :sf_to_bk_task_local => :environment do
  puts "Sync task is running..."

  sf_client = Call.sf_authenticate_live
  bk_client = Call.create_live_bk_client
  start_time = Time.now

  10.times do
    puts "Process running for : " + ((Time.now - start_time) / 60).round(2).to_s + " minutes..."
    if Time.now - start_time > 560
      break
    end
    Call.big_one(sf_client, bk_client)
    sleep 30
    puts "Update loop done."
  end
  puts "Sync task finished"
end
