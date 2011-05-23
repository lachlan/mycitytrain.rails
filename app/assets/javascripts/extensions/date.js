Date.prototype.duration = function(other, unit) {
  var duration = other.getTime() - this.getTime();
  if (unit == 'seconds') {
    duration = Math.round(duration/1000); 
  } else if (unit == 'minutes') {
    duration = Math.round(duration/(60000));
  } else if (unit == 'words') {
    duration = Math.round(duration/1000);
    if (duration <= 0) {
      duration = "now";
    } else if (duration >= 1 && duration <= 3599) {
      duration = "min".pluralize(Math.ceil(duration/60));
    } else if (duration >= 3600 && duration <= 86399) {
      var durationInHours = Math.floor(duration/3600);
      var remainderInMinutes = (duration % 3600)/60;
      if (remainderInMinutes < 30) {
        duration = "hour".pluralize(durationInHours);
      } else {
        duration = "hour".pluralize(durationInHours + 0.5);
      }
    } else if (duration >= 86400 && duration <= 2591999) {
      var durationInDays = Math.floor(duration/86400);
      var remainderInHours = (duration % 86400)/3600;
      if (remainderInHours < 12) {
        duration = "day".pluralize(durationInDays);
      } else {
        duration = "day".pluralize(durationInDays + 0.5);
      }
    } else if (duration <= 2592000 && duration <= 31535999) {
      duration = "mth".pluralize(Math.ceil(duration/2592000));
    } else {
      duration = "yr".pluralize(Math.ceil(duration/31536000));
    }
  }
  return duration;
};
// Returns a Date for the next second, minute or hour
Date.prototype.next = function(unit) {
  var n = new Date(this.getTime());
  if (unit == 'millisecond' || unit == undefined) {
    n.setMilliseconds(this.getMilliseconds() + 1);
  } else if (unit == 'second') {
    n.setSeconds(this.getSeconds() + 1);
    n.setMilliseconds(0);
  } else if (unit == 'minute') {
    n.setMinutes(this.getMinutes() + 1);
    n.setSeconds(0);
    n.setMilliseconds(0);
  } else if (unit == 'hour') {
    n.setHours(this.getHours() + 1);
    n.setMinutes(0);
    n.setSeconds(0);
    n.setMilliseconds(0);
  }
  return n;
}
Date.prototype.format = function() {
  var hours = this.getHours() <= 12 ? this.getHours() : this.getHours() - 12
  if (this.getHours() === 0) hours = 12
  var minutes = this.getMinutes() < 10 ? '0' + this.getMinutes() : this.getMinutes()
  var meridiem = this.getHours() < 12 ? 'am' : 'pm'
  return hours + ':' + minutes + ' ' + meridiem
}
Date.__original_parse__ = Date.parse;
Date.parse = function(other) {
  var date = new Date()
  if (_(other).isNumber()) {
    date.setTime(other)
  } else if (_(other).isDate()) {
    date = other
  } else if (_(other).isString()){
    var matches = other.match(/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.(\d{3}))?(Z)/)  // ISO8601 datetime string
    if (matches) {
      var year = parseInt(matches[1], 10)
        , month = parseInt(matches[2], 10)
        , day = parseInt(matches[3], 10)
        , hours = parseInt(matches[4], 10)
        , minutes = parseInt(matches[5], 10)
        , seconds = parseInt(matches[6], 10)
        
      date = new Date(Date.UTC(year, month - 1, day, hours, minutes, seconds, 0))
    } else {
      date = Date.__original_parse__(other);
    }
  } else {
    date = Date.__original_parse__(other);
  }
  return date
}
Date.now = function() { return new Date(); }