class Station < ActiveRecord::Base
    has_many :departing_journeys, :class_name => "Journey", :foreign_key => "departing_id"
    has_many :arriving_journeys, :class_name => "Journey", :foreign_key => "arriving_id"
    
    validates_presence_of :code, :name
    validates_uniqueness_of :code, :name
    
    def self.find_all
      stations = Station.find(:all, :order => 'name')
      if !stations or stations.length == 0
        CitytrainAPI.stations
        stations = Station.find(:all, :order => 'name')
      end
      stations
    end
      
end
