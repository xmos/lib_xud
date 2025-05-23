# Copyright 2024-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

def header():
    return """<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html> <head>
<title>XTA-XUD output</title>
<style>
details {
  user-select: none;
}

details>summary> span.icon {
  width: 1em;
  height: 1em;
  transition: all 0.3s;
}

details[open]> summary span.icon {
  transform: rotate(90deg);
}

details>summary span.icon2 {
  width: 1em;
  height: 1em;
  transition: all 0.3s;
}

details[open]> summary span.icon2 {
  transform: rotate(90deg);
}

summary {
  display: flex;
  cursor: pointer;
}

summary::-webkit-details-marker {
  display: none;
}

div.a {
  margin-left: 50px;
}

pre.b {
  margin-left: 50px;
}
</style>
<script>
</script>
</head>

<body>
<h1>XTA-XUD output</h1>
"""

def p(summary):
    summary = summary.replace('>','&gt;').replace('<','&lt;')
    return '<p>' + summary + '</p>'

def pre(summary):
    summary = summary.replace('>','&gt;').replace('<','&lt;')
    return '<pre class="b">\n' + summary + '\n</pre>'

def openable_element(summary, main):
#    summary = summary.replace('>','&gt;').replace('<','&lt;')
    return """
<p>
<details>
  <summary>
    <span class="icon">&#9656;</span>""" + summary + """</summary><div class="a">""" + main + """</div>
</details>
</p>
"""

def trailer():
   return "</body> </html>\n"
