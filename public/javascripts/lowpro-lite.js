// LowPro by Dan Webb (http://danwebb.net) Bloody Brit! Buy him a beer if you use his code.
// I just ripped out the parts I don't need with the newer version of Protoype, feel free to 
// steal this file for your own use.
//
Object.extend(Event, {
  _domReady : function() {
    if (arguments.callee.done) return;
    arguments.callee.done = true;

    if (Event._timer)  clearInterval(Event._timer);
    
    Event._readyCallbacks.each(function(f) { f() });
    Event._readyCallbacks = null;
    
  },
  onReady : function(f) {
    if (!this._readyCallbacks) {
      var domReady = this._domReady;
      
      if (domReady.done) return f();
      
      if (document.addEventListener)
        document.addEventListener("DOMContentLoaded", domReady, false);
        
        /*@cc_on @*/
        /*@if (@_win32)
            var dummy = location.protocol == "https:" ?  "https://javascript:void(0)" : "javascript:void(0)";
            document.write("<script id=__ie_onload defer src='" + dummy + "'><\/script>");
            document.getElementById("__ie_onload").onreadystatechange = function() {
                if (this.readyState == "complete") { domReady(); }
            };
        /*@end @*/
        
        if (/WebKit/i.test(navigator.userAgent)) { 
          this._timer = setInterval(function() {
            if (/loaded|complete/.test(document.readyState)) domReady(); 
          }, 10);
        }
        
        Event.observe(window, 'load', domReady);
        Event._readyCallbacks =  [];
    }
    Event._readyCallbacks.push(f);
  }
});

Event.addBehavior = function(rules) {
  var ab = this.addBehavior;
  Object.extend(ab.rules, rules);
  
  if (!ab.responderApplied) {
    Ajax.Responders.register({
      onComplete : function() { 
        if (Event.addBehavior.reassignAfterAjax) 
          setTimeout(function() { ab.unload(); ab.load(ab.rules) }, 10);
      }
    });
    ab.responderApplied = true;
  }
  
  if (ab.autoTrigger) {
    this.onReady(ab.load.bind(ab, rules));
  }
  
};

Object.extend(Event.addBehavior, {
  rules : {}, cache : [],
  reassignAfterAjax : true,
  autoTrigger : true,
  
  load : function(rules) {
    for (var selector in rules) {
      var observer = rules[selector];
      var sels = selector.split(',');
      sels.each(function(sel) {
        var parts = sel.split(/:(?=[a-z]+$)/), css = parts[0], event = parts[1];
        $$(css).each(function(element) {
          if (event) {
            $(element).observe(event, observer);
            Event.addBehavior.cache.push([element, event, observer]);
          } else {
            if (!element.$$assigned || !element.$$assigned.include(observer)) {
              if (observer.attach) observer.attach(element);
              
              else observer.call($(element));
              element.$$assigned = element.$$assigned || [];
              element.$$assigned.push(observer);
            }
          }
        });
      });
    }
  },
  
  unload : function() {
    this.cache.each(function(c) {
      Event.stopObserving.apply(Event, c);
    });
    this.cache = [];
  }
  
});

Event.observe(window, 'unload', Event.addBehavior.unload.bind(Event.addBehavior));

Behavior = {
  create : function(members) {
    var behavior = function() { 
      var behavior = arguments.callee;
      if (this == window) {
        var args = [];
        for (var i = 0; i < arguments.length; i++) 
          args.push(arguments[i]);
          
        return function(element) {
          var initArgs = [this].concat(args);
          behavior.attach.apply(behavior, initArgs);
        };
      } else {
        var args = (arguments.length == 2 && arguments[1] instanceof Array) ? 
                      arguments[1] : Array.prototype.slice.call(arguments, 1);

        this.element = $(arguments[0]);
        this.initialize.apply(this, args);
        behavior._bindEvents(this);
        behavior.instances.push(this);
      }
    };
    behavior.prototype.initialize = Prototype.K;
    Object.extend(behavior.prototype, members);
    Object.extend(behavior, Behavior.ClassMethods);
    behavior.instances = [];
    return behavior;
  },
  ClassMethods : {
    attach : function(element) {
      return new this(element, Array.prototype.slice.call(arguments, 1));
    },
    _bindEvents : function(bound) {
      for (var member in bound)
        if (member.match(/^on(.+)/) && typeof bound[member] == 'function')
          bound.element.observe(RegExp.$1, bound[member].bindAsEventListener(bound));
    }
  }
};
