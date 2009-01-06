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
    journey_parts = XmlSimple.xml_in(xml, 'force_array' => ['Journey']) if xml
    if journey_parts and journey_parts['Journey']
      
      last_journey = nil #kkk test removal
      journey_parts['Journey'].each do |jp|
        
        #add any new journey
        if jp['iJourneyID'] != last_journey 
          last_journey = jp['iJourneyID']
          departing_at = departing_on + jp['sDepartureTime'].to_i.seconds
          journey = Journey.find_or_create_by_departing_id_and_arriving_id_and_departing_at(:departing => departing, :arriving => arriving, :departing_at => departing_at) 
        end
        
        #get the trip patterns for this journey
        xml = self.ws_get_trip_patterns(jp['sTripName'], jp['sDaysOp'].to_i, departing_on)
        trips = XmlSimple.xml_in(xml, 'force_array' => ['TripStop'])
        if trips and trips['TripStop']
          
          part_of_journey = false #kkk test removal (remember to test for multitrips - probably need to initialise depends on ruby, if variable is re-initialised depending on scope)
          position = 0 #kkk refactor this out
          trips['TripStop'].sort! {|a,b| a['sDepartureTime'].to_i <=> b['sDepartureTime'].to_i} #need to order by sDepartureTime
          trips['TripStop'].each do |trip| 
            
            part-of-journey = true if !part_of_journey and jp['DepartureNodeName'] = trip['sStationName']
            
            if part-of-journey
              #add this new stop
              station = Station.find_by_name trip['sStationName']
              departing_at = departing_on + trip['sDepartureTime'].to_i.seconds
              arriving_at = departing_on + trip['sArrivalTime'].to_i.seconds
              platform = trip['sPlatformName'].to_i 
              platform = nil if !(platform > 0 and platform < 20)
              position += 1
              
              #kkk this method name/call is a little long
              Station.find_or_create_by_journey_id_and_station_id_and_platform_and_departing_at_and_arriving_at_and_position(:journey => journey, :station => station, :platform => platform, :departing_at => departing_at, :arriving_at => arriving_at)
              
              break if trip['sStationName'] = jp['ArrivalNodeName']
              
            end    
          end  
        end        
      end
    end
  end
  
  private
  
  def self.ws_get_stations
    @@service.WSGetStations("")
  end
  
  def self.ws_get_journeys(departing_station_code, arriving_station_code, departing_on)
    @@service.WSGetJourneys(departing_station_code, arriving_station_code, 0, 86400, "DEP", departing_on, true, 9999, "")
  end
  
  def self.ws_get_fares(departing_station_code, arriving_station_code)
    @@service.WSGetFares(departing_station_code, arriving_station_code, "")
  end
  
  def self.ws_get_trip_patterns(trip_name, daysop, departing_on)
    @@service.WSGetTripPatterns(departing_on, trip_name, daysop, "")
  end
  
end