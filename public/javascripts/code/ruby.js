CodeHighlighter.addStyle("ruby",{
	comment : {
		exp  : /(#[^\n]+)|(#\s*\n)/
	},
	brackets : {
		exp  : /\(|\)/
	},
	string : {
		exp  : /'[^']*'|"[^"]*"/
	},
	keywords : {
		exp  : /\b(do|end|self|class|def|if|module|yield|then|else|for|until|unless|while|elsif|case|when|break|retry|redo|rescue|require|raise)\b/
	},
	symbol : {
	  exp : /([^:])(:[A-Za-z0-9_!?]+)/
	},
	rails : {
	  exp: /\b(acts_as_list|acts_as_tree|after_create|after_destroy|after_save|after_update|after_validation|after_validation_on_create|after_validation_on_update|before_create|before_destroy|before_save|before_update|before_validation|before_validation_on_create|before_validation_on_update|composed_of|belongs_to|has_one|has_many|has_and_belongs_to_many|helper|helper_method|validate|validate_on_create|validates_numericality_of|validate_on_update|validates_acceptance_of|validates_associated|validates_confirmation_of|validates_each|validates_format_of|validates_inclusion_of|validates_length_of|validates_presence_of|validates_size_of|validates_uniqueness_of|attr_protected|attr_accessible)\b/
	}
});