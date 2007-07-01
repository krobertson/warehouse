Permissions = {
  removeMember: function(user_id) {
    if(!confirm("Are you sure you wish to remove this member?")) return
    if(user_id == 'anon')
      new Ajax.Request("/permissions/anon", {method:'delete'});
    else
      new Ajax.Request("/users/" + user_id + "/permissions", {method:'delete'});
  },
  
  remove: function(line) {
    if(line.getAttribute('id')) {
      if(!confirm("Are you sure you wish to remove this permission?")) return
      new Ajax.Request("/permissions/" + line.getAttribute('id').match(/(\d+)$/)[0], {method:'delete'});
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
    newpath.setAttribute('id', 'permission_paths_' + index + '_path')
    newpath.setAttribute('name', 'permission[paths][' + index + '][path]')
    newsel.setAttribute('name', 'permission[paths][' + index + '][full_access]')
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
    if(this.firstRun) progress = this.options.startProgress;
    console.log(progress);
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
      $(t).observe('click', this.toggle.bindAsEventListener(this));
    }.bind(this));
    this.cancelBtn.observe('click', this.hide.bindAsEventListener(this));
  },
  
  toggle: function(event) {
    Event.stop(event);
    if(this.overlay.visible()) {
      this.hide();
    } else {
      this.show();
    }
  },
  
  hide: function(event) {
    if(event) Event.stop(event);
    new Fx.Style(this.sheetContent, 'margin-top', {
      duration: (this.sheetHeight * 2) + 500,
      transition: Fx.Transitions.expoOut,
      onComplete: function() { this.overlay.hide(); }.bind(this)
    })._start(0, -(this.sheet.getHeight()));    
  },
  
  show: function(event) {
    if(Sheet.Current && Sheet.Current.overlay.visible()) Sheet.Current.hide()
    Sheet.Current = this;
    this.overlay.show();
    new Fx.Style(this.sheetContent, 'margin-top', {
      duration: (this.sheetHeight * 2), 
      transition: Fx.Transitions.expoOut
    })._start(-(this.sheetHeight), 0);
  },
  
  build: function(namespace) {
    this.overlay = new Element('div', {id: namespace + '-overlay'});
    this.overlay.hide();
    // Firefox wiggles the text if this is `fixed` so we make it absolute to prevent
    // it from turning the page into water.
    if(!Prototype.Browser.WebKit) this.overlay.setStyle({position: 'absolute'});
    this.sheetContent = new Element('div', {id: namespace + '-content'});
    this.overlay.addClassName('overlay');
    this.sheetContent.addClassName('overlay-content');
    this.sheetContent.appendChild(this.sheet);
    this.overlay.appendChild(this.sheetContent);
    this.sheetContent.setStyle({'margin-top': -(this.sheetHeight) + "px"});
    $('container').appendChild(this.overlay);
  }
};

Event.addBehavior({
  'a.addpath:click': function(event) {
    var a = Event.findElement(event, 'a');
    Permissions.add(a.up());
    return false;
  },
  
  'a.delpath:click': function() {
    Permissions.remove(this.up());
  }
});
