class TimetableType < ActiveRecord::Base
  has_many :timetable_days
  has_many :journeys  
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
end
