#!/usr/bin/env python
import re
import os
import sys


def include_shaders(paths):
    def include_shaders_content(x):
        indent = x.group(1)
        tab = 8 * " "

        text = []
        for path in paths:
            basename = os.path.basename(path)
            tag, ext = os.path.splitext(basename)

            with open(path) as f:
                t = f.read()
            t = t.strip().split(os.linesep)
            t = [(os.linesep + indent + tab).join(t)]
            t[0] = tab + t[0]

            typename = {".vert": "vertex", ".frag": "fragment"}
            header = '<script id="{:}-{:}s" type="x-shader/x-{:}">'.format(
                tag, ext[1], typename[ext])
            t.insert(0, header)
            t.append("</script>")
            text += t
        text[0] = indent + text[0]

        return (os.linesep + indent).join(text)

    with open("src/pages/index.html") as f:
        content = f.read()
    return re.sub(r'( *)<!-- *SHADERS GO HERE *-->',
        include_shaders_content, content)


if __name__ == "__main__":
    with open("site/index.html", "w") as f:
        f.write(include_shaders(sys.argv[1:]))
