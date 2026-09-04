import base64, os, re, sys
ROOT = "/Users/stanleyyoung/Apple/Challenge 4"
SHOTS = os.path.join(ROOT, "design/screenshots")
src = open(os.path.join(ROOT, "design/talking-points.html")).read()

missing = []
def repl(m):
    name = m.group(1)
    path = os.path.join(SHOTS, name)
    if os.path.exists(path):
        data = base64.b64encode(open(path, "rb").read()).decode()
        return '<img src="data:image/png;base64,%s" alt="%s">' % (data, name)
    missing.append(name)
    return '<span class="missing">awaiting<br>%s</span>' % name

out = re.sub(r'\{\{IMG:([^}]+)\}\}', repl, src)
dest = "/private/tmp/claude-501/-Users-stanleyyoung-Apple-Challenge-4/c68dbc49-c507-40f5-969d-93d98ef58f57/scratchpad/talking-points.html"
open(dest, "w").write(out)
print("embedded:", 6 - len(missing), "of 6")
if missing:
    print("missing:", ", ".join(missing))
print("size:", round(len(out)/1024), "KB")
