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
    var index   = line.parentNode.getElementsByTagName('dd').length
    var newline = line.duplicate();
    var newsel  = newline.down('select');
    var newpath = newline.down('input');
    var newid   = newline.down('input', 1);
    newline.setAttribute('id', '');
    newpath.value = '';
    newpath.setAttribute('id', 'permission_paths_' + index + '_path')
    newpath.setAttribute('name', 'permission[paths][' + index + '][path]')
    newsel.setAttribute('name', 'permission[paths][' + index + '][full_access]')
    if(newid) newid.remove();
    Event.addBehavior.unload(); Event.addBehavior.load(Event.addBehavior.rules)
  }
};

Element.addMethods({
  duplicate: function(element) {
    element = $(element);
    var clone = element.cloneNode(true);
    element.parentNode.appendChild(clone);
    return clone;
  }
});

var Sheet = Class.create();
Sheet.prototype = {
  initialzie: function(element, trigger, options) {
    this.sheet = $(element);
    this.trigger = $(trigger);
  }
}

Event.addBehavior({
  'a.addpath:click': function() {
    Permissions.add(this.up());
    return false;
  },
  
  'a.delpath:click': function() {
    Permissions.remove(this.up());
  },
  
  'a#bookmark:click': function(event) {
    $('bookmark-form').show();
    new Fx.Style('bookmark-content', 'margin-top', {
      duration: 400, 
      transition: Fx.Transitions.expoOut
      })._start(-452, 0);
  },
  
  '#login:click': function(event) {
    Event.stop(event);
    $('login-form').show();
    new Fx.Style('login-content', 'margin-top', {
      duration: 700, 
      transition: Fx.Transitions.expoOut
      })._start(-162, 0);
  },
  
  '#cancel:click': function(event) {
    this.onclick = function() { return false; }
    Event.stop(event);
    new Fx.Style('login-content', 'margin-top', {
      duration: 400, 
      transition: Fx.Transitions.expoOut,
      onComplete: function() { $('login-form').hide(); }
      })._start(0, -162);
  }
});