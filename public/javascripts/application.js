

Permissions = {
  removeMember: function(user_id) {
    if(!confirm("Are you sure you wish to remove this member?")) return
    if(user_id == 'anon')
      new Ajax.Request("/permissions/anon", {method:'delete'});
    else
      new Ajax.Request("/users/" + user_id + "/permissions", {method:'delete'});
  },
  
  remove: function(line) {
    if(line.readAttribute('id')) {
      if(!confirm("Are you sure you wish to remove this permission?")) return;
      new Ajax.Request("/permissions/" + line.readAttribute('id').match(/(\d+)$/)[0], {method:'delete'});
    } else {
      line.remove();
    }
  },
  
  add: function(line) {
    var index   = line.parentNode.getElementsByTagName('p').length
    var newline = $(line).duplicate();
    var newsel  = newline.down('select');
    var newpath = newline.down('input');
    var newid   = newline.down('input', 1);
    newpath.value = '';
    newpath.writeAttribute('id', 'permission_paths_' + index + '_path')
    newpath.writeAttribute('name', 'permission[paths][' + index + '][path]')
    newsel.writeAttribute('name', 'permission[paths][' + index + '][full_access]')
    if(newid) newid.remove();
    
    if(!Prototype.Browser.IE) {
      Event.addBehavior.unload(); 
      Event.addBehavior.load(Event.addBehavior.rules)
    }
  }
};

var Importer = Class.create();
Importer.prototype = {
  initialize: function(repoid, options) {
    this.repoId = repoid;
    this.options = $H({
      onImported: Prototype.emptyFunction,
      onStep: Prototype.emptyFunction,
      startProgress: 0
    }).merge(options || {});
    this.firstRun = true;
  },
  
  step: function(progress) {
    console.log(progress);
    if(this.firstRun) progress = this.options.startProgress;
    if(progress < 100) {
      new Ajax.Request('/repositories/' + this.repoId + '/sync', {
        method: 'post',
        onSuccess: function(transport) {
          this.firstRun = false;
          var prog = transport.responseText;
          this.step(prog);
          this.options.onStep.call(this, prog);
        }.bind(this),
        
        on500: function() {
          $('import-progress').update('A 500 error occurred, please check your logs');
        }
      });
    } else {
      this.options.onImported.call(this);
    }
  }
}

Element.addMethods({
  duplicate: function(element) {
    element = $(element);    
    var clone = element.cloneNode(true);
    element.parentNode.appendChild(clone);
    return clone;
  }
});

// Create OSX-style Sheets  
var Sheet = Class.create();
Sheet.Cache = [];
Sheet.Current = null;
Sheet.prototype = {
  initialize: function(element, trigger, options) {
    this.sheet = $(element);
    if(!this.sheet) return;
    this.sheetHeight = this.sheet.getHeight();
    this.cancelBtn = document.getElementsByClassName('cancelbtn', this.sheet)[0];   
    this.trigger = trigger;
    this.overlay;
    this.build(element);
    this.addObservers();
  },
  
  addObservers: function() {
    [this.trigger].flatten().each(function(t) {
      $(t).observe('click', this.toggle.bind(this));
    }.bind(this));
    this.cancelBtn.observe('click', this.hide.bind(this));
  },
  
  toggle: function(event) {
    event.stop();
    if(this.overlay.visible())
      this.hide();
    else 
      this.show();
  },
  
  hide: function(event) {
    if(event) event.stop();
    new Fx.Style(this.sheetContent, 'margin-top', {
      duration: (this.sheetHeight * 2) + 500,
      transition: Fx.Transitions.expoOut,
      onComplete: function() { this.overlay.hide(); }.bind(this)
    })._start(0, -(this.sheet.getHeight()));    
  },
  
  show: function(event) {
    if(Sheet.Current && Sheet.Current.overlay.visible()) Sheet.Current.hide()
    Sheet.Current = this;
    Sheet.Current.overlay.show();
    this.sheet.show();
    new Fx.Style(this.sheetContent, 'margin-top', {
      duration: (this.sheetHeight * 2), 
      transition: Fx.Transitions.expoOut
    })._start(-(this.sheetHeight), 0);
  },
  
  build: function(namespace) {
    this.overlay = new Element('div', {id: namespace + '-overlay'});
    this.overlay.hide();
    // Firefox wiggles the text if this is `fixed` so we make it absolute to prevent
    // it from turning the page into water.  Not as useful as Safari and IE 7, but it 
    // works good.
    var IE7 = navigator.userAgent.indexOf('MSIE 7') > -1
    if(!Prototype.Browser.WebKit && !IE7)
      this.overlay.setStyle({position: 'absolute'});

    this.sheetContent = new Element('div', {id: namespace + '-content'});
    this.overlay.addClassName('overlay');
    this.sheetContent.addClassName('overlay-content');
    this.sheetContent.appendChild(this.sheet);
    this.overlay.appendChild(this.sheetContent);
    this.sheetContent.setStyle({marginTop: -(this.sheetHeight) + "px"});
    $('container').appendChild(this.overlay);
  }
};

