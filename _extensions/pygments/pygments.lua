local default_inline_lang = nil

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

return {
	{ Meta = Meta },
	{
		Code = Code,
		CodeBlock = CodeBlock,
	},
}
