// crappy pluralize implementation
function plural(singular) {
  return singular + "s";
}

function pluralize(count, singular) {
  var p = (count == 1 || count == '1')? singular : plural(singular);
  if (count) 
    p = count + " " + p;
  else
    p = "0 " + p;
  return p;
}

function durationInSeconds(fromDate, toDate) {
  return Math.round((toDate - fromDate)/1000);
}

function durationInWords(durationInSeconds) {
  var duration = durationInSeconds;
  var phrase;
  var unsigned_duration = duration;
  if (duration < 0) {
    unsigned_duration = duration * -1;
  }
  
  if (unsigned_duration == 0) {
    phrase = "now";
  } else if (unsigned_duration >= 1 && unsigned_duration <= 3599) {
    phrase = pluralize(Math.ceil(duration/60), "min");
  } else if (unsigned_duration >= 3600 && unsigned_duration <= 86399) {
    var durationInHours = Math.floor(duration/3600);
    var remainderInMinutes = (duration % 3600)/60;
    if (remainderInMinutes < 30)
      phrase = pluralize(durationInHours, "hour");
    else
      phrase = pluralize(durationInHours + 0.5, "hour");
  } else if (unsigned_duration >= 86400 && unsigned_duration <= 2591999) {
    var durationInDays = Math.floor(duration/86400);
    var remainderInHours = (duration % 86400)/3600;
    if (remainderInHours < 12)
      phrase = pluralize(durationInDays, "day");
    else
      phrase = pluralize(durationInDays + 0.5, "day");
  } else if (unsigned_duration <= 2592000 && unsigned_duration <= 31535999) {
    phrase = pluralize(Math.ceil(duration/2592000), "mth");
  } else {
    phrase = pluralize(Math.ceil(duration/31536000), "yr");
  }
  return phrase;
}

var millisecondsUntilNextMinute = function() {
  var now = new Date();
  var next = new Date();
  next.setMinutes(now.getMinutes() + 1);
  next.setSeconds(0);
  next.setMilliseconds(0);
  return next - now;
}

var generateID = function(href) {
  return 'id' + href.replace(/[^a-zA-Z0-9]/g, '_');
}

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

var updateStationName = function(element) {
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

$(document).ready(function() {
  $.support.WebKitAnimationEvent = (typeof WebKitTransitionEvent == "object");

  var journey_limit = 5;
  var active = 'active';
  var effects = 'fx in out flip slide pop cube swap slideup dissolve fade reverse';

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
        linkee.one('webkitAnimationEnd', function() { animationFinished(); });
      } else {
        animationFinished();
      }
    }    
    if ((href).match('^#')) {
      fx($(href));
    } else {
      // load external links via ajax directly into page content
      var id = generateID(href);
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
    updateStationName($(this));
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
        $('#settings form input[type=text]').each(updateStationName);
        $.post(form.attr('action'), form.serialize(), function(data) {
          saveFormValues(form);
          loadFavourites(function() {
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
    var prev = journeys.find('.journey').last();
    var href = journeys.find('a.loader').attr('href');
    if (href) {
      var departTime = prev.attr('data-depart-time-iso8601');
      if (departTime) {
        href = href.replace(/^(.*)=(.*)$/, '$1=' + departTime);
        if (limit && limit > 0) href = href + '&limit=' + limit;
      }

      $.get(href, function(data) {
        var id = generateID(href);
        $('#' + id).remove();
        $('body').append('<div id="' + id + '"></div>');
        $('#' + id).append(data);
        
        var newJourneys = $('#' + id).find('.journey').hide();
        prev.after(newJourneys);
        $('#' + id).remove();                
        var loader = journeys.find('a.loader');
        loader.attr('href', loader.attr('href').replace(/^(.*)=(.*)$/, '$1=' + journeys.find('.journey').last().attr('data-depart-time-iso8601')));
        
        journeys.find('.missing').hide().last().show();
        journeys.find('.missing:hidden').remove();
        
        newJourneys.slideDown('slow');
        
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
  
  // keep the ETAs up to date with current time and remove departed journeys
  var updateETAs = function() {
    $('.journey').each(function() {
      var journey = $(this);
      var eta = journey.find('.eta');
      var departureDate = new Date();
      var currentDate = new Date();
      departureDate.setTime(journey.attr('data-depart-time-js'));
    
      var duration = durationInSeconds(currentDate, departureDate);
    
      var durationInMinutes = duration/60;
      if (durationInMinutes <= 5) {
        eta.removeClass("lt_ten").addClass("lt_five");
      } else if (durationInMinutes <= 10) {
        eta.addClass("lt_ten");
      }
    
      if (duration > 0 || journey.hasClass('detail')) {
        eta.html(durationInWords(duration));
      } else {
        eta.html("now");
        journey.addClass('expired');
      }
    });
    
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
  
    $('.journeys').each(function() {
      var journeys = $(this);
      var expired = journeys.find('.journey.expired:not(.missing)');
      var count = journey_limit - (journeys.find('.journey').length - expired.length);
      if (count > 0) loadMoreJourneys(journeys, count);
      flasher(expired);
    });

    // reschedule next run
    window.setTimeout(updateETAs, millisecondsUntilNextMinute());
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
  updateETAs();
});