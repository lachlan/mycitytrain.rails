# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def format_time(time, format = :short_html)  
    case format
      when :short_html  then time.strftime('%I:%M&nbsp;%p').downcase
      when :iso8601     then time.iso8601 
      when :weekday     then time.strftime('%A')
      when :js          then (time.to_f * 1000).round
    end
  end
    
  def duration_in_words(from_time, to_time)
    if from_time and to_time
      from_time = from_time.to_time if from_time.respond_to?(:to_time)
      to_time = to_time.to_time if to_time.respond_to?(:to_time)
      duration_in_seconds = ((to_time - from_time).abs).round
    else
      duration_in_seconds = 0
    end
    
    case duration_in_seconds
      # between 0 seconds and 1 minute
      when 0..59 then 
        pluralize(duration_in_seconds, 'second')

      # between 1 minute and 1 hour
      when 60..3599 then
        duration_in_minutes = (duration_in_seconds / 60.0).floor
        remainder_in_seconds = (duration_in_seconds % 60.0).round
        remainder_in_seconds > 0 ? pluralize(duration_in_minutes, 'minute') + ', ' + pluralize(remainder_in_seconds, 'second') : pluralize(duration_in_minutes, 'minute')

      # between 1 hour and 1 day
      when 3600..86399 then
        duration_in_hours = (duration_in_seconds / 3600.0).floor
        remainder_in_minutes = ((duration_in_seconds % 3600.0) / 60.0).round
        remainder_in_minutes > 0 ? pluralize(duration_in_hours, 'hour') + ', ' + pluralize(remainder_in_minutes, 'minute') : pluralize(duration_in_hours, 'hour')
      
      # between 1 day and 1 month
      when 86400..2591999
        duration_in_days = (duration_in_seconds / 86400.0).floor
        remainder_in_hours = ((duration_in_seconds % 86400.0) / 3600.0).round
        remainder_in_hours > 0 ? 'about ' + pluralize(duration_in_days, 'day') + ', ' + pluralize(remainder_in_hours, 'hour') : pluralize(duration_in_days, 'day')
        
      # between 1 month and 1 year
      when 2592000..31535999
        duration_in_months = (duration_in_seconds / 2592000.0).floor
        remainder_in_days = ((duration_in_seconds % 2592000.0) / 86400.0).round
        remainder_in_days > 0 ? 'about ' + pluralize(duration_in_months, 'month') + ', ' + pluralize(remainder_in_days, 'day') : 'about ' + pluralize(duration_in_months, 'month')
        
      # greater than 1 year
      else
        duration_in_years = (duration_in_seconds/31536000.0).floor
        remainder_in_months = ((duration_in_seconds % 31536000.0) / 2592000.0).round
        remainder_in_months > 0 ? 'about ' + pluralize(duration_in_years, 'year') + ', ' + pluralize(remainder_in_months, 'month') : 'about ' + pluralize(duration_in_years, 'year')
    end
  end
  
  def classify_duration_to_now(time)
    if time
      duration_in_seconds = (time - Time.now).round    
      if duration_in_seconds < 300 then
        "lt_five"
      elsif duration_in_seconds < 600 then
        "lt_ten"
      else
        ""
      end
    else
      "unknown"
    end
  end

  def duration_in_concise_words(from_time, to_time)
    if from_time and to_time
      from_time = from_time.to_time if from_time.respond_to?(:to_time)
      to_time = to_time.to_time if to_time.respond_to?(:to_time)
      duration_in_seconds = (to_time - from_time).round
      unsigned_duration_in_seconds = duration_in_seconds.abs
    
      case unsigned_duration_in_seconds
        # between 0 minute and 1 hour
        when 0..3599 then
          duration_in_minutes = (duration_in_seconds / 60.0).ceil
          duration = pluralize(duration_in_minutes, 'min')

        # between 1 hour and 1 day
        when 3600..86399 then
          duration_in_hours = duration_in_seconds / 3600
          remainder_in_mins = (duration_in_seconds % 3600) / 60
          if remainder_in_mins < 30
            duration = pluralize(duration_in_hours, 'hour')
          else
            duration = pluralize(duration_in_hours + 0.5, 'hour')
          end
          
        # between 1 day and 1 month
        when 86400..2591999 then
          duration_in_days = duration_in_seconds / 86400
          remainder_in_hours = (duration_in_seconds % 86400) / 3600
          if remainder_in_hours < 12
            duration = pluralize(duration_in_days, 'day')
          else
            duration = pluralize(duration_in_days + 0.5 , 'day')
          end
        
        # between 1 month and 1 year
        when 2592000..31535999 then
          duration_in_months = (duration_in_seconds / 2592000.0).floor
          duration = pluralize(duration_in_months, 'mth')
        
        # greater than 1 year
        else
          duration_in_years = (duration_in_seconds/31536000.0).floor
          duration = pluralize(duration_in_years, 'yr')
      end
    else
      duration = "&mdash;"
    end
    duration
  end
  
  def duration_in_concise_words_from_now(to_time)
    duration_in_concise_words(Time.now, to_time)
  end
  
end
