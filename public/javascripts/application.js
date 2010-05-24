$.jQTouch({
        icon: '/images/logo_60x60.png',
        statusBar: 'black',
        preloadImages: [
            '/jqtouch/themes/custom/img/chevron_white.png',
            '/jqtouch/themes/custom/img/bg_row_select.gif',
            '/jqtouch/themes/custom/img/back_button_clicked.png',
            '/jqtouch/themes/custom/img/button_clicked.png'
            ]
    });
    

/*
$(document).ready(function() {
  var bindEvents = function() {
    $('.fav.settings .submit').click(function(e) {
      $(this).parents('.fav.settings').children('form').submit();
      //e.preventDefault();
    });
    $('.fav.settings .submit').tap(function(e) {
      $(this).parents('.fav.settings').children('form').submit();
      //e.preventDefault();
    });  
  }
  
  bindEvents();
  
  $('.fav.settings form').submit(function() {
    var formdata = $(this).serialize();
    var title = $(this).parent().attr('title');
    $.post("/favourite", formdata, function(data) {
      $('div.fav[title="' + title + '"]').remove();
      $('body').prepend(data);
      $('div.fav.original[title="' + title + '"]').addClass('current');
      bindEvents();
    });
    return false;
  });
  
  
});
*/
