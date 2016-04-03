clipboard = require "clipboard"

load = ->
	contact = new clipboard ".contact"
	alertify = require "alertify.js"
	alertify.logPosition "top right"
	
	contact.on "success", ->
		alertify.success "Mijn e-mail, in jouw clipboard."
	
	contact.on "error", ->
		alertify.log "Doe Cmd-C om mijn e-mail te kopiëren."
	
	comments = document.getElementById("nodebb-comments")
	
	if comments
		@nodeBBURL = 'https://forum.als7.nl'
		@articleID = comments.getAttribute 'data-id'
		@articleData =
			title_plain: comments.getAttribute 'data-titel'
			url: 'https://als7.nl' + location.pathname
			markDownContent: 'Automatisch gegenereerd.'
			tags: []
		
		@nbb = document.createElement('script')
		nbb.type = 'text/javascript';
		nbb.async = true;
		nbb.src = nodeBBURL + '/plugins/nodebb-plugin-blog-comments/lib/general.js';
		(document.getElementsByTagName('head')[0] or document.getElementsByTagName('body')[0]).appendChild(nbb);

document.addEventListener "DOMContentLoaded", load.bind(window)