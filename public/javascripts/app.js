// Generates an id suitable for use in HTML: http://www.w3.org/TR/html4/types.html#type-name
String.prototype.id = function() { return 'id_' + this.toString().replace(/[^a-zA-Z0-9]/g, '_'); }

// Pluralizes a string by adding an 's' on the end
String.prototype.pluralize = function(count) {
  if (count == undefined) count = 0;
  return count + " " + ((count == 1 || count == '1')? this : this + 's');
};

// Returns the duration between two dates
Date.prototype.duration = function(other, unit) {
  var duration = other - this;
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

$(document).ready(function() {
  $.support.WebKitAnimationEvent = (typeof WebKitTransitionEvent == "object");

  var journey_limit = 5;
  var active = 'active';
  var effects = 'fx in out flip slide pop cube swap slideup dissolve fade reverse';
  
  var locations = new Array();
  var search = function(term, exact) {
    if (exact)
      var pattern = new RegExp('^' + term + '$', 'i');
    else
      var pattern = new RegExp('^' + term, 'i');
    var matches = new Array();
    for (var i = 0; i < locations.length; i++) {
      if (locations[i].match(pattern)) matches.push(locations[i]);
    }
    return matches;
  };

  var loadLocations = function(callback) {
    if (locations.length == 0) {
  	  $.getJSON('/locations', function(data) {
  	    locations = data;
        if (callback) callback();
      });
    } else {
      if (callback) callback();
    }
  };

  var updateLocationName = function(element) {
    var value = $(element).attr('value');
    if (value) {
      var matches = search(value, true);
      if (matches.length > 0) {
        $(element).attr('value', matches[0]);
      }
    }
  };

  // save the original value of each form input field
  // only works for <input> elements
  var saveFormValues = function(form) {
    $(form).find('input').each(function() {
      $(this).data('value', $(this).attr('value'));
    });
  }

  var formHasChanged = function(form) {
    var dirty = false;
    $(form).find('input').each(function() {
      dirty = dirty || ($(this).attr('value') !== $(this).data('value'));
    });
    return dirty;
  };
  

  // set up the autocomplete suggestions on the form input fields
	$('input.origin, input.destination').autocomplete({
		minLength: 1,
		source: function(request, response) {
		  loadLocations(function() {
		    response(search(request.term));
		  });
		}
	});
	    
  // load some more journeys
  $('body').delegate('a.loader:not(.disabled)', 'click', function() {
    var loader = $(this);
    loader.addClass('disabled')
    loadMoreJourneys($(this).parents('.journeys'), null, function() {
      loader.removeClass('disabled');
    });
    return false; 
  });

  // handle transitions automatically on non-disabled and non-submit links
  $('body').delegate('a.fx:not(.disabled):not(.submit)', 'click', function() { 
    $(this).trigger('transition');
    return false;
  });

  // don't allow click events on disabled links
  $('body').delegate('a.disabled', 'click', function() {
    return false;
  });

  // handle transition event
  $('body').delegate('a.fx', 'transition', function() {
    var link = $(this);
    var effect = link.attr('class');
    var linker = link.parents('.page').last();    
    var href = link.attr('href');
    var fx = function(linkee) {
      if (linkee.length == 0) linkee = $('.page').first(); // if we can't find the linkee, then default to first .page element
      $(':focus').blur();
      $(linker).add(linkee).removeClass(effects).addClass(effect);
      linkee.addClass('in').addClass(active);
      linker.addClass('out');
      var animationFinished = function() {
        linker.removeClass(active).add(linkee).removeClass(effects);
        linkee.find('a.back').attr('href', '#' + linker.attr('id')).addClass('reverse').addClass(effect);
        setActivePage(setMinHeight);
      }
      if ($.support.WebKitAnimationEvent) {
        linkee.one('webkitAnimationEnd', animationFinished);
      } else {
        animationFinished();
      }
    }
    if (href.match('^#')) {
      fx($(href));
    } else {
      // load external links via ajax directly into page content
      var id = href.id();
      $('body').find('#' + id).remove();
      $('body').append('<div id="' + id + '" class="page"></div>');
      link.addClass('disabled');
      $.get(href, function(data) {
        fx($('#' + id).append(data));
        link.attr('href', '#' + id).removeClass('disabled');
      });
    }
    return false;
  });
      
  // update user entered value to use the correctly captitalized 
  // station names after an input field changes
  $('#settings form input').change(function() {
    updateLocationName($(this));
  });
   
  saveFormValues($('#settings form'));
  
  // ajax post settings form and load favourites
  $('.submit').click(function() {
    var link = $(this);
    var form = $('#settings form');
    
    if (formHasChanged(form)) {
      loadLocations(function() {
        link.addClass('disabled');
        // set station name to correctly capitalized name
        $('#settings form input[type=text]').each(updateLocationName);
        $.post(form.attr('action'), form.serialize(), function(data) {
          saveFormValues(form);
          loadFavourites(function() {
            updateETAs();
            if ($('#favourites').length > 0) {
              link.trigger('transition').removeClass('disabled');
            }
          });
        });        
      });
    } else {
      link.trigger('transition').removeClass('disabled');
    }
    return false;
  });
  
  var setActivePage = function(callback, fadeIn) {  
    var activePages = $('.page.' + active);
    var page = $('.page').first();
    if (activePages.length > 0) page = activePages.removeClass(active).first();
    if (fadeIn)
      page.fadeIn('slow', function() {
        $(this).addClass(active);
      });
    else
      page.addClass(active);
    if (callback) callback();
  }

  var loadFavourites = function(callback) {
    $.get('/favourites', function(data) {
      $('#favourites').replaceWith(data);
      if (callback) callback();
    });
  }
    
  var loadMoreJourneys = function(journeys, limit, callback) {
    var origin = journeys.attr('data-origin');
    var destination = journeys.attr('data-destination');
    var href = '/' + escape(origin).toLowerCase() + '/' + escape(destination).toLowerCase() + '?';
    var prev = journeys.find('.journey').last();
    if (href) {
      var departTime = prev.attr('data-depart-time-iso8601');
      if (departTime) {
        href += '&after=' + departTime;
      }
      if (limit && limit > 0) href = href + '&limit=' + limit;

      $.get(href, function(data) {
        var id = unescape(href).id() ;
        $('#' + id).remove();
        $('body').append('<div id="' + id + '"></div>');
        $('#' + id).append(data);
        
        var newJourneys = $('#' + id).find('.journey:not(.missing)').hide();
        if (newJourneys.length > 0) {
          prev.after(newJourneys);
          var loader = journeys.find('a.loader');
          loader.attr('href', loader.attr('href').replace(/^(.*)=(.*)$/, '$1=' + journeys.find('.journey').last().attr('data-depart-time-iso8601')));        
          newJourneys.slideDown('slow');  
          journeys.find('.missing').slideUp('slow', function() {
            $(this).remove();
          });
        }
        $('#' + id).remove();
        if (callback) callback();
      });
    }
  }
  
  // add arrow key shortcuts for flipping between favourites and return journeys
  $(document).keydown(function(event) {
    if (event.keyCode == '37') { 
      $('.active .left.arrow a').click();
    } else if (event.keyCode == '39') {
      $('.active .right.arrow a').click();
    } else if (event.keyCode == '38') {
      $('.active a.return.reverse').click();
    } else if (event.keyCode == '40') {
      $('.active a.return:not(.reverse)').click();
    }
  });

  var setMinHeight = function() {
    $('.page').css('min-height', $(window).height());
  };
  $(window).resize(setMinHeight);
  
  // keep the ETAs up to date with current time
  var updateETAs = function() {
    $('.journey:not(.missing)').each(function() {
      var journey = $(this);
      var eta = journey.find('.eta');
      var departure = new Date();
      var now = new Date();
      departure.setTime(journey.attr('data-depart-time-js'));
    
      var minutes = now.duration(departure, 'minutes');
      if (minutes <= 10) eta.addClass('soon');
      if (minutes <= 5) eta.addClass('now');
      eta.html(now.duration(departure, 'words'));
      if (now.duration(departure, 'seconds') <= 0) journey.addClass('expired');
    });
  }
  
  var flasher = function(element) {
    if (element) {
      element.animate({opacity:0.5},1000,'linear',function() {
        $(this).animate({opacity:1},1000,'linear',function() {
          $(this).animate({opacity:0.5},1000,'linear',function() {
            $(this).animate({opacity:1},1000,'linear',function() {
              $(this).animate({opacity:0.5},1000,'linear',function() {
                $(this).animate({opacity:1},1000,'linear',function() {                        
                  $(this).slideUp('slow', function() {
                    var parent = $(this).parents('.journeys');
                    $(this).remove();
                  });
                });
              });
            });
          });
        });
      });
    }
  };
  
  var expireDepartedJourneys = function() {
    $('.journeys').each(function() {
      var journeys = $(this);
      var expired = journeys.find('.journey.expired');
      var count = journey_limit - (journeys.find('.journey:not(.missing)').length - expired.length);
      if (count > 0) loadMoreJourneys(journeys, count, updateETAs);
      flasher(expired);
    });    
  }
  
  var browserWarning = $('.ie6 .browser-warning, .ie7 .browser-warning, .ie8 .browser-warning');
  browserWarning.first().slideDown('slow', function() {
    window.setTimeout(function() {
      browserWarning.first().slideUp('slow', function() {
        $('.browser-warning').remove();
      });
    }, 10000);
  })
  
  setActivePage(setMinHeight);

  (function runner() {
    updateETAs();
    expireDepartedJourneys();
    // schedule next run
    var now = new Date();
    window.setTimeout(runner, now.duration(now.next('minute')));
  })();
});