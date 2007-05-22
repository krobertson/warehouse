Element.addMethods({
  duplicate: function(element) {
    element = $(element);
    var clone = element.cloneNode(true);
    element.parentNode.appendChild(clone);
  }
});

Event.addBehavior({
  'a.addpath:click': function() {
    $('path').duplicate(); 
    return false;
  }
});