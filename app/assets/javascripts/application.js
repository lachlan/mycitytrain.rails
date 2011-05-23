// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require libs/underscore
//= require libs/backbone
//= require extensions/string
//= require extensions/date
//= require_tree .

/** Main application object, container for models, views and controllers */
var App = {
  Models: {}
, Views: {}
, Controllers: {}
}

$(function() {
  $.support.WebKitAnimationEvent = (typeof WebKitTransitionEvent == "object");
  var active = 'active';
  // handle transitions automatically on non-disabled and non-submit links
  $('body').delegate('a.fx:not(.disabled):not(.submit)', 'click', function() { 
    $(this).parents('.page').attr('data-fx', $(this).attr('class'));
  });

  var transition = function(to, callback) {
    var effects = 'fx in out flip slide pop cube swap slideup dissolve fade reverse';
    var from = $('.page:visible');
    to = $(to)

    var effect = from.attr('data-fx');
    if (_.isEmpty(effect)) effect = 'fx fade'; //default effect
    from.removeAttr('data-fx');

    $(':focus').blur();

    $(from).add(to).removeClass(effects).addClass(effect);

    var finished = function() {
      from.removeClass(active).add(to).removeClass(effects);
      if (_.isFunction(callback)) callback(to);
    }

    to.one('webkitAnimationEnd', finished);
    to.addClass(active).addClass('in');
    from.addClass('out');

    if (!$.support.WebKitAnimationEvent) {
      finished();
    }
  }

  var flash = function(element, options, callback) {
    element = $(element);
    var timeout = 750;

    var blink = function(element, duration, callback) {
      element.animate({ opacity: 0.5 }, duration, 'linear', function() {
        element.animate({ opacity: 1 }, duration, 'linear', function() {
          if (!_.isUndefined(callback) && _.isFunction(callback)) callback();
        });
      });
    }

    blink(element, timeout, function() {
      blink(element, timeout, function() {
        blink(element, timeout, function() {
          element.slideUp('slow', function() {
            element.remove();
          });
        });
      });
    });
  };
  
  /** All the application models: location, locations, journey, journeys, favourite, favourites */
  App.Models.Location = Backbone.Model.extend()
  
  App.Models.Locations = Backbone.Collection.extend({
    model: App.Models.Location
  , url: '/data/locations.json'
  , parse: function(response) {
      var self = this
      return _(response).map(function(item) {
        return { name: item }
      })
    }   
  , search: function(term, exact) {
      var pattern = new RegExp('^' + term, 'i')
        , matches = new Array()
      if (exact) pattern = new RegExp('^' + term + '$', 'i')

      this.each(function(location) {
        if (location.get('name').match(pattern)) matches.push(location.get('name'))
      })
      return matches
    }
  })
  
  App.Models.Journey = Backbone.Model.extend({
    initialize: function() {
      this.set({ 
          departure: Date.parse(this.get('departure'))
        , arrival: Date.parse(this.get('arrival'))
        , origin: this.get('origin').unescape().toTitleCase()
        , destination: this.get('destination').unescape().toTitleCase()
        }
      )
      this.unset('eta')
    }
  , eta: function(unit) {
      if (_(unit).isUndefined()) unit = 'words'
      return Date.now().duration(this.get('departure'), unit)
    }
  , className: function() {
      var name = ''
        , eta = this.eta('minutes')

      if (eta <= '5')
        name = 'now'
      else if (eta <= '10')
        name = 'soon'
  
      return name
    }
  , toJSON: function() {
      return _(Backbone.Model.prototype.toJSON.call(this)).extend({ 
        eta: this.eta()
      , className: this.className()
      })
    }
  })

  App.Models.Journeys = Backbone.Collection.extend({ 
    model: App.Models.Journey
  , limit: 4
  , initialize: function(models, options) {
      _(this).bindAll()
      _(this).extend(
        { 
          origin: options.origin
        , destination: options.destination
        , inverse: options.inverse
        }
      )
    
      if (_.isUndefined(this.inverse)) {
        _(this).extend(
          {
            inverse: new App.Models.Journeys([], 
              { origin: this.destination
              , destination: this.origin
              , inverse: this 
              }
            )
          }
        )
      }
    }
  , url: function(limit) {
      if (_(limit).isUndefined()) limit = this.limit
      return ('/data/' 
             + this.origin.escape()
             + '/' 
             + this.destination.escape() 
             + '.json?limit='
             + limit
             ).toLowerCase()
    }
  , parse: function(response) {
      var self = this
      return _(response).map(function(row) {
        return { origin: self.origin
               , destination: self.destination
               , departure: row[0]
               , arrival: row[1]
               }
        }
      )
    }
  , next: function(callback, limit) {
      var self = this
        , journeys = new App.Models.Journeys([], 
            { 
              origin: self.origin
            , destination: self.destination 
            }
          )

      journeys.url = self.url(limit)    
      if (self.length > 0) journeys.url += '&after=' + JSON.stringify(self.last().get('departure')).escape()
  
      journeys.fetch(
        { 
          success: function() {
            self.add(journeys.toJSON())
            if (_(callback).isFunction()) callback()
          }
        }
      )
    }
  , remove: function(models, options) {
      Backbone.Collection.prototype.remove.call(this, models, options)
    }
  , expire: function(callback) {
      var self = this
      if (this.length === 0) {
        this.next(callback)
      } else {
        self.each(function(journey) {
          // trigger an update to the eta
          journey.change()
          // remove it if its departed or about to depart in less than a minute
          if (journey.get('departure') <= (new Date(Date.now().getTime() + 59 * 1000))) self.remove(journey)
        })
        // after removing some services, automatically refresh the collection if its below its limit
        if (this.length < this.limit) 
          this.next(callback, this.limit - this.length)
        else if (_(callback).isFunction())
          callback()
      }
    }
  , comparator: function(service) {
      return service.get('departure')
    }
  })

  App.Models.Favourite = Backbone.Model.extend({
    initialize: function(attributes) {
      var self = this;
      self.journeys = new App.Models.Journeys([], { origin: self.get('origin'), destination: self.get('destination') }) 
      
      if (attributes.inverse) {
        self.unset('inverse')
        self.inverse = attributes.inverse
      } else {
        self.inverse = new App.Models.Favourite({
          origin: self.get('destination')
        , destination: self.get('origin')
        , inverse: self
        })
      }
    }
  , url: function(hash) {
      if (_(hash).isUndefined()) hash = true;
      var prefix = hash ? '/#' : ''
      return prefix
           + '/' 
           + (this.get('origin') + '/' + this.get('destination'))
           .escape()
           .toLowerCase()
    }
  , id: function() {
      return (this.get('origin') + '_' + this.get('destination'))
             .escape()
             .toLowerCase()
    }
  , expire: function() {
      this.journeys.expire()
      this.inverse.journeys.expire()
    }
  })

  App.Models.Favourites = Backbone.Collection.extend({ 
    model: App.Models.Favourite
  , _cookie: 'favourites'
  , inverse: function() {
      return new App.Models.Favourites(this.map(function(item) {
        return item.inverse
      }))
    }
  , save: function() {
      $.cookie(this._cookie, JSON.stringify(this), { expires: 7 * 52 * 25 })
    }
  , fetch: function() {
      var json = $.cookie(this._cookie)
      if (_(json).isString() && !_(json).isEmpty()) {
        var array = JSON.parse(json)
      
        if (_(array).isArray()) {          
          array = _(array).select(function(item) {
            return _(item).isArray() && _(item[0]).isString() && _(item[1]).isString() && !_(item[0]).isEmpty() && !_(item[1]).isEmpty();
          })
        
          this.refresh(_(array).map(function(item) {
            return { origin: item[0]
                   , destination: item[1] 
                   }
          }))
        }
      }    
    }
  , toJSON: function() {
      return this.map(function(model) {
        return [model.get('origin'), model.get('destination')]
      })
    }
  , expire: function() {
      this.each(function(favourite) {
        favourite.expire()
      })
    } 
  })  
  
  /** All the application views: journey, journeys, page, about, settings, favourite, favourites */
  App.Views.Journey = Backbone.View.extend({
    tagName: 'li'
  , className: 'journey'
  , template: _.template($('#journey-template').html())
  , initialize: function() {
      _(this).bindAll('render')
      this.model.bind('change', this.render)
    }
  , render: function() {
      $(this.el).html(this.template(this.model.toJSON()))
      return this
    }
  })

  App.Views.Journeys = Backbone.View.extend({
    tagName: 'ol'
  , initialize: function() {
      _(this).bindAll('render', 'add', 'remove')
      this.collection.bind('refresh', this.render)
      this.collection.bind('add', this.add)
      this.collection.bind('remove', this.remove)
    }
  , render: function() {
      $(this.el).empty()
      var self = this
      self.collection.each(function(item) {
        self.add(item, false)
      })
      return self
    }
  , add: function(item, reveal) {      
      if (!_(reveal).isBoolean()) reveal = true
    
      var html = $((new App.Views.Journey({ model: item, id: item.cid })).render().el)
      if (reveal) html.hide()
      $(this.el).append(html)
      if (reveal) html.slideDown()
    }
  , remove: function(item) {
      flash($(this.el).find('#' + item.cid))
    }
  })

  App.Views.Page = Backbone.View.extend({
    tagName: 'div'
  , className: 'page'
  , initialize: function() {
      _(this).bindAll('render')
    }
  , render: function() {
      $(this.el).empty()
                .append($('<div id="header"></div>').html(this.header()))
                .append($('<div id="content"></div>').html(this.content()))
                .append($('<div id="footer"></div>').html(this.footer()))
      return this
    }
  , header: function() {
      return _.template($('#header-template').html())
    }
  , content: function() {
      return $('')
    }
  , footer: function() {
      return _.template($('#footer-template').html());
   }
  })

  App.Views.About = App.Views.Page.extend({
    id: 'about'
  , events: {
       'click #header-right-button': 'done'
    }
  , header: function() {
       return _.template($('#header-template').html())
    }
  , content: function() {
       return _.template($('#about-template').html())
    }
  , footer: function() {
       return $('')
    }
  , done: function(e) {
       history.back()
       e.preventDefault()
    }
  })
  
  App.Views.Settings = App.Views.Page.extend({
    id: 'settings'
  , events: {
      'click #header-right-button': 'done'
    }
  , header: function() {
      return _.template($('#header-template').html())
    }
  , content: function() {
      return _.template($('#settings-template').html(), { collection: this.collection.toJSON() })
    }
  , footer: function() {
      return $('')
    }
  , done: function(e) {
      // save changes!
      var self = this
        , changed = false
        , models = []
        , count = 0      
      
      self.$('form li').each(function() {
        var origin = $(this).find('input.origin').attr('value').trim().toTitleCase()
          , destination = $(this).find('input.destination').attr('value').trim().toTitleCase()
        
        if (!_(origin).isEmpty() && !_(destination).isEmpty()) {
          var favourite = self.collection.find(function(item) {
            return _(origin).isEqual(item.get('origin')) && _(destination).isEqual(item.get('destination'))
          })
        
          if (_(favourite).isUndefined()) {
            changed = true
            models.push(new App.Models.Favourite({ origin: origin, destination: destination }))
          } else {
            models.push(favourite)
          }
          count++
        }
      })
      if (changed || count < self.collection.length) {
        self.collection.refresh(models)    
        self.collection.save()
        window.location = '/' // reload the app?
      } else {
        history.back()
      }
      e.preventDefault()
    }    
  });
  
  App.Views.Favourite = App.Views.Page.extend({
    initialize: function(options) {
      _(this).bindAll('header', 'footer', 'content', 'load')    
      this.partial = new App.Views.Journeys({ collection: this.model.journeys })
      this.inverse = false || options.inverse
    }
  , events: {
      'click button': 'load'
    }
  , header: function() {
      return _.template($('#journey-header-template').html(), { url: this.model.inverse.url(), inverse: this.inverse })
    }
  , content: function() {
      return $('<div class="journeys"></div>').append(this.partial.render().el).append(_.template($('#load-template').html())())
    }
  , load: function() {
      var finished = false
      var button = this.$('button')
      var expire = button.attr('disabled', 'disabled').hasClass('expire-only')
      
      var animateLoader = function(element, isFinished) {
        var element = $(element)
          , className = 'transparent'
          , elements = element.find('span')
          , finished = isFinished

        if (_.isFunction(isFinished)) finished = isFinished()
        
        if (finished) {
          elements.removeClass(className)
        } else {
          var invisible = elements.filter('.' + className).first()
          if (invisible.length > 0) {
            invisible.removeClass(className)
          } else {
            elements.addClass(className).first().removeClass(className)
          }
          window.setTimeout(function() { animateLoader(element, isFinished) }, 250)
        }
      }
      
      // animate the loading button, but only after 250 ms has passed in case action is super quick
      window.setTimeout(function() {
        animateLoader(button, function() { return finished })
      }, 250);
      
      if (expire) {
        this.model.journeys.expire(function() {
          button.removeClass('expire-only').removeAttr('disabled')
          finished = true
        })
      } else {
        this.model.journeys.next(function() {
          button.removeAttr('disabled')
          finished = true
        })        
      }
    }
  , footer: function() {
      return _.template($('#footer-template').html(), { collection: this.collection, index: this.collection.indexOf(this.model) })
    }
  })

  App.Views.Favourites = Backbone.View.extend({
    tagName: 'div'
  , id: 'favourites'  
  , initialize: function(options) {
      var self = this
      self.collection.bind('refresh', self.render)
      self.collection.bind('add', self.add)
      self.collection.bind('remove', self.remove)

      self.partials = self.collection.map(function(item) {
        return new App.Views.Favourite({ model: item, id: item.cid, collection: self.collection })
      })
      self.partials = self.partials.concat(self.collection.inverse().map(function(item) {
        return new App.Views.Favourite({ model: item, id: item.cid, collection: self.collection.inverse(), inverse: true })
      }))
    }
  , render: function() {
      var self = this
      $(self.el).empty()
      _(self.partials).each(function(partial) {
        $(self.el).append(partial.render().el)
      })
      return self    
    }
  , add: function(item) {
      //this.partials.push(new App.Views.Favourite({ model: item, id: item.cid collection: this.collection }))
      //this.partials.push(new App.Views.Favourite({ model: item.inverse, id: item.inverse.cid collection: this.collection.inverse() }))
      //this.render()
    }
  , remove: function(item) {
      $(this.el).remove('#' + item.cid)
    }
  })
  
  /** All the application controllers: about, settings, journey */
  App.Controllers.About = Backbone.Controller.extend({
    routes: {
      '/about': 'about'
    }
  , initialize: function(options) {
      this.view = new App.Views.About()
      $('body').append(this.view.render().el)
    }
  , about: function() {
      transition('#' + this.view.id)
    }
  })

  App.Controllers.Settings = Backbone.Controller.extend({
    routes: {
      '/settings': 'settings'
    }
  , initialize: function(options) {
      this.locations = options.locations
      this.view = new App.Views.Settings({ collection: options.collection })
      $('body').append(this.view.render().el)
    }
  , settings: function() {
      if (this.locations.length === 0) this.locations.fetch()
      transition('#' + this.view.id)
    }  
  })

  App.Controllers.Journey = Backbone.Controller.extend({  
    routes: {
      '': 'root'
    , '/': 'root'
    , '/:origin/:destination': 'journey'
    }
  , initialize: function(options) {
      this.collection = options.collection
      this.view = new App.Views.Favourites({ collection: this.collection })
    
      // pre-render the element on the page, it won't be displayed until a journey url is accessed
      var element = this.view.render().el
      $('body').append(element)
    }
  , root: function() {
      var hash = '/settings' // redirect to settings when no favourites exist
      if (this.collection.length > 0) hash = this.collection.first().url(false)
      window.location.hash = hash
    }
  , journey: function(origin, destination) {
      origin = origin.unescape().toTitleCase()
      destination = destination.unescape().toTitleCase()
      var self = this
        , match = function(item) {
            return _(origin).isEqual(item.get('origin')) && _(destination).isEqual(item.get('destination'))
          }
        , item = self.collection.find(match)
      
      if (_(item).isUndefined()) item = self.collection.inverse().find(match)
      var element = $('#' + item.cid)
      transition(element)
    }
  })
  
  _(App).extend({
    favourites: new App.Models.Favourites()
  , locations: new App.Models.Locations()
  , initialize: function() {
      this.favourites.fetch()
      //this.locations.fetch()

      var about = new App.Controllers.About()
        , settings = new App.Controllers.Settings({ collection: this.favourites, locations: this.locations })
        , journeys = new App.Controllers.Journey({ collection: this.favourites })
        , self = this

      Backbone.history.start()

      // set up the autocomplete suggestions on the form input fields
      $('input.origin, input.destination').autocomplete({
      	minLength: 1,
      	source: function(request, response) {
      	  response(self.locations.search(request.term))
      	}
      })

      var self = this
      var run = function() {
        $('button:not(.disabled)').addClass('expire-only').click()
        window.setTimeout(run, (Date.now().next('minute') - Date.now()))
      }
      run()
    }
  })
  
  /** start the app */
  App.initialize()
})