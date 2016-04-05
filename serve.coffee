loader = require "metalsmith-loader"
loader core: true, global: true

_ = require "lodash"
slug = require('slug')
moment = require "moment"
moment.locale "nl"

server = require "http-server"
gaze = require "gaze"

# browserSync
# 	server     : "dist",
# 	files      : ["{templates}/**.*"],
# 	open: false
# 	middleware : (req, res, next) ->
# 		build(next);

autoValues = (options) ->
	(files, ms, done) ->
		if typeof options.functions is "object"
			{functions, global} = options
		else
			functions = options
		
		if global
			files = global: ms.metadata()
		
		for field, fn of functions
			for filename, metadata of files
				metadata[field] = fn(metadata, filename, files, ms)
		done()

rewrite = (pattern) ->
	fields = []
	
	rtrn = pattern.replace /:([\w.]+)/, (full, field) ->
		fields.push field
		"' + metadata." + field + " + '"
	
	fnbody = "return '" + rtrn + "'"
	
	fn = Function "metadata", "fnbody"
	
	# console.log pattern, fields
	
	(files, ms, done) ->
		for source, metadata of files
			incomplete = false
			
			for field in fields
				unless metadata[field]?
					incomplete = true
					break
			
			if incomplete
				metadata.path = source
			else
				destination = pattern.replace /:([\w.]+)/g, (full, field) ->
					metadata[field]
				
				destination = slug destination, lower: true
				
				files[destination + "/index.html"] = metadata
				metadata.path = destination
				delete files[source]
		done()

webpackconfig = 
	context: __dirname + "/src/scripts"
	entry: "./index.coffee"
	output:
		path: __dirname + "/dist"
		filename: "bundle.js"
	devtool: 'source-map'
	module:
		loaders: [
			test: /\.coffee$/, loader: "coffee-loader"
		,
			test: /\.(coffee\.md|litcoffee)$/, loader: "coffee-loader?literate"
		]

build = =>
	metalsmith = Metalsmith(__dirname)
		.use webpack webpackconfig
		.use ignore([
			'**/.DS_Store'
		])
		.use drafts()
		# .use defaultValues [
		# 	{
		# 		pattern: "**/*",
		# 		defaults: layout: "layout.jade"
		# 	}
		# 	# {
		# 	# 	pattern: "pages/index.jade",
		# 	# 	defaults: layout: "layout.jade"
		# 	# }
		# ]
		.use markdown()
		.use stylus()
		.use collections
			postsbydate:
				pattern: "posts/**"
				sortBy: "date"
				reverse: true
		.use autoValues
			article: (d) -> d.contents
		.use rewrite ":titel"
		.use(
			branch "posts/**"
				.use autoValues article: (d) -> d.contents
			)
		.use tags
			handle: "door"
			metadataKey: "mensen"
			path: "door/:tag/index.html"
			layout: "page.jade"
		.use tags
			handle: "bundel"
			metadataKey: "bundels"
			path: "bundels/:tag/index.html"
			sortBy: "deel"
			layout: "bundel.jade"
		.use autoValues
			global: true
			functions:
				# map object of objects to array of objects for pagination
				
				bundelArray: (d) -> _.map d.bundels, (boek, naam) ->
					_.extend boek,
						naam: naam
						door: _(boek).map(_.property "door").flatten().uniq().value()
						doorUrlSafe: _(boek).map(_.property "doorUrlSafe").flatten().uniq().value()
						# datum: _(boek).map(_.property "datum").max()
				mensenArray: (d) -> _.map d.mensen, (e, i) ->
					_.extend e, naam: i
		.use pagination
			postsbydate:
				layout: "postsbydate.jade"
				perPage: Infinity
				first: "index.html"
				path: "page/:num/index.html"
			mensenArray:
				layout: "mensen.jade"
				perPage: Infinity
				first: "door/index.html"
				path: "door/page/:num/index.html"
				pageMetadata: titel: "Mensen"
			bundelArray:
				layout: "bundels.jade"
				perPage: Infinity
				first: "bundels/index.html"
				path: "bundels/page/:num/index.html"
				pageMetadata: titel: "Bundels"
		# .use inPlace
		# 	engine: "jade"
		# 	pattern: "**/*.jade"
		# 	rename: true
		.use layouts
			engine: "jade"
			directory: "templates"
			pattern: "**/*.html"
			default: "post.jade"
		# .use uncss
		# 	css: ["semantic/semantic.min.css"]
		# 	html: ["pages/*.html", "*.html"]
		# 	output: "style.css"
		.use alias()
		.use sitemap hostname: "https://als7.nl"
		.use assets()
		.destination './dist'
		.metadata { _, slug, moment }
		# .use autoValues
		# 	test: (d) -> if d.titel?.startsWith("Jan") then console.dir d, depth: 0
		.build (err) ->
			console.log if err? then err + err.stack else "Build complete!"

simplewatch
	buildFn: build
	buildPath: __dirname + '/dist'
	srcPath: __dirname
	pattern: "{src,templates,public}/**/*"