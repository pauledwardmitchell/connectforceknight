class Call < ApplicationRecord

  def self.test_fn
    puts "Test function running..."
  end

  def self.query_sf #find sf objects that need updating
    sf_client = Call.sf_authenticate
    #client.query("query string") where tax property id is nil
    #hit app db?
  end

  def self.call_bk
    #establish savon client
    bk_client = Savon.client(wsdl: 'https://rc.api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', follow_redirects: true)
    #call w savon
    bk_response = client.call(:address_search, message: { 'Key' => ENV['BK_TEST_KEY'],
                                                          'Address' => '5625 Shaddelee Lane',
                                                          'LastLine' => '33919',
                                                          'OwnerName' => 'Smith',
                                                          'ReportType' => '400',
                                                          'ClientReference' => '400' })
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
