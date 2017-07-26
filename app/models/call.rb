class Call < ApplicationRecord

  def self.test_fn
    puts "Test function running..."
  end

  def self.big_one
    records = Call.query_sf
    two_records = records.take(2)
    two_records.each do |record|
      updated_record = Call.call_bk(record) #set this equal to new_record?  then have new record hit sf?
      Call.update_sf(updated_record)
    end
  end

  def self.query_sf #find sf objects that need updating
    sf_client = Call.sf_authenticate_live
    sf_response = sf_client.query('select Id,
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
                                          Tax_Sq_Footage__c,
                                          Flood_Zone__c from REOHQ__REOHQ_Property__c where Tax_Sq_Footage__c = null')
  end

  def self.call_bk(record)
    #establish savon client
    bk_client = Savon.client(wsdl: 'https://rc.api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', follow_redirects: true)

    #build address
    address = Call.address(record)
    puts address

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

    puts record
    record
  end

  def self.update_sf(updated_record)
    puts "This object would hit the SF db:"
    puts "ID: " + updated_record.Id
    puts updated_record

    # client.update('REOHQ__REOHQ_Property__c', Id: updated_record.Id, Tax_Sq_Footage__c: updated_record.Tax_Sq_Footage__c, Flood_Zone__c: updated_record.Flood_Zone__c)
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
