class Call < ApplicationRecord

  def self.test_fn
    puts "Test function running..."
  end

  def self.query_sf #find sf objects that need updating
    sf_client = Call.sf_authenticate
    sf_response = sf_client.query('select Id, REOHQ__REOHQ_Property__c, REOHQ__REOHQ_Parcel_ID__c, REOHQ__REOHQ_County__c, REOHQ__REOHQ_City__c, REOHQ__REOHQ_State__c, REOHQ__REOHQ_Zip_Code__c, Tax_Sq_Footage__c, Flood_Zone__c from REOHQ__REOHQ_Property__c where Tax_Sq_Footage__c = null')
  end

  def self.call_bk
    #establish savon client
    bk_client = Savon.client(wsdl: 'https://rc.api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', follow_redirects: true)
    #call w savon
    bk_response = bk_client.call(:address_search, message: { 'Key' => ENV['BK_TEST_KEY'],
                                                          'Address' => '5625 Shaddelee Lane',
                                                          'LastLine' => '33919',
                                                          'OwnerName' => 'Smith',
                                                          'ReportType' => '400',
                                                          'ClientReference' => '400' })
    bk_response_hash = bk_response.to_hash
    # binding.pry
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

  def self.sf_authenticate_live
    Restforce.new(username: ENV['SALESFORCE_USERNAME_LIVE'],
                  password: ENV['SALESFORCE_PASSWORD_LIVE'],
                  security_token: ENV['SALESFORCE_SECURITY_TOKEN_LIVE'],
                  client_id: ENV['SALESFORCE_CLIENT_ID_LIVE'],
                  client_secret: ENV['SALESFORCE_CLIENT_SECRET_LIVE'])
  end


end
