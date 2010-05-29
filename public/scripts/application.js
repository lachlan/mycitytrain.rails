$(document).ready(function() {
  $.support.WebKitAnimationEvent = (typeof WebKitTransitionEvent == "object");
  
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
    
  $('a.fx').live('click', function() {
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
    
  $('a.replace').live('click', function() {
    var link = $(this);
    $.get(link.attr('href'), function(data) {
      if (link.hasClass('parent')) link = link.parent();
      // TODO: animating this would be nice
      link.replaceWith(data).animate(
      {
        width: ['toggle', 'swing'],
        height: ['toggle', 'swing'],
        opacity: 'toggle'
      }, 5000, 'linear', function() {
        $(this).after('<div>Animation complete.</div>');
      });
    });
    return false; 
  });
  
  $(':input').live('change', function() {
    var form = $(this).parents('form').first();
    $.post(form.attr('action'), form.serialize(), function(data)  {
      loadFavourites();
    });
  });
  
  /*
  $('*').swipe({
    swipeLeft: function() { 
      var target = $('.page.active footer li.active').next();
      if (target) target.children('a').click();
    },
    swipeRight: function() { 
      var target = $('.page.active footer li.active').prev();
      if (target) target.children('a').click();
    }
  });
  */
  // hide address bar
  window.scrollTo(0, 1);
});