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
  $.support.iPhone = ((navigator.userAgent.match(/iPhone/i)) || (navigator.userAgent.match(/iPod/i)));
  $.support.Standalone = window.navigator.standalone;
  $.support.WebKitAnimationEvent = (typeof WebKitTransitionEvent == "object");

  var journey_limit = 5;
  var active = 'active';
  var effects = 'fx in out flip slide pop cube swap slideup dissolve fade reverse';
  
  var handlers = function() {
    // load some more journeys
    $('a.loader').click(function() {
      loadMoreJourneys($(this).parents('.journeys'));
      return false; 
    });

    // handle transitions automatically on non-disabled and non-submit links
    $('a.fx:not(.disabled):not(.submit)').click(function() { 
      $(this).trigger('transition');
      return false;
    });
  
    // don't allow click events on disabled links
    $('a.disabled').click(function() {
      return false;
    });

    // disable done button until user configures a journey
    $(':input').change(function() {
      var input = $(this);
      var link = input.parents('.page').find('a.back');
      var form = input.parents('form').first();
      form.data('dirty', true);
  
      link.addClass('disabled');
      form.find('li').each(function() {
        var selected = $(this).find(":selected");
        var value = selected.first().attr('value');
        // if you've selected at least one journey, and the origin and destination don't match
        if ((selected.filter("[value='']").length == 0) && (selected.filter("[value='" + value + "']").length < 2))
          link.removeClass('disabled');
      });
    });
  
    // handle transition event
    $('a.fx').bind('transition', function() {
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
        $('.content').find('#' + id).remove();
        $('.content').append('<div id="' + id + '" class="page"></div>');
        link.addClass('disabled');
        $.get(href, function(data) {
          fx($('#' + id).append(data));
          link.attr('href', '#' + id).removeClass('disabled');
          handlers();
        });
      }
      return false;
    });

    // ajax post settings form and load favourites
    $('.submit').click(function() {
      var link = $(this).addClass('disabled');
      var form = link.parents('.page').find('form');
      if (form.data('dirty')) {
        $.post(form.attr('action'), form.serialize(), function(data) {
          if ($.browser.msie) {
            location.href = "/";
          } else {
            loadFavourites(function() {
              handlers();
              if ($('#favourites').length == 0) {
                link.addClass('disabled');
              } else {
                link.trigger('transition').removeClass('disabled');
                form.data('dirty', false)
              }
            });
          }
        });
      } else {
        link.trigger('transition').removeClass('disabled');
      }
      return false;
    });
  };
  
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
    $.get('/', function(data) {
      $('#favourites').remove();
      $('.content').append(data);
      if (callback) callback();
    });
  }
    
  var loadMoreJourneys = function(journeys, limit) {
    var prev = journeys.find('.journey').last();
    var href = journeys.find('a.loader').attr('href');
    if (href) {
      href = href.replace(/^(.*)=(.*)$/, '$1=' + prev.attr('title'));
      if (limit && limit > 0) href = href + '&limit=' + limit;

      $.get(href, function(data) {
        var id = generateID(href);
        $('#' + id).remove();
        $('.content').append('<div id="' + id + '"></div>');
        $('#' + id).append(data);
        prev.after($('#' + id).find('.journey').hide().slideDown('slow', function() {
          $('#' + id).remove();
          var loader = journeys.find('a.loader');
          loader.attr('href', loader.attr('href').replace(/^(.*)=(.*)$/, '$1=' + journeys.find('.journey').last().attr('title')));
        }));
        // reattach handlers
        handlers();
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
    $('.journey .eta').each(function() {
      var eta = $(this);
      var journey = eta.parents('.journey');
      var departureDate = new Date();
      var currentDate = new Date();
      departureDate.setTime(eta.parent().find('.time').first().attr('data-time'));
    
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
  
  setActivePage(setMinHeight);
  updateETAs();
  handlers();
  
  // show iphone hint
  if ($.support.iPhone && !$.support.Standalone) {
    window.setTimeout(function() {
      $('body > .footer').slideToggle('slow');
      window.setTimeout(function() { 
        $("body > .footer").slideToggle("slow"); 
      }, 8000);
    }, 1500);
  }
});