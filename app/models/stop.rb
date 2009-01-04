class Stop < ActiveRecord::Base
  belongs_to :journey
  belongs_to :station
  acts_as_list :scope => :journey
  
  validates_presence_of :journey, :station, :platform, :departing_at, :arriving_at, :position
  validates_numericality_of :position, :only_integer => true
end
