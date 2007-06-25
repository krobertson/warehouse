/*
 * QTObject embed
 * http://blog.deconcept.com/2005/01/26/web-standards-compliant-javascript-quicktime-detect-and-embed/
 *
 * by Geoff Stearns (geoff@deconcept.com, http://www.deconcept.com/)
 *
 * v1.0.2 - 02-16-2005
 *
 * Embeds a quicktime movie to the page, includes plugin detection
 *
 * Usage:
 *
 *	myQTObject = new QTObject("path/to/mov.mov", "movid", "width", "height");
 *	myQTObject.altTxt = "Upgrade your Quicktime Player!";    // optional
 
 *  myQTObject.addParam("controller", "false");              // optional
 *	myQTObject.write();
 *
 */
 
var QTEmbed = Class.create();
QTEmbed.prototype = {
  initialize: function(element, mov, options) {
    this.element = element;
    this.src = mov;
    this.options = $H({ params: { autoplay: false, cache: true }}).merge(options || {});
    this.build();
  },
  
  build: function() {
    params = [];
    $H(this.options.params).each(function(param) {
      params.push(new Template('<param name="#{name}" value="#{value}" />').evaluate({name: param.key, value: param.value}));
    });
    console.log(params);
    var attrs = {
      width: this.options.width,
      height: this.options.height,
      params: params.join('\n'),
      autoplay: this.options.params.autoplay,
      controller: true,
      src: this.src,
      id: this.options.id
    };
    this.embed = new Template('<embed id="#{id}" type="video/quicktime" controller="#{controller}" autoplay="#{autoplay}" src="#{src}" width="#{width}" height="#{height}">#{params}</embed>').evaluate(attrs);
  },
  
  toString: function() {
    return this.embed;
  }
};

// QTObject = function(mov, id, w, h) {
//  this.mov = mov;
//  this.id = id;
//  this.width = w;
//  this.height = h;
//  this.redirect = "";
//  this.sq = document.location.search.split("?")[1] || "";
//  this.altTxt = "This content requires the QuickTime Plugin. <a href='http://www.apple.com/quicktime/download/'>Download QuickTime Player</a>.";
//  this.bypassTxt = "<p>Already have QuickTime Player? <a href='?detectqt=false&"+ this.sq +"'>Click here.</a></p>";
//  this.params = new Object();
//  this.doDetect = getQueryParamValue('detectqt');
// }
// 
// QTObject.prototype.addParam = function(name, value) {
//  this.params[name] = value;
// }
// 
// QTObject.prototype.getParams = function() {
//     return this.params;
// }
// 
// QTObject.prototype.getParam = function(name) {
//     return this.params[name];
// }
// 
// QTObject.prototype.getParamTags = function() {
//     var paramTags = "";
//     for (var param in this.getParams()) {
//         paramTags += '<param name="' + param + '" value="' + this.getParam(param) + '" />';
//     }
//     if (paramTags == "") {
//         paramTags = null;
//     }
//     return paramTags;
// }
// 
// QTObject.prototype.getHTML = function() {
//     var qtHTML = "";
//  if (navigator.plugins && navigator.plugins.length) { // not ie
//         qtHTML += '<embed type="video/quicktime" src="' + this.mov + '" width="' + this.width + '" height="' + this.height + '" id="' + this.id + '"';
//         for (var param in this.getParams()) {
//             qtHTML += ' ' + param + '="' + this.getParam(param) + '"';
//         }
//         qtHTML += '></embed>';
//     }
//     else { // pc ie
//         qtHTML += '<object classid="clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B" width="' + this.width + '" height="' + this.height + '" id="' + this.id + '">';
//         this.addParam("src", this.mov);
//         if (this.getParamTags() != null) {
//             qtHTML += this.getParamTags();
//         }
//         qtHTML += '</object>';
//     }
//     return qtHTML;
// }
// 
// 
// QTObject.prototype.getVariablePairs = function() {
//     var variablePairs = new Array();
//     for (var name in this.getVariables()) {
//         variablePairs.push(name + "=" + escape(this.getVariable(name)));
//     }
//     if (variablePairs.length > 0) {
//         return variablePairs.join("&");
//     }
//     else {
//         return null;
//     }
// }
// 
// QTObject.prototype.write = function(elementId) {
//  if(isQTInstalled() || this.doDetect=='false') {
//    if (elementId) {
//      document.getElementById(elementId).innerHTML = this.getHTML();
//    } else {
//      document.write(this.getHTML());
//    }
//  } else {
//    if (this.redirect != "") {
//      document.location.replace(this.redirect);
//    } else {
//      if (elementId) {
//        document.getElementById(elementId).innerHTML = this.altTxt +""+ this.bypassTxt;
//      } else {
//        document.write(this.altTxt +""+ this.bypassTxt);
//      }
//    }
//  }   
// }
// 
// function isQTInstalled() {
//  var qtInstalled = false;
//  qtObj = false;
//  if (navigator.plugins && navigator.plugins.length) {
//    for (var i=0; i < navigator.plugins.length; i++ ) {
//          var plugin = navigator.plugins[i];
//          if (plugin.name.indexOf("QuickTime") > -1) {
//      qtInstalled = true;
//          }
//       }
//  } else {
//    execScript('on error resume next: qtObj = IsObject(CreateObject("QuickTimeCheckObject.QuickTimeCheck.1"))','VBScript');
//    qtInstalled = qtObj;
//  }
//  return qtInstalled;
// }
// 
// /* get value of querystring param */
// function getQueryParamValue(param) {
//  var q = document.location.search;
//  var detectIndex = q.indexOf(param);
//  var endIndex = (q.indexOf("&", detectIndex) != -1) ? q.indexOf("&", detectIndex) : q.length;
//  if(q.length > 1 && detectIndex != -1) {
//    return q.substring(q.indexOf("=", detectIndex)+1, endIndex);
//  } else {
//    return "";
//  }
// }
