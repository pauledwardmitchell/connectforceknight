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
  #initialize clients out here?
  sf_client = Call.sf_authenticate_live
  bk_client = Savon.client(wsdl: 'https://rc.api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', follow_redirects: true)

  10.times do #if can't pass in args here, just have it listed 10 times
    Call.test_fn#(sf_client, bk_client)
    #sleep 48
    puts "Heroku test task loop done."
  end
end
