class TimetableType < ActiveRecord::Base
  has_many :timetable_days  
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
end
