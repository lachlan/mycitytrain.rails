function addSwipeListener(el, listener){
  var startX;
  var dx;
  var direction;

  function cancelTouch() {
    el.removeEventListener('touchmove', onTouchMove);
    el.removeEventListener('touchend', onTouchEnd);
    startX = null;
    startY = null;
    direction = null;
  }
 
  function onTouchMove(e) {
    if (e.touches.length > 1) {
      cancelTouch();
    } else {
      dx = e.touches[0].pageX - startX;
      var dy = e.touches[0].pageY - startY;
      if (direction == null) {
        direction = dx;
        e.preventDefault();
      } else if ((direction < 0 && dx > 0) || (direction > 0 && dx < 0) || Math.abs(dy) > 15) {
        cancelTouch();
      }
    }
  }

  function onTouchEnd(e) {
    cancelTouch();
    if (Math.abs(dx) > 50) {
      listener({ target: el, direction: dx > 0 ? 'right' : 'left' });
    }
  }
 
  function onTouchStart(e) {
    if (e.touches.length == 1) {
      startX = e.touches[0].pageX;
      startY = e.touches[0].pageY;
      el.addEventListener('touchmove', onTouchMove, false);
      el.addEventListener('touchend', onTouchEnd, false);
    }
  }

  el.addEventListener('touchstart', onTouchStart, false);
}

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

$(document).ready(function() {
  addSwipeListener(document.body, function(e) { 
    var target;
    if (e.direction == "left") {
      target = $('.page.active footer li.active').next();
    } else {
      target = $('.page.active footer li.active').prev();      
    }
    if (target) target.children('a').click();
  });
  
  $.support.WebKitAnimationEvent = (typeof WebKitTransitionEvent == "object");

  var journey_limit = 5;
  var active = 'active';
  var effects = 'fx in out flip slide pop cube swap slideup dissolve fade reverse';
  
  var setActivePage = function() {
    $('.page').css('min-height',$(window).height());
    
    var activePages = $('.page.' + active);
    if (activePages.length > 0)
      activePages.removeClass(active).first().addClass(active);
    else
      $('.page').first().addClass(active);
  }

  var loadFavourites = function(callback) {
    $.get('/', function(data) {
      $('#favourites').remove();
      $('#content').append(data);
      if (callback) callback();
    });
  }
  
  var loadSettings = function(callback) {
    $.get('/settings#settings', function(data) {
      $('#content').append(data);
      if (callback) callback();
    });
  }

  // load page contents asynchronously
  var loadContent = function() {
    var pages = $('.page');
    if (pages.length == 0) {
      loadFavourites(function() {
        if ($('#favourites').length == 0) {
          loadSettings(function() {
            setActivePage();
          });
        }
        setActivePage();
      });
    } else {
      setActivePage();
    }
  }
    
  loadContent();
    
  // handle transitions automatically on non-disabled and non-submit links
  $('a.fx:not(.disabled):not(.submit)').live('click', function() {
    $(this).trigger('transition');
    return false;
  });
  
  // handle transition event
  $('a.fx').live('transition', function() {
    var link = $(this);
    var effect = link.attr('class');
    var linker = link.parents('.page').last();    
    var href = link.attr('href');
    var fx = function(linkee) {
      $(':focus').blur();
      window.scrollTo(0, 1);
      $(linker).add(linkee).removeClass(effects).addClass(effect);
      linkee.addClass('in').addClass(active);
      linker.addClass('out');
      var animationFinished = function() {
        linker.removeClass(active).add(linkee).removeClass(effects);
        linkee.find('a.back').attr('href', '#' + linker.attr('id')).addClass('reverse').addClass(effect);
        setActivePage();
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
      $('#content').find('#' + id).remove();
      $('#content').append('<section id="' + id + '" class="page"></section>');
      $.get(href, function(data) {
        fx($('#' + id).append(data));
        link.attr('href', '#' + id);
      });
    }
    return false;
  });
  
  // load some more journeys
  $('a.loader').live('click', function() {
    loadMoreJourneys($(this).parents('.journeys'));
    return false; 
  });
  
  var loadMoreJourneys = function(journeys, limit) {
    var prev = journeys.find('.journey').last();
    var href = prev.find('a').attr('href') + '/after';
    if (limit && limit > 0) href = href + '?limit=' + limit;
    
    $.get(href, function(data) {
      var id = generateID(href);
      $('#' + id).remove();
      $('#content').append('<section id="' + id + '"></section>');
      $('#' + id).append(data);
      prev.after($('#' + id).children().hide().slideDown('slow', function() {
        $('#' + id).remove();
        journeys.find('a.loader').attr('href', journeys.find('.journey').last().find('a').attr('href') + '/after');
      }));
    });
  }
  
  // don't allow click events on disabled links
  $('a.disabled').live('click', function() {
    return false;
  })
  
  // disable done button until user configures a journey
  $(':input').live('change', function() {
    var input = $(this);
    var link = input.parents('.page').find('a.back');
    var form = input.parents('form').first();
    
    link.addClass('disabled');
    form.find('li').each(function() {
      var selected = $(this).find(":selected");
      var value = selected.first().attr('value');
      // if you've selected at least one journey, and the origin and destination don't match
      if ((selected.filter("[value='']").length == 0) && (selected.filter("[value='" + value + "']").length < 2))
        link.removeClass('disabled');
    });
  });
  
  // ajax post settings form and load favourites
  $('.submit').live('click', function() {
    var link = $(this);
    var form = link.parents('.page').find('form');
    $.post(form.attr('action'), form.serialize(), function(data) {
      loadFavourites(function() {
        if ($('#favourites').length == 0) {
          link.addClass('disabled');
        } else {
          link.trigger('transition');
        }
      });
    });
  });
  
  // keep the ETAs up to date with current time and remove departed journeys
  var updateETAs = function() {
    $('.journey .eta').each(function() {
      var eta = $(this);
      var journey = eta.parents('.journey');
      var departureDate = new Date();
      var currentDate = new Date();
      departureDate.setTime(eta.parent().find('.time').first().attr('title'));
      
      var duration = durationInSeconds(currentDate, departureDate);
      
      var durationInMinutes = duration/60;
      if (durationInMinutes <= 5) {
        eta.removeClass("less_than_ten_minutes").addClass("less_than_five_minutes");
      } else if (durationInMinutes <= 10) {
        eta.addClass("less_than_ten_minutes");
      }
      
      if (duration > 0 || journey.hasClass('detail')) {
        eta.html(durationInWords(duration));
      } else {
        eta.html("now");
        journey.addClass('expired');
      }
    });
    
    $('.journeys').each(function() {
      var journeys = $(this);
      var expired = journeys.find('.journey.expired');
      var count = journey_limit - (journeys.find('.journey').length - expired.length);
      
      if (count > 0) loadMoreJourneys(journeys, count);
      
      expired.animate({opacity:0.5},1000,'linear',function() {
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
    });
    // reschedule next run
    window.setTimeout(updateETAs, millisecondsUntilNextMinute());
  }
    
  updateETAs();
  
  // hide address bar
  window.scrollTo(0, 1);
  
  // show iphone hint
  if (window.navigator.platform == "iPhone")
  {
    if (!window.navigator.standalone)
    {
      window.setTimeout(function() {
        $("#iPhoneHint").addClass("visible");
          window.setTimeout(function() {
          $("#iPhoneHint").removeClass("visible");
        }, 8000);
      }, 1500);
    }
  }
  
});