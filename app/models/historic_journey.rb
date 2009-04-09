class HistoricJourney < ActiveRecord::Base
  belongs_to :departing, :class_name => 'Station'
  belongs_to :arriving, :class_name => 'Station'
  validates_presence_of :departing, :arriving
end
