# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def format_time(time, format = :short)
	
		case format
		when :short then time.strftime('%I:%M %p').downcase
		when :iso8601 then time.iso8601 
		end
		
	end
	
end