// http://redhanded.hobix.com/inspect/showingPerfectTime.html
/* other support functions -- thanks, ecmanaut! */
var strftime_funks = {
  zeropad: function( n ){ return n > 9 ? n : '0' + n; },
  a: function(t) { return ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][t.getDay()] },
  A: function(t) { return ['Sunday','Monday','Tuedsay','Wednesday','Thursday','Friday','Saturday'][t.getDay()] },
  b: function(t) { return ['Jan','Feb','Mar','Apr','May','Jun', 'Jul','Aug','Sep','Oct','Nov','Dec'][t.getMonth()] },
  B: function(t) { return ['January','February','March','April','May','June', 'July','August',
      'September','October','November','December'][t.getMonth()] },
  c: function(t) { return t.toString() },
  d: function(t) { return this.zeropad(t.getDate()) },
  H: function(t) { return this.zeropad(t.getHours()) },
  I: function(t) { return this.zeropad((t.getHours() + 12) % 12) },
  m: function(t) { return this.zeropad(t.getMonth()+1) }, // month-1
  M: function(t) { return this.zeropad(t.getMinutes()) },
  p: function(t) { return this.H(t) < 12 ? 'AM' : 'PM'; },
  S: function(t) { return this.zeropad(t.getSeconds()) },
  w: function(t) { return t.getDay() }, // 0..6 == sun..sat
  y: function(t) { return this.zeropad(this.Y(t) % 100); },
  Y: function(t) { return t.getFullYear() },
  '%': function(t) { return '%' }
};

Date.prototype.strftime = function (fmt) {
    var t = this;
    for (var s in strftime_funks) {
        if (s.length == 1 )
            fmt = fmt.replace('%' + s, strftime_funks[s](t));
    }
    return fmt;
};

// http://twitter.pbwiki.com/RelativeTimeScripts
Date.distanceOfTimeInWords = function(fromTime, toTime, includeTime) {
  var delta = parseInt((toTime.getTime() - fromTime.getTime()) / 1000);
  if(delta < 60) {
      return 'less than a minute ago';
  } else if(delta < 120) {
      return 'about a minute ago';
  } else if(delta < (45*60)) {
      return (parseInt(delta / 60)).toString() + ' minutes ago';
  } else if(delta < (120*60)) {
      return 'about an hour ago';
  } else if(delta < (24*60*60)) {
      return 'about ' + (parseInt(delta / 3600)).toString() + ' hours ago';
  } else if(delta < (48*60*60)) {
      return '1 day ago';
  } else {
    var days = (parseInt(delta / 86400)).toString();
    if(days > 30) {
      var fmt  = '%B %d'
      if(toTime.getYear() != fromTime.getYear()) { fmt += ', %Y' }
      if(includeTime) fmt += ' %I:%M %p'
      return fromTime.strftime(fmt);
    } else {
      return days + " days ago"
    }
  }
}

Date.prototype.timeAgoInWords = function() {
  var relative_to = (arguments.length > 0) ? arguments[1] : new Date();
  return Date.distanceOfTimeInWords(this, relative_to, arguments[2]);
}

// for those times when you get a UTC string like 18 May 09:22 AM
Date.parseUTC = function(value) {
  var localDate = new Date(value);
  var utcSeconds = Date.UTC(localDate.getFullYear(), localDate.getMonth(), localDate.getDate(), localDate.getHours(), localDate.getMinutes(), localDate.getSeconds())
  return new Date(utcSeconds);
}

Event.addBehavior({
  
  'a.addpath:click': function(event) {
    var a = Event.findElement(event, 'a');
    Permissions.add(a.up());
    return false;
  },
  
  'a.delpath:click': function() {
    Permissions.remove(this.up());
  },
  
  'span.time': function() {
    this.innerHTML = Date.parseUTC(this.innerHTML).timeAgoInWords();
  },
  
  'a#as-toggle:click': function(event) {
    Event.stop(event);
    var as = $('advanced-settings'); as.toggle();
    as.visible() ? this.update('Less settings&hellip;') : this.update('More settings&hellip;')
  },
  
  '#settings-mail-type:change': function() {
    if($F(this) == 'smtp') {
      $('mail-sendmail').hide();
      $('mail-smtp').show();
    } else {
      $('mail-smtp').hide();
      $('mail-sendmail').show();
    }
  },
  
  '#diffnum form:submit': function(event) {
    var field = this.down('input');
    var match = $F(field).match(/\d+/);
    if(match) {
      location.href = "/changesets/" + match
    } else {
      field.value = "#";
    }
    Event.stop(event);
  }
  
});
