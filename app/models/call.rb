class Call < ApplicationRecord

  def self.test_fn
    puts "Test function running..."
    sleep 55
  end

  def self.big_one_auth
    sf_client = Call.sf_authenticate_live
    bk_client = Savon.client(wsdl: 'https://rc.api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', follow_redirects: true)
    Call.big_one(sf_client, bk_client)
  end

  def self.big_one(sf_client, bk_client)

    records = Call.query_sf(sf_client)
    two_records = records.take(2)
    two_records.each do |record|
      updated_record = Call.call_bk(record, bk_client) #set this equal to new_record?  then have new record hit sf?
      Call.update_sf(updated_record, sf_client)
    end
    puts "Update complete"
  end

  def self.query_sf(sf_client) #find sf objects that need updating
    sf_response = sf_client.query("SELECT Id,
                                          Name,
                                          REOHQ__REOHQ_Parcel_ID__c,
                                          REOHQ__REOHQ_County__c,
                                          REOHQ__REOHQ_City__c,
                                          REOHQ__REOHQ_State__c,
                                          REOHQ__REOHQ_Zip_Code__c,
                                          Street_Prefix__c,
                                          Street_Number__c,
                                          Street_Name__c,
                                          Street_Suffix__c,
                                          BKFS__c,
                                          Tax_Sq_Footage__c,
                                          Flood_Zone__c from REOHQ__REOHQ_Property__c
                                   WHERE RecordType.Name = 'Acquisition Flip Property'
                                   AND REOHQ__REOHQ_Property_Type__c = 'Detached Single'
                                   AND ((MLS_Status__c = 'Closed' AND Closed_Date__c = LAST_N_MONTHS:12) OR MLS_Status__c IN ('Pending', 'Contingent', 'Active', 'New', 'Price Change', 'Back on Market', 'Reactivated'))
                                   AND Tax_Sq_Footage__c IN (null, 0)
                                   AND REOHQ__REOHQ_County__c IN ('Cook', 'Lake', 'McHenry', 'Kane', 'DuPage', 'Will', 'Kendall')
                                   AND Area_Number__c != null
                                   AND BKFS__c = false")

  end

  def self.call_bk(record, bk_client)
    #establish savon client
    # bk_client = Savon.client(wsdl: 'https://rc.api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', follow_redirects: true)
#UNCOMMENT AFTER PROXY IS WHITELISTED ON BK
    # bk_client = Savon.client(wsdl: 'https://rc.api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', proxy: "http://proxy:2ff0a2f7ff51-4ec1-834d-13520242e6b2@proxy-54-83-47-43.proximo.io", follow_redirects: true)
    #build address
    address = Call.address(record)
    puts "Updating record for: " + address

    #call w savon
    bk_response = bk_client.call(:address_search, message: { 'Key' => ENV['BK_TEST_KEY'],
                                                             'Address' => address,
                                                             'LastLine' => record.REOHQ__REOHQ_Zip_Code__c,
                                                             'OwnerName' => 'Null',
                                                             'ReportType' => '400',
                                                             'ClientReference' => '400' })

    #extract report_url from api response
    report_url = bk_response.hash[:envelope][:body][:address_search_response][:address_search_result][:report_url]
    #open xml with nokogiri
    xml = Nokogiri::XML(open(report_url))

    #parse xml to extract values
    tax_sq_ft = xml.search("BuildingArea")[0].children.text
    flood_zone_code = xml.search("FloodZone")[0].children.text

    #set vales in record object
    record.Tax_Sq_Footage__c = tax_sq_ft
    record.Flood_Zone__c = flood_zone_code

    # puts record
    record
  end

  def self.update_sf(updated_record, sf_client)
    puts "This object would hit the SF db:"
    puts "ID: " + updated_record.Id + " / FLOOD CODE: " + updated_record.Flood_Zone__c + " / TAX AREA: " + updated_record.Tax_Sq_Footage__c
    puts "- - - - - - - - "
    puts " "
    # puts updated_record

    # client.update('REOHQ__REOHQ_Property__c', Id: updated_record.Id, Tax_Sq_Footage__c: updated_record.Tax_Sq_Footage__c, Flood_Zone__c: updated_record.Flood_Zone__c, BKFS__c: true)
  end

  def self.address(record)
    #build address
    address = ""
    if record.Street_Prefix__c
      address = record.Street_Prefix__c + " "
    end
    address = address + record.Street_Number__c + " " + record.Street_Name__c + " "
    if record.Street_Suffix__c
      address = address + record.Street_Suffix__c
    end
    address
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
