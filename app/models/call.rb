class Call < ApplicationRecord

  def self.test_fn
    puts "Test function running..."
  end

  def self.query_sf #find sf objects that need updating
    client = Call.sf_authenticate
    #client.query("query string") where tax property id is nil
    #hit app db?
  end

  def self.call_bk
    #call w savon
    #handle result
  end

  def self.update_sf
    # Update the Account with `Id` '0016000000MRatd'
    # client.update('Account', Id: '0016000000MRatd', Name: 'Whizbang Corp')
    # => true
  end

  def self.sf_authenticate
    Restforce.new(username: ENV['SALESFORCE_USERNAME'],
                  password: ENV['SALESFORCE_PASSWORD'],
                  security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
                  client_id: ENV['SALESFORCE_CLIENT_ID'],
                  client_secret: ENV['SALESFORCE_CLIENT_SECRET'])
  end

end
