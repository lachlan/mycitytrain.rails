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
      link.replaceWith(data);
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
    
  // hide address bar
  window.scrollTo(0, 1);
});