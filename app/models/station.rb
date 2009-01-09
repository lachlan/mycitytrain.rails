class Station < ActiveRecord::Base
    has_many :departing_journeys, :class_name => "Journey", :foreign_key => "departing_id", :dependent => :destroy
    has_many :arriving_journeys, :class_name => "Journey", :foreign_key => "arriving_id", :dependent => :destroy
    
    validates_presence_of :code, :name
    validates_uniqueness_of :code, :name
    
    def journeys
      departing_journeys + arriving_journeys
    end
    
    def self.find_all
      stations = Station.find(:all, :order => 'name')
      if stations.empty?
        CitytrainAPI.stations
        stations = Station.find(:all, :order => 'name')
      end
      stations
    end
      
end
