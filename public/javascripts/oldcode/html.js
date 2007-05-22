CodeHighlighter.addStyle('html', {
	comment : {
		exp: /&lt;!\s*(--([^-]|[\r\n]|-[^-])*--\s*)&gt;/
	},
  // tag : {
  //  exp: /(&lt;\/?)([a-zA-Z1-6]+\s?)/, 
  //  replacement: "$1<span class=\"$0\">$2</span>"
  // },
  // string : {
  //  exp  : /'[^']*'|"[^"]*"/
  // },
  // attribute : {
  //  exp: /\b([a-zA-Z-:]+)(=)/, 
  //  replacement: "<span class=\"$0\">$1</span>$2"
  // },
  tag : {
    exp: /&lt;("[^"]*"|'[^']*'|[^'">])*&gt;/,
    replacement: "<span class=\"$0\">$0</span>"
  },
	doctype : {
		exp: /&lt;!DOCTYPE([^&]|&[^g]|&g[^t])*&gt;/
	}
});