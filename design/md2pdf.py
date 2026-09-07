import html, re, subprocess, sys, os

def render(md):
    out, i, lines = [], 0, md.split("\n")
    while i < len(lines):
        ln = lines[i]
        if ln.strip() == "---":
            out.append('<hr>'); i += 1; continue
        m = re.match(r'^(#{1,6})\s+(.*)$', ln)
        if m:
            lvl = len(m.group(1))
            out.append("<h%d>%s</h%d>" % (lvl, inline(m.group(2)), lvl)); i += 1; continue
        if ln.startswith(">"):
            block = []
            while i < len(lines) and lines[i].startswith(">"):
                block.append(inline(lines[i].lstrip(">").lstrip())); i += 1
            out.append("<blockquote>%s</blockquote>" % "<br>".join(block)); continue
        if ln.startswith("```"):
            i += 1; block = []
            while i < len(lines) and not lines[i].startswith("```"):
                block.append(html.escape(lines[i])); i += 1
            i += 1
            out.append("<pre>%s</pre>" % "\n".join(block)); continue
        if ln.strip().startswith("|"):
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append(lines[i]); i += 1
            out.append(table(rows)); continue
        if re.match(r'^\s*[-*]\s+', ln):
            items = []
            while i < len(lines) and re.match(r'^\s*[-*]\s+', lines[i]):
                items.append("<li>%s</li>" % inline(re.sub(r'^\s*[-*]\s+', '', lines[i]))); i += 1
            out.append("<ul>%s</ul>" % "".join(items)); continue
        if re.match(r'^\s*\d+\.\s+', ln):
            items = []
            while i < len(lines) and re.match(r'^\s*\d+\.\s+', lines[i]):
                items.append("<li>%s</li>" % inline(re.sub(r'^\s*\d+\.\s+', '', lines[i]))); i += 1
            out.append("<ol>%s</ol>" % "".join(items)); continue
        if ln.strip() == "":
            i += 1; continue
        para = []
        start = i
        while i < len(lines) and lines[i].strip() and not re.match(r'^(#{1,6}\s|>|```|\||\s*[-*]\s|\s*\d+\.\s)', lines[i]) and lines[i].strip() != "---":
            para.append(inline(lines[i])); i += 1
        if i == start:
            # No progress: this line matched a block opener that its own branch
            # declined (a bare ">", for instance). Emit it and move on, rather
            # than looping forever.
            para.append(inline(lines[i])); i += 1
        out.append("<p>%s</p>" % " ".join(para))
    return "\n".join(out)

def table(rows):
    cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
    body = [r for r in cells if not all(re.fullmatch(r':?-{2,}:?', c or '-') for c in r)]
    if not body: return ""
    head, rest = body[0], body[1:]
    th = "".join("<th>%s</th>" % inline(c) for c in head)
    trs = "".join("<tr>%s</tr>" % "".join("<td>%s</td>" % inline(c) for c in r) for r in rest)
    return "<table><thead><tr>%s</tr></thead><tbody>%s</tbody></table>" % (th, trs)

def inline(t):
    t = html.escape(t)
    t = re.sub(r'`([^`]+)`', r'<code>\1</code>', t)
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', t)
    t = t.replace("&amp;plusmn;", "&plusmn;").replace("&amp;mdash;", "&mdash;")
    return t

CSS = """
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@600;700;800&family=IBM+Plex+Mono:wght@400;500&family=Newsreader:opsz,wght@6..72,300;6..72,400;6..72,600&display=swap">
<style>
  @page { size: A4; margin: 20mm 18mm; }
  :root {
    --ink:#12161C; --ink2:#4E5A68; --rule:#D8DEE6; --accent:#C24A1B; --panel:#F3F5F8;
  }
  * { -webkit-print-color-adjust: exact; print-color-adjust: exact; box-sizing:border-box; }
  body { font-family:"Newsreader",Georgia,serif; font-size:11.2pt; line-height:1.6; color:var(--ink); margin:0; }
  h1 { font-family:"Archivo",sans-serif; font-size:23pt; font-weight:800; letter-spacing:-.02em; line-height:1.1; margin:26pt 0 8pt; break-after:avoid; }
  h1:first-child { margin-top:0; }
  h2 { font-family:"Archivo",sans-serif; font-size:15pt; font-weight:700; margin:20pt 0 6pt; break-after:avoid; }
  h3 { font-family:"Archivo",sans-serif; font-size:11.5pt; font-weight:700; margin:16pt 0 4pt; color:var(--accent); break-after:avoid; }
  p { margin:0 0 9pt; }
  hr { border:0; border-top:1px solid var(--rule); margin:16pt 0; }
  strong { font-weight:600; }
  code { font-family:"IBM Plex Mono",monospace; font-size:9.4pt; background:var(--panel); padding:1px 4px; border-radius:3px; }
  pre { font-family:"IBM Plex Mono",monospace; font-size:9pt; background:var(--panel); padding:10pt 12pt; border-radius:5px; white-space:pre-wrap; }
  blockquote { margin:10pt 0; padding:8pt 14pt; border-left:3px solid var(--accent); background:var(--panel); font-family:"IBM Plex Mono",monospace; font-size:9.6pt; }
  blockquote p { margin:0; }
  table { width:100%; border-collapse:collapse; margin:10pt 0; font-size:10pt; break-inside:avoid; }
  th { text-align:left; font-family:"IBM Plex Mono",monospace; font-size:8.4pt; letter-spacing:.06em; text-transform:uppercase; color:var(--ink2); border-bottom:1px solid var(--rule); padding:0 8pt 5pt 0; font-weight:500; }
  td { border-bottom:1px solid var(--rule); padding:6pt 8pt 6pt 0; vertical-align:top; }
  ul,ol { margin:0 0 9pt; padding-left:18pt; }
  li { margin-bottom:3pt; }
</style>
"""

src, dest = sys.argv[1], sys.argv[2]
md = open(src).read()
html_doc = "<title>%s</title>" % os.path.basename(src) + CSS + render(md)
tmp = "/private/tmp/claude-501/-Users-stanleyyoung-Apple-Challenge-4/c68dbc49-c507-40f5-969d-93d98ef58f57/scratchpad/_md.html"
open(tmp, "w").write(html_doc)
subprocess.run(["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome","--headless","--disable-gpu",
                "--no-pdf-header-footer","--print-to-pdf=" + dest, "file://" + tmp],
               capture_output=True)
print("wrote", dest)
