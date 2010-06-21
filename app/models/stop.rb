class Stop < ActiveRecord::Base
  belongs_to :journey
  
  validates_presence_of :journey, :station_name, :platform, :departing_seconds, :arriving_seconds, :position
  validates_numericality_of :position, :only_integer => true
end
