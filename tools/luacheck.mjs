#!/usr/bin/env node
// 轻量 Lua 结构检查：不执行代码，只做词法切分 + 块配对/括号配对
// 用途：改完 DoorsHardCore-Seamless.lua 先在本地过一遍，再去 Roblox 里跑
// 用法：node tools/luacheck.mjs DoorsHardCore-Seamless.lua
import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) {
  console.error("用法: node tools/luacheck.mjs <file.lua>");
  process.exit(2);
}
const src = readFileSync(file, "utf8");

const KEYWORDS_OPEN_FOR = new Set(["for", "while"]);
const KEYWORDS = new Set([
  "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
  "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
  "true", "until", "while",
]);

const tokens = [];
let i = 0;
const n = src.length;
let line = 1;

function longBracketOpen(at) {
  // [[ 或 [=*[
  if (src[at] !== "[") return null;
  let j = at + 1;
  let eq = 0;
  while (src[j] === "=") { eq++; j++; }
  if (src[j] !== "[") return null;
  return { level: eq, contentStart: j + 1 };
}

function longBracketClose(level, from) {
  const close = "]" + "=".repeat(level) + "]";
  const at = src.indexOf(close, from);
  return at === -1 ? -1 : at + close.length;
}

while (i < n) {
  const c = src[i];

  if (c === "\n") { line++; i++; continue; }

  // 注释
  if (c === "-" && src[i + 1] === "-") {
    const lb = longBracketOpen(i + 2);
    if (lb) {
      const endAt = longBracketClose(lb.level, lb.contentStart);
      if (endAt === -1) { console.error(`未闭合的长注释，起始行 ${line}`); process.exit(1); }
      line += (src.slice(i, endAt).match(/\n/g) || []).length;
      i = endAt;
      continue;
    }
    while (i < n && src[i] !== "\n") i++;
    continue;
  }

  // 长字符串
  if (c === "[") {
    const lb = longBracketOpen(i);
    if (lb) {
      const endAt = longBracketClose(lb.level, lb.contentStart);
      if (endAt === -1) { console.error(`未闭合的长字符串，起始行 ${line}`); process.exit(1); }
      line += (src.slice(i, endAt).match(/\n/g) || []).length;
      i = endAt;
      tokens.push({ t: "str", line });
      continue;
    }
  }

  // 普通字符串
  if (c === '"' || c === "'") {
    const startLine = line;
    const quote = c;
    i++;
    let closed = false;
    while (i < n) {
      const ch = src[i];
      if (ch === "\\") { i += 2; continue; }
      if (ch === "\n") { line++; }
      if (ch === quote) { i++; closed = true; break; }
      i++;
    }
    if (!closed) { console.error(`未闭合的字符串，起始行 ${startLine}`); process.exit(1); }
    tokens.push({ t: "str", line: startLine });
    continue;
  }

  // 数字
  if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(src[i + 1] || ""))) {
    const m = /^0[xX][0-9a-fA-F]+|^[0-9]*\.?[0-9]+([eE][+-]?[0-9]+)?/.exec(src.slice(i));
    i += m ? m[0].length : 1;
    tokens.push({ t: "num", line });
    continue;
  }

  // 标识符 / 关键字
  if (/[A-Za-z_]/.test(c)) {
    const m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(src.slice(i));
    const word = m[0];
    i += word.length;
    tokens.push({ t: KEYWORDS.has(word) ? "kw" : "id", v: word, line });
    continue;
  }

  // 运算符 / 标点
  const ops = ["...", "..", "==", "~=", "<=", ">=", "//", "::", "->"];
  let matched = null;
  for (const op of ops) {
    if (src.startsWith(op, i)) { matched = op; break; }
  }
  if (matched) { i += matched.length; tokens.push({ t: "op", v: matched, line }); continue; }

  if ("+-*/%^#&~|<>=(){}[];:,.".includes(c)) {
    i++;
    tokens.push({ t: "op", v: c, line });
    continue;
  }

  // 其他字符（BOM / 全角标点混进代码等）——直接报出来
  const codePoint = src.codePointAt(i);
  const ch = String.fromCodePoint(codePoint);
  if (codePoint > 127) {
    console.error(`第 ${line} 行出现全角/非 ASCII 字符: ${JSON.stringify(ch)}（多半是注释外的中文标点）`);
    process.exit(1);
  }
  i += ch.length;
}

// 块配对
const stack = [];
const errors = [];
const parens = [];

for (let k = 0; k < tokens.length; k++) {
  const tok = tokens[k];
  if (tok.t === "kw") {
    const v = tok.v;
    if (v === "for" || v === "while") {
      stack.push({ kind: "loop", line: tok.line });
    } else if (v === "do") {
      const top = stack[stack.length - 1];
      if (top && top.kind === "loop") {
        top.kind = "do";
      } else {
        stack.push({ kind: "do", line: tok.line });
      }
    } else if (v === "if") {
      stack.push({ kind: "if", line: tok.line });
    } else if (v === "function") {
      stack.push({ kind: "function", line: tok.line });
    } else if (v === "repeat") {
      stack.push({ kind: "repeat", line: tok.line });
    } else if (v === "end") {
      const top = stack.pop();
      if (!top) errors.push(`第 ${tok.line} 行多了 end`);
      else if (top.kind === "repeat") {
        errors.push(`第 ${tok.line} 行的 end 与第 ${top.line} 行的 repeat 不匹配（repeat 要用 until 收）`);
      }
    } else if (v === "until") {
      const top = stack.pop();
      if (!top) errors.push(`第 ${tok.line} 行多了 until`);
      else if (top.kind !== "repeat") {
        errors.push(`第 ${tok.line} 行的 until 与第 ${top.line} 行的 ${top.kind} 不匹配`);
      }
    }
  } else if (tok.t === "op") {
    if (tok.v === "(" || tok.v === "{" || tok.v === "[") {
      parens.push({ v: tok.v, line: tok.line });
    } else if (tok.v === ")" || tok.v === "}" || tok.v === "]") {
      const want = { ")": "(", "}": "{", "]": "[" }[tok.v];
      const top = parens.pop();
      if (!top) errors.push(`第 ${tok.line} 行多了 ${tok.v}`);
      else if (top.v !== want) {
        errors.push(`第 ${tok.line} 行的 ${tok.v} 与第 ${top.line} 行的 ${top.v} 不匹配`);
      }
    }
  }
}

for (const s of stack) {
  errors.push(`第 ${s.line} 行的 ${s.kind} 没有收（缺 end${s.kind === "repeat" ? " / until" : ""}）`);
}
for (const p of parens) {
  errors.push(`第 ${p.line} 行的 ${p.v} 没有闭合`);
}

if (errors.length) {
  console.error(`✗ ${file}: ${errors.length} 处结构问题`);
  for (const e of errors.slice(0, 40)) console.error("  - " + e);
  process.exit(1);
}

console.log(`✓ ${file}: 结构检查通过（${tokens.length} 个 token，${src.split("\n").length} 行）`);
