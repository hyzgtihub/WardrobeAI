import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const designPath = path.resolve(scriptDir, "..", "DESIGN.md");
const content = fs.readFileSync(designPath, "utf8");
const errors = [];

const requiredSections = [
  "文档作用与单一真源", "高低保真隔离", "品牌原则", "颜色", "排版", "栅格与间距",
  "圆角、描边与阴影", "图标", "衣物图片", "核心组件", "交互与状态", "无障碍与质量门槛",
  "Figma → tokens.json → SwiftUI 映射", "AI 生成页面的前置条件", "版本、变更与废弃", "Gate B2 验收标准"
];

const requiredComponents = [
  "Button", "Icon Button", "Text Field", "Checkbox", "Category Chip", "Tag", "Garment Card",
  "Editable Field Row", "Photo Hero", "Auto-save Status", "Bottom Navigation", "Navigation Bar",
  "Empty State", "Error State", "Loading Skeleton", "Sheet / Dialog"
];

for (const section of requiredSections) {
  if (!content.includes(section)) errors.push(`缺少章节：${section}`);
}
for (const component of requiredComponents) {
  if (!content.includes(`YISU Hi-Fi/${component}`)) errors.push(`缺少组件规范：${component}`);
}
if (!content.includes("[tokens.json](./tokens.json)")) errors.push("缺少 tokens.json 相对链接");
if (!content.includes("extensions.swiftUI")) errors.push("缺少 SwiftUI token 映射说明");
if (/\b(TODO|TBD)\b|待补充|稍后决定/i.test(content)) errors.push("存在未决占位内容");

if (errors.length) {
  console.error("FAIL: DESIGN.md 校验失败");
  errors.forEach((error) => console.error(`- ${error}`));
  process.exit(1);
}

console.log(`PASS: DESIGN.md 已通过 ${requiredSections.length} 个章节、${requiredComponents.length} 个组件和交付映射检查`);

