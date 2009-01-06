require 'soap/wsdlDriver'

class CitytrainAPI
  @@service = SOAP::WSDLDriverFactory.new('http://www.citytrain.com.au/soaplisten/CityTrain.WSDL').create_rpc_driver
  
  def self.stations
    stations = XmlSimple.xml_in(self.ws_get_stations, 'force_array' => ['Station'])
    stations['Station'].each do |station|
      Station.find_or_create_by_code(:name => station['sStationName'], :code => station['sStationCode'])
    end
  end
  
  def self.journeys(departing, arriving, departing_on = Time.zone.now)
    Time.zone = "Brisbane"
    departing_on = Time.zone.local(departing_on.year, departing_on.month, departing_on.day) # set time to midnight
    xml = self.ws_get_journeys(departing.code, arriving.code, departing_on)
    journeys = XmlSimple.xml_in(xml, 'force_array' => ['Journey']) if xml
    if journeys and journeys['Journey']
      journeys['Journey'].each do |journey|
        departing = Station.find_by_code journey['sStationCode']
        arriving = Station.find_by_code journey['sChangeAt']
        departing_at = departing_on + journey['sDepartureTime'].to_i.seconds
    
        Journey.find_or_create_by_departing_id_and_arriving_id_and_departing_at(:departing => departing, :arriving => arriving, :departing_at => departing_at) if departing and arriving and departing_at
      
        # TODO: now fetch and create stops for each journey
        #trip_name = journey['sTripName']
        #daysop = journey['sDaysOp'].to_i
        #stops = XmlSimple.xml_in(self.ws_get_trip_patterns(trip_name, daysop, departing_on), 'force_array' => ['Trip'])
      end
    end
  end
  
  private
  
  def self.ws_get_stations
    @@service.WSGetStations(nil)
  end
  
  def self.ws_get_journeys(departing_station_code, arriving_station_code, departing_on = Time.zone.now)
    @@service.WSGetJourneys(departing_station_code, arriving_station_code, 0, 86400, "DEF", departing_on, departing_on, 9999, nil)
  end
  
  def self.ws_get_fares(departing_station_code, arriving_station_code)
    @@service.WSGetFares(departing_station_code, arriving_station_code, nil)
  end
  
  def self.ws_get_trip_patterns(trip_name, daysop, departing_on = Time.zone.now)
    @@service.WSGetTripPatterns(departing_on, trip_name, daysop, nil)
  end
  
end