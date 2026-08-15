import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const tokenPath = path.resolve(scriptDir, "..", "tokens.json");
const tokens = JSON.parse(fs.readFileSync(tokenPath, "utf8"));
const requiredRoots = ["color", "spacing", "radius", "size", "typography", "shadow", "motion"];
const errors = [];
const leaves = [];

for (const root of requiredRoots) {
  if (!tokens[root]) errors.push(`缺少根分类：${root}`);
}

function lookup(dotPath) {
  return dotPath.split(".").reduce((value, key) => value?.[key], tokens);
}

function inspectValue(value, tokenPath) {
  if (typeof value === "string") {
    const match = value.match(/^\{([^}]+)\}$/);
    if (match && !lookup(match[1])) errors.push(`${tokenPath} 引用了不存在的 token：${match[1]}`);
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((item, index) => inspectValue(item, `${tokenPath}[${index}]`));
    return;
  }
  if (value && typeof value === "object") {
    Object.entries(value).forEach(([key, item]) => inspectValue(item, `${tokenPath}.${key}`));
  }
}

function walk(node, segments = []) {
  if (!node || typeof node !== "object" || Array.isArray(node)) return;
  if ("$type" in node || "$value" in node) {
    const tokenPath = segments.join(".");
    leaves.push({ tokenPath, token: node });
    for (const field of ["$type", "$value", "description", "extensions"]) {
      if (!(field in node)) errors.push(`${tokenPath} 缺少字段 ${field}`);
    }
    if (!node.extensions?.swiftUI) errors.push(`${tokenPath} 缺少 extensions.swiftUI`);
    inspectValue(node.$value, tokenPath);
    return;
  }
  Object.entries(node).forEach(([key, value]) => {
    if (!key.startsWith("$")) walk(value, [...segments, key]);
  });
}

walk(tokens);

const categoryCounts = Object.fromEntries(requiredRoots.map((root) => [
  root,
  leaves.filter(({ tokenPath }) => tokenPath.startsWith(`${root}.`)).length
]));

for (const [root, count] of Object.entries(categoryCounts)) {
  if (count === 0) errors.push(`${root} 分类没有 token`);
}

if (errors.length) {
  console.error("FAIL: tokens.json 校验失败");
  errors.forEach((error) => console.error(`- ${error}`));
  process.exit(1);
}

console.log(`PASS: ${leaves.length} 个 token 已通过结构、引用与 SwiftUI 映射校验`);
console.log(JSON.stringify(categoryCounts, null, 2));
