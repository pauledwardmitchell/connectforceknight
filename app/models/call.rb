class Call < ApplicationRecord

  def self.test_fn
    puts "Test function running..."
    sleep 55
  end

  def self.big_one_auth
    sf_client = Call.sf_authenticate_live
    bk_client = Call.create_live_bk_client
    Call.big_one(sf_client, bk_client)
  end

  def self.big_one(sf_client, bk_client)
    puts "Calling Salesforce for records to update..."
    records = Call.query_sf(sf_client)
    puts records.count

    if records.first
      records.each do |record|
        updated_record = Call.call_bk(record, bk_client)
        Call.update_sf(record, updated_record, sf_client)
      end
    else
      puts "No records to update at this time"
      sleep 40
    end

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
                                          Lot_Square_footage__c,
                                          Tax_Sq_Footage__c,
                                          Flood_Zone__c from REOHQ__REOHQ_Property__c
                                   WHERE RecordType.Name = 'Acquisition Flip Property'
                                   AND REOHQ__REOHQ_Property_Type__c = 'Detached Single'
                                   AND ((MLS_Status__c = 'Closed' AND Closed_Date__c = LAST_N_MONTHS:12) OR MLS_Status__c IN ('Pending', 'Contingent', 'Active', 'New', 'Price Change', 'Back on Market', 'Reactivated'))
                                   AND Tax_Sq_Footage__c IN (null, 0)
                                   AND REOHQ__REOHQ_County__c IN ('Cook', 'Lake', 'McHenry', 'Mc Henry', 'Kane', 'DuPage', 'Du Page', 'Will', 'Kendall')
                                   AND Area_Number__c != null
                                   AND BKFS__c = false")
  end

  def self.call_bk(record, bk_client)
    #build address, fips
    # fips = Call.get_fips(record.REOHQ__REOHQ_County__c)
    address = Call.address(record)
    puts "Calling BKFS for information on: " + address

    #call w savon

    #if record.REOHQ__REOHQ_Parcel_ID__c != nil && Call.get_fips(record.REOHQ__REOHQ_County__c) != nil
      #bk_response = Call.bkfs_apn_search(bk_client, fips, record)
      #bk_response
    #else
      #bk_response = Call.bkfs_address_search(bk_client, address, record)
      #bk_response
    #end

    bk_response = bk_client.call(:address_search, message: { 'Key' => ENV['BK_LIVE_KEY'],
                                                             'Address' => address,
                                                             'LastLine' => record.REOHQ__REOHQ_Zip_Code__c,
                                                             'OwnerName' => 'Null',
                                                             'ReportType' => '400',
                                                             'ClientReference' => '400' })
    #extract report_url from api response
    report_url = bk_response.hash[:envelope][:body][:address_search_response][:address_search_result][:report_url]


    if bk_response.body[:address_search_response][:address_search_result][:status_code] == "OK"
      #open xml with nokogiri
      xml = Nokogiri::XML(open(report_url))
      #parse xml to extract values
      tax_sq_ft = xml.search("BuildingArea")[0].children.text
      flood_zone_code = xml.search("FloodZone")[0].children.text
      lot_sq_footage = xml.search("LotSize")[0].children.text

      #remove trailing white space on flood zone code
      flood_zone_code = flood_zone_code.strip

      #set vales in record object
      record.Tax_Sq_Footage__c = tax_sq_ft
      record.Flood_Zone__c = flood_zone_code
      record.Lot_Square_footage__c = lot_sq_footage

      #returns updated record
      record
    elsif bk_response.body[:address_search_response][:address_search_result][:status_code] == "IK"
      puts "Check API Credentials"
      record = nil
    else
      puts "BKFS cannot find a match for this property. STATUS CODE: " + bk_response.body[:address_search_response][:address_search_result][:status_code] + " / " + bk_response.body[:address_search_response][:address_search_result][:status]
      record
    end
    record
  end

  def self.bkfs_address_search(bk_client, address, record)
    bk_response = bk_client.call(:address_search, message: { 'Key' => ENV['BK_LIVE_KEY'],
                                                             'Address' => address,
                                                             'LastLine' => record.REOHQ__REOHQ_Zip_Code__c,
                                                             'OwnerName' => 'Null',
                                                             'ReportType' => '400',
                                                             'ClientReference' => '400' })
    bk_response
  end

  def self.update_sf(record, updated_record, sf_client)
    if updated_record.Tax_Sq_Footage__c == "0"
      if sf_client.update('REOHQ__REOHQ_Property__c', Id: updated_record.Id, Flood_Zone__c: updated_record.Flood_Zone__c, Lot_Square_footage__c: updated_record.Lot_Square_footage__c, BKFS__c: true)
        puts "The tax_sq_ft for this record is not being updated because the BKFS value is zero."
        puts "Record updated in Salesforce. ID: " + record.Id
      else
        puts "Record NOT updated in Salesforce. ID: " + record.Id
      end
      puts "- - - - - - - - "
      puts " "
    else
      if sf_client.update('REOHQ__REOHQ_Property__c', Id: updated_record.Id, Tax_Sq_Footage__c: updated_record.Tax_Sq_Footage__c, Flood_Zone__c: updated_record.Flood_Zone__c, Lot_Square_footage__c: updated_record.Lot_Square_footage__c, BKFS__c: true)
        puts "Record updated in Salesforce. ID: " + record.Id
      else
        puts "Reauthenticating Salesforce client..."
        sf_client = Call.sf_authenticate_live
        if sf_client.update('REOHQ__REOHQ_Property__c', Id: updated_record.Id, Tax_Sq_Footage__c: updated_record.Tax_Sq_Footage__c, Flood_Zone__c: updated_record.Flood_Zone__c, Lot_Square_footage__c: updated_record.Lot_Square_footage__c, BKFS__c: true)
          puts "Record updated in Salesforce. ID: " + record.Id
        else
          puts "Record NOT updated in Salesforce. ID: " + record.Id
          sleep 36000
        end
      end
      puts "- - - - - - - - "
      puts " "
    end
  end

  def self.address(record)
    #build address
    address = record.Street_Number__c + " "
    if record.Street_Prefix__c
      address = address + record.Street_Prefix__c + " "
    end
    address = address + record.Street_Name__c + " "
    if record.Street_Suffix__c
      address = address + record.Street_Suffix__c
    end
    address = address.strip
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

  def self.create_test_bk_client
    bk_client = Savon.client(wsdl: 'https://rc.api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', follow_redirects: true)
  end

  def self.create_live_bk_client
    bk_client = Savon.client(wsdl: 'https://api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', follow_redirects: true)
  end

  def self.create_live_bk_client_with_static_ip
    bk_client = Savon.client(wsdl: 'https://api.sitexdata.com/sitexapi/SitexAPI.asmx?wsdl', proxy: ENV['PROXIMO_URL'], follow_redirects: true)
  end

  # def self.bkfs_apn_search(bk_client, fips, record)
  #   bk_response = bk_client.call(:apn_search, message: { 'Key' => ENV['BK_LIVE_KEY'],
  #                                                            'FIPS' => fips,
  #                                                            'APN' => record.REOHQ__REOHQ_Parcel_ID__c,
  #                                                            'ReportType' => '400',
  #                                                            'ClientReference' => '400' })
  #   bk_response
  # end

  # def self.bkfs_test_apn_search(bk_client, fips, record)
  #   bk_response = bk_client.call(:apn_search, message: { 'Key' => ENV['BK_TEST_KEY'],
  #                                                            'FIPS' => fips,
  #                                                            'APN' => record.REOHQ__REOHQ_Parcel_ID__c,
  #                                                            'ReportType' => '400',
  #                                                            'ClientReference' => '400' })
  #   bk_response
  # end

  # def self.get_fips(county_name)
  #   case county_name
  #   when 'Cook'
  #     return '17031'
  #   when 'Lake'
  #     return '17097'
  #   when 'McHenry'
  #     return '17111'
  #   when 'Kane'
  #     return '17089'
  #   when 'DuPage', 'Du Page'
  #     return '17043'
  #   when 'Will'
  #     return '17197'
  #   when 'Kendall'
  #     return '17093'
  #   else
  #     return nil
  #   end
  # end
end
