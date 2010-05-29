class TimetableDay < ActiveRecord::Base
  belongs_to :timetable_type
  
  validates_presence_of :timetable_type_id, :wday
  validates_uniqueness_of :wday

end
