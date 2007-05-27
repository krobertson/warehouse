Element.addMethods({
  duplicate: function(element) {
    element = $(element);
    var clone = element.cloneNode(true);
    element.parentNode.appendChild(clone);
  }
});

Event.addBehavior({
  'a.addpath:click': function() {
    $(this.up()).duplicate(); 
    return false;
  },
  
  'a.delpath:click': function() {
    this.up().remove();
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