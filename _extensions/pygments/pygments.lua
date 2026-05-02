local default_inline_lang = nil
local needs_stylesheet = false
local code_block_count = 0

function Meta(meta)
	if meta["inline-code-lang"] then
		default_inline_lang = pandoc.utils.stringify(meta["inline-code-lang"])
	end
	return meta
end

function Code(el)
	-- Only process if we are in a supported format
	local is_html = quarto.doc.is_format("html")
	local is_latex = quarto.doc.is_format("latex") or quarto.doc.is_format("beamer")

	if not (is_html or is_latex) then
		return el
	end

	local lang = el.classes[1] or default_inline_lang
	if lang == nil or lang == "" or lang == "text" then
		return el
	end

	local format = is_html and "html" or "latex"
	local options = { "-l", lang, "-f", format, "-O", "nowrap=True" }
	local success, res = pcall(pandoc.pipe, "pygmentize", options, el.text)

	if success then
		needs_stylesheet = true
		if is_html then
			-- Remove trailing newline/whitespace
			res = res:gsub("%s+$", "")
			return pandoc.RawInline("html", '<code class="sourceCode ' .. lang .. '">' .. res .. "</code>")
		else
			-- LaTeX inline code
			return pandoc.RawInline("latex", res)
		end
	else
		return el
	end
end

function CodeBlock(el)
	-- Only process if we are in a supported format
	local is_html = quarto.doc.is_format("html")
	local is_latex = quarto.doc.is_format("latex") or quarto.doc.is_format("beamer")

	if not (is_html or is_latex) then
		return el
	end

	-- Only process if a language is specified
	if el.classes[1] == nil then
		return el
	end

	-- Define the language and the code
	local lang = el.classes[1]
	local code = el.text

	local format = is_html and "html" or "latex"
	local options = { "-l", lang, "-f", format, "-O", "nowrap=True" }
	local success, res = pcall(pandoc.pipe, "pygmentize", options, code)

	if success then
		needs_stylesheet = true
		if is_html then
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
			-- LaTeX code block
			local success_latex, res_latex = pcall(pandoc.pipe, "pygmentize", { "-l", lang, "-f", "latex" }, code)
			if success_latex then
				if quarto.doc.is_format("beamer") then
					-- Beamer needs fragile frames for Verbatim.
					-- A workaround is to write the code to a file and \input it.
					code_block_count = code_block_count + 1
					local filename = "pygments-code-" .. code_block_count .. ".tex"
					local f = io.open(filename, "w")
					if f then
						f:write(res_latex)
						f:close()
						return pandoc.RawBlock("latex", "\\input{" .. filename .. "}")
					else
						return el
					end
				else
					return pandoc.RawBlock("latex", res_latex)
				end
			else
				return el
			end
		end
	else
		-- Fallback to default if pygmentize fails
		return el
	end
end

function Pandoc(doc)
	if needs_stylesheet then
		if quarto.doc.is_format("html") then
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
		elseif quarto.doc.is_format("latex") or quarto.doc.is_format("beamer") then
			-- Include LaTeX macros for pygments
			local success, res = pcall(pandoc.pipe, "pygmentize", { "-S", "default", "-f", "latex" }, "")
			if success then
				quarto.doc.include_text("in-header", res)
			end
			-- We also need fancyvrb for the Verbatim environment
			quarto.doc.use_latex_package("fancyvrb")
			quarto.doc.use_latex_package("color")
		end
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
