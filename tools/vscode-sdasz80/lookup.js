// Finds the documentation of an instruction written for sdasz80. No VS Code here: can be run alone.
const instructions = require('./instructions');

const ACCUMULATOR = ['add', 'adc', 'sub', 'sbc', 'and', 'or', 'xor', 'cp'];
const REGISTERS = /^(a|b|c|d|e|h|l|i|r|af'?|bc|de|hl|sp|ix|iy|ixh|ixl|iyh|iyl)$/;
const CONDITIONS = /^(z|nz|c|nc|po|pe|p|m)$/;

// line without its comment and label; quotes are respected (';' can be a character)
function code(line) {
  const m = /^((?:'.'|"[^"]*"|[^;'"]|')*)/.exec(line);
  return m[1].replace(/^\s*[\w.$]+::?/, (label) => ' '.repeat(label.length));
}

function parse(line) {
  const m = /^(\s*)([a-z]+)(?:\s+(.*?))?\s*$/i.exec(code(line));
  if (!m || !Object.hasOwn(instructions, m[2].toLowerCase())) return undefined;
  const name = m[2].toLowerCase();
  let operands = [];
  if (m[3]) {
    // commas inside quotes or parentheses do not separate operands
    operands = m[3].match(/(?:'.'|\([^)]*\)|[^,])+/g).map((o) => {
      const text = o.trim();
      return /['"]/.test(text) && !/^af'$/i.test(text) ? text : text.toLowerCase().replace(/\s+/g, '');
    });
  }
  if (ACCUMULATOR.includes(name) && operands.length === 1) operands.unshift('a');
  return { name, operands, start: m[1].length, end: m[1].length + name.length };
}

// does an operand of the source match an operand of a form?
function matches(form, op) {
  const inner = /^\((.*)\)$/.exec(op);
  const constant = !REGISTERS.test(op) && !inner && !/\((ix|iy)\)$/.test(op);
  switch (form) {
    case 'r': return /^[abcdehl]$/.test(op);
    case 'r!': return op === 'r';
    case 'n': case 'nn': return constant;
    case 'b': return /^#?[0-7]$/.test(op) || (constant && !/^#?\d/.test(op));
    case '(nn)': return !!inner && !REGISTERS.test(inner[1]) && !/^(ix|iy)[+-]/.test(inner[1]);
    case 'rr': return /^(bc|de|hl|sp)$/.test(op);
    case 'qq': return /^(bc|de|hl|af)$/.test(op);
    case 'x': return /^(ix|iy)$/.test(op);
    case '(x)': return /^\((ix|iy)\)$/.test(op);
    case '(x+d)': return /^\((ix|iy)([+-].*)?\)$/.test(op) || /\((ix|iy)\)$/.test(op);
    case 'cc': return CONDITIONS.test(op);
    case 'jc': return /^(z|nz|c|nc)$/.test(op);
    default: return form === op;
  }
}

const formOperands = (form) => {
  const i = form.indexOf(' ');
  return i < 0 ? [] : form.slice(i + 1).split(',');
};

// { name, start, end, row, rows }: row is undefined when this combination does not exist
function find(line) {
  const ins = parse(line);
  if (!ins) return undefined;
  const rows = instructions[ins.name];
  const row = rows.find(([forms]) => forms.some((form) => {
    const ops = formOperands(form);
    return ops.length === ins.operands.length && ops.every((o, i) => matches(o, ins.operands[i]));
  }));
  return { ...ins, row, rows };
}

const FLAGS = ['S', 'Z', 'H', 'P/V', 'N', 'C'];
const MEANING = { '*': 'modifié', V: 'débordement', P: 'parité', '-': 'inchangé', 0: '0', 1: '1', '?': 'indéfini' };

const showForm = (form) => form
  .replace('x+d', 'ix+d').replace(/\bx\b/, 'ix').replace('r!', 'r (refresh)').replace('jc', 'cc')
  .replace(/(^| |,)(nn?)(?=,|$)/g, (m, before, n) => /^(jp|jr|call|djnz|rst|im)/.test(form) ? m : `${before}#${n}`);

function markdown(found) {
  const { name, operands, row, rows } = found;
  const out = [];
  if (row) {
    const [, flags, cycles, text] = row;
    out.push(`**${name}** — ${text}`);
    out.push(flags === '------' ? 'Flags : aucun ne change.'
      : `| ${FLAGS.join(' | ')} |\n|${':-:|'.repeat(6)}\n| ${[...flags].map((f) => MEANING[f]).join(' | ')} |`);
    out.push(`Durée : ${cycles} cycles`);
  } else {
    out.push(`**${name} ${operands.join(', ')}** — cette combinaison n'existe pas sur le Z80.`);
  }
  out.push('Formes possibles :\n\n' + rows.map(([forms, , cycles]) =>
    '- ' + forms.map((f) => '`' + showForm(f).replace(/,/g, ', ') + '`').join(', ')).join('\n'));
  return out.join('\n\n');
}

// line of the definition of the local label (1$) used on a line: between two normal labels
function localLabel(lines, line, name) {
  const normal = (i) => /^\s*[A-Za-z_.][\w.$]*::?(?!=)/.test(lines[i]);
  let first = line, last = line;
  while (first > 0 && !normal(first)) first--;
  while (last + 1 < lines.length && !normal(last + 1)) last++;
  const at = (i) => lines[i].trimStart().startsWith(name + ':');
  for (let i = first; i <= last; i++) if (at(i)) return i;
  return undefined;
}

module.exports = { find, markdown, localLabel, formOperands, instructions };
