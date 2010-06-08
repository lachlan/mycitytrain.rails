require 'soap/wsdlDriver'
require 'soap/rpc/driver'
require 'xmlsimple'

class CitytrainAPI
  @@service = SOAP::WSDLDriverFactory.new('http://www.citytrain.com.au/soaplisten/CityTrain.WSDL').create_rpc_driver
  
  def self.logger
    RAILS_DEFAULT_LOGGER
  end

  def self.stations
    stations = XmlSimple.xml_in(self.ws_get_stations, 'force_array' => ['Station'])
    stations['Station'].each do |station|
      Station.find_or_create_by_code(:name => station['sStationName'], :code => station['sStationCode'])
    end
  end
  
  def self.journeys(departing, arriving, departing_on)
    
    xml = self.ws_get_journeys(departing.code, arriving.code, departing_on)
      
    journey_parts = XmlSimple.xml_in(xml, 'force_array' => ['Journey']) if xml
    if journey_parts and journey_parts['Journey']
      journeys = []
      journey_parts['Journey'].each do |jp|
        if jp['iJourneyID'] == '0'
          journeys << [jp]
        else
          if journeys.empty? || journeys.last.first['iJourneyID'] != jp['iJourneyID']
            journeys << [jp]
          else
            journeys.last << jp
          end
        end
      end
 
      journeys.each do |j|
        timetable_type_id = TimetableDay.find_by_wday(departing_on.wday).timetable_type_id
        departing_seconds = j.first['sDepartureTime'].to_i
        arriving_seconds = j.last['sArrivalTime'].to_i
        
        Journey.find_or_create_by_departing_id_and_arriving_id_and_timetable_type_id_and_departing_seconds_and_arriving_seconds(:departing_id => departing.id, :arriving_id => arriving.id, :timetable_type_id => timetable_type_id, :departing_seconds => departing_seconds, :arriving_seconds => arriving_seconds) 
      end
    end
  end
  
  def self.stops(journey)
    departing_on = Time.zone.now.midnight #kkk journey.departing_at.midnight
    xml = self.ws_get_journeys(journey.departing.code, journey.arriving.code, departing_on, journey.departing_seconds, 1)
    journey_parts = XmlSimple.xml_in(xml, 'force_array' => ['Journey']) if xml
    if journey_parts and journey_parts['Journey']
      
      position = 0
      journey_parts['Journey'].each do |jp|

        #get the trip patterns for this journey
        trip = jp['sTripname']
        daysop = jp['sDaysOp'].to_i
        base_departing_at = departing_on + jp['sDepartureTime'].to_i.seconds
        
        xml = self.ws_get_trip_patterns(trip, daysop, base_departing_at)
        trips = XmlSimple.xml_in(xml, 'force_array' => ['TripStop'])
        if trips and trips['TripStop']
          
          part_of_journey, base_seconds = false, 0
          trips['TripStop'].sort! {|a,b| a['sDepartureTime'].to_i <=> b['sDepartureTime'].to_i} #need to order by sDepartureTime
          trips['TripStop'].each do |trip| 
            
            part_of_journey = true if !part_of_journey and jp['DepartureNodeName'] == trip['sStationName']
            
            if part_of_journey
              #add this new stop
              base_seconds = trip['sDepartureTime'].to_i if base_seconds == 0
              departing_at = base_departing_at + (trip['sDepartureTime'].to_i - base_seconds).seconds
              arriving_at = base_departing_at + (trip['sArrivalTime'].to_i - base_seconds).seconds
              station_name = trip['sStationName']
              platform = trip['sPlatformName']
              platform = '0' unless (1..20) === platform.to_i 
              position += 1
              
              #kkk
              Stop.find_or_create_by_journey_id_and_position(:journey_id => journey.id, :station_name => station_name, :platform => platform, :departing_at => departing_at, :arriving_at => arriving_at, :position => position)
                            
              break if station_name == jp['ArrivalNodeName']
              
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
  
  def self.ws_get_journeys(departing_station_code, arriving_station_code, search_dt, from_time_seconds = 0, limit = 9999)
    @@service.WSGetJourneys(departing_station_code, arriving_station_code, from_time_seconds, 86400, "DEP", search_dt, true, limit, "")
  end
  
  def self.ws_get_trip_patterns(trip_name, daysop, search_dt)
    #Guarding against incompatbilities between rails and soap.  TimeWithZone can't be used, use Time instead
  search_dt = search_dt.utc if search_dt.class.name == "ActiveSupport::TimeWithZone"
  
    # create SOAP driver and add trip patterns method by hand because the auto WSDL parse seems to screw it up
    service = SOAP::RPC::Driver.new("http://www.citytrain.com.au/soaplisten/CityTrain.WSDL",                                  # endpoint uri
                                    "http://www.qr.com.au/passenger_services/CityTrain/message/",                             # namespace
                                    "http://www.qr.com.au/passenger_services/CityTrain/action/Timetable.WSGetTripPatterns")   # SOAPAction
    service.add_method('WSGetTripPatterns', 'searchDate', 'Trip', 'DaysOp', 'targetSchema')
    service.WSGetTripPatterns(search_dt, trip_name, daysop, "")
  end
end