# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def format_time(time, format = :short_html)
	
		case format
		when :short_html then time.strftime('%I:%M&nbsp;%p').downcase
		when :iso8601 then time.iso8601 
		when :weekday then time.strftime('%A')
		end
		
	end

end
