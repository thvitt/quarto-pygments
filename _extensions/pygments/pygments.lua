local default_inline_lang = nil
local needs_stylesheet = false

function Meta(meta)
	if meta["inline-code-lang"] then
		default_inline_lang = pandoc.utils.stringify(meta["inline-code-lang"])
	end
	return meta
end

function Code(el)
	local lang = el.classes[1] or default_inline_lang
	if lang == nil or lang == "" or lang == "text" then
		return el
	end

	local success, res = pcall(pandoc.pipe, "pygmentize", { "-l", lang, "-f", "html", "-O", "nowrap=True" }, el.text)
	if success then
		needs_stylesheet = true
		-- Remove trailing newline/whitespace
		res = res:gsub("%s+$", "")
		return pandoc.RawInline("html", '<code class="sourceCode ' .. lang .. '">' .. res .. "</code>")
	else
		return el
	end
end

function CodeBlock(el)
	-- Only process if a language is specified
	if el.classes[1] == nil then
		return el
	end

	-- Define the language and the code
	local lang = el.classes[1]
	local code = el.text

	-- Run pygmentize: -l (language), -f (format), -O (options)
	-- 'nowrap=True' is used so we can wrap it in Reveal.js compatible tags later if needed
	local success, res = pcall(pandoc.pipe, "pygmentize", { "-l", lang, "-f", "html", "-O", "nowrap=True" }, code)

	if success then
		needs_stylesheet = true
		-- Wrap in standard Reveal.js/Quarto classes so the layout doesn't break
		local html = '<div class="sourceCode"><pre class="sourceCode '
			.. lang
			.. '"><code class="sourceCode '
			.. lang
			.. '">'
			.. res
			.. "</code></pre></div>"
		return pandoc.RawBlock("html", html)
	else
		-- Fallback to default if pygmentize fails
		return el
	end
end

function Pandoc(doc)
	if needs_stylesheet then
		-- Use the directory where the filter is located
		local extension_dir = quarto.utils.resolve_path(".")
		local css_file = extension_dir .. "/pygments.css"

		local f = io.open(css_file, "r")
		if f then
			f:close()
		else
			-- Generate it if it doesn't exist
			-- We use -a .sourceCode to prefix all rules so they apply to our generated HTML
			os.execute("pygmentize -S default -f html -a .sourceCode > " .. css_file)
		end

		-- Use Quarto API to add the stylesheet as a dependency
		quarto.doc.add_html_dependency({
			name = "pygments",
			version = "1.0.0",
			stylesheets = { "pygments.css" },
		})
	end
	return doc
end

return {
	{ Meta = Meta },
	{
		Code = Code,
		CodeBlock = CodeBlock,
	},
	{ Pandoc = Pandoc },
}
