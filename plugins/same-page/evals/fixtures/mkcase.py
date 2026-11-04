"""Write an eval case: python3 -I fixtures/mkcase.py <spec.json>
spec: {name, variant, prompt, max_turns?, no_writes?: bool, graders: {gname: criteria}}"""
import json, os, subprocess, sys
s = json.load(open(sys.argv[1]))
here = os.path.dirname(os.path.abspath(__file__))
d = os.path.join(here, '..', s['name'])
subprocess.run([os.path.join(here, 'new-case.sh'), d, s['variant']], check=True)
y = f'schema_version: "1.0"\nname: {s["name"]}\ncontext:\n  scaffold_script: scaffold.sh\n'
if s.get('no_writes'):
    y += ('graders:\n'
          '  - {type: tool_used, name: no-write-tool, tool: Write, min: 0, max: 0}\n'
          '  - {type: tool_used, name: no-edit-tool, tool: Edit, min: 0, max: 0}\n')
open(os.path.join(d, 'case.yaml'), 'w').write(y)
tools = s.get('tools', '[Read, Glob, Grep, Bash, Write, Edit, Skill]')
open(os.path.join(d, 'prompt.md'), 'w').write(
    f'---\nmax_turns: {s.get("max_turns", 30)}\nallowed_tools: {tools}\n---\n\n{s["prompt"]}\n')
g = os.path.join(d, 'graders'); os.makedirs(g, exist_ok=True)
for name, c in s['graders'].items():
    open(os.path.join(g, f'{name}.md'), 'w').write(f'---\ntype: llm\nweight: 1\n---\n\n{c}\n')
