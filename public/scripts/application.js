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
  
  if (unsigned_duration >= 0 && unsigned_duration <= 60) {
    phrase = "now";
  } else if (unsigned_duration >= 61 && unsigned_duration <= 3599) {
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

$(document).ready(function() {
  $.support.WebKitAnimationEvent = (typeof WebKitTransitionEvent == "object");

  var journey_limit = 5;
  var active = 'active';
  var effects = 'fx in out flip slide pop cube swap slideup dissolve fade reverse';
  
  var setActivePage = function() {
    var activePages = $('.page.' + active);
    if (activePages.length > 0)
      activePages.removeClass(active).first().addClass(active);
    else
      $('.page').first().addClass(active);
    $('.page').css('min-height',$(window).height());
  }

  var loadFavourites = function(callback) {
    $.get('/', function(data) {
      $('#favourites').remove();
      $('body').append(data);
      if (callback) callback();
    });
  }
  
  var loadSettings = function(callback) {
    $.get('/favourites', function(data) {
      $('body').append(data);
      if (callback) callback();
    });
  }

  // load page contents asynchronously
  var loadBody = function() {
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
    
  loadBody();
    
  $('a.fx:not(.disabled)').live('click', function() {
    var effect = $(this).attr('class');
    var linker = $(this).parents('.page').last();    
    var href = $(this).attr('href');
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
      // load external links via ajax directly into page body
      var element = $('body');
      var id = "__ajax_results__";
      if (href.lastIndexOf('#') > -1) {
        id = href.substring(href.lastIndexOf('#'), href.length);
        element.children(id).remove();
      } else {
        element.children('#' + id).remove();
        element.append('<section id="' + id + '" class="page"></section>');
        id = '#' + id;
        element = $(id);
      }
      $.get(href, function(data) {
        element.append(data);
        fx($(id));
      });
    }
    return false;
  });
    
  $('a.replace:not(.disabled)').live('click', function() {
    var link = $(this);
    $.get(link.attr('href'), function(data) {
      if (link.hasClass('parent')) link = link.parent();
      // TODO: animating this would be nice  
      var id = '__replace_results__';
      $('#' + id).remove();
      $('body').append('<section id="' + id + '"></section>');
      $('#' + id).append(data);
      link.after($('#' + id).children().hide().slideDown());
      link.remove();
    });
    return false; 
  });
  
  $('a.disabled').live('click', function() {
    return false;
  })
  
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
    
    if (!link.hasClass('disabled')) {
      link.addClass('disabled');
      $.post(form.attr('action'), form.serialize(), function(data)  {
        loadFavourites(function() {
          if ($('#favourites').length == 0)
            link.addClass('disabled');
          else
            link.removeClass('disabled');
        });
      });
    }
  });
  
  window.setInterval(function() {
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
      
      if (duration >= 0 || journey.hasClass('detail')) {
        eta.html(durationInWords(duration));
      } else {
        journey.animate({opacity:0.5},500,'linear',function() {
          $(this).animate({opacity:1},500,'linear',function() {
            $(this).slideUp('slow', function() {
              var parent = $(this).parent();
              var link = $(this).parent().find('a.replace');
              var href = link.attr('href');
              $(this).remove();
              var limit = journey_limit - parent.find('.journey').length;
              if (limit > 0) link.attr('href', href + '?limit=' + limit).click();
            })
          });
        });
      }
    });
  }, 1000);
    
  // hide address bar
  window.scrollTo(0, 1);
});