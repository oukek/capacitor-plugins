#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// 设置路径
const rootDir = path.resolve(__dirname, '..');
const packagesDir = path.join(rootDir, 'packages');
const rootReadmePath = path.join(rootDir, 'README.md');

async function main() {
  try {
    console.log('开始更新根目录 README.md 中的插件列表...');

    // 检查 packages 目录是否存在
    if (!fs.existsSync(packagesDir)) {
      console.error(`错误: packages 目录不存在: ${packagesDir}`);
      process.exit(1);
    }

    // 检查根目录的 README.md 文件是否存在
    if (!fs.existsSync(rootReadmePath)) {
      console.error(`错误: 根目录的 README.md 文件不存在: ${rootReadmePath}`);
      process.exit(1);
    }

    // 读取根目录的 README.md 文件
    let rootReadmeContent = fs.readFileSync(rootReadmePath, 'utf8');

    // 查找插件列表部分
    const pluginListSection = '## 插件列表';
    if (!rootReadmeContent.includes(pluginListSection)) {
      console.error(`错误: 在根目录的 README.md 文件中未找到插件列表部分`);
      process.exit(1);
    }

    // 获取 packages 目录下的所有插件
    const plugins = [];
    const items = fs.readdirSync(packagesDir);

    // 过滤目录项
    for (const item of items) {
      const itemPath = path.join(packagesDir, item);
      const stat = fs.statSync(itemPath);

      // 如果是目录，并且没有以 . 开头（忽略隐藏目录）
      if (stat.isDirectory() && !item.startsWith('.')) {
        // 尝试读取 package.json 文件
        const packageJsonPath = path.join(itemPath, 'package.json');
        if (fs.existsSync(packageJsonPath)) {
          try {
            const packageJsonContent = fs.readFileSync(packageJsonPath, 'utf8');
            const packageJson = JSON.parse(packageJsonContent);
            
            // 收集插件信息
            plugins.push({
              name: item,
              fullName: packageJson.name || `@oukek/capacitor-${item}`,
              description: packageJson.description || `Capacitor 插件 - ${item}`,
              version: packageJson.version || 'N/A'
            });
          } catch (err) {
            console.log(`警告: 无法读取 ${item} 的 package.json 文件: ${err.message}`);
            
            // 仍然添加插件，使用默认值
            plugins.push({
              name: item,
              fullName: `@oukek/capacitor-${item}`,
              description: `Capacitor 插件 - ${item}`,
              version: 'N/A'
            });
          }
        } else {
          console.log(`警告: ${item} 目录下没有找到 package.json 文件`);
          
          // 仍然添加插件，使用默认值
          plugins.push({
            name: item,
            fullName: `@oukek/capacitor-${item}`,
            description: `Capacitor 插件 - ${item}`,
            version: 'N/A'
          });
        }
      }
    }

    if (plugins.length === 0) {
      console.log(`警告: 在 packages 目录下没有找到任何插件`);
      process.exit(0);
    }

    // 按插件名称排序
    plugins.sort((a, b) => a.name.localeCompare(b.name));

    // 创建表格内容
    let tableContent = '| 插件名称 | 描述 | 版本 |\n| --- | --- | --- |\n';
    for (const plugin of plugins) {
      tableContent += `| [${plugin.fullName}](./packages/${plugin.name}/README.md) | ${plugin.description} | ${plugin.version} |\n`;
    }

    // 替换插件列表部分
    const pluginListSectionIndex = rootReadmeContent.indexOf(pluginListSection);
    
    // 查找插件列表部分的结束位置（下一个 ## 开头的标题）
    let endIndex = rootReadmeContent.indexOf('\n## ', pluginListSectionIndex + pluginListSection.length);
    if (endIndex === -1) {
      // 如果没有找到下一个标题，则假设插件列表一直到文件末尾
      endIndex = rootReadmeContent.length;
    }

    // 分别获取插件列表前后的内容
    const beforeSection = rootReadmeContent.substring(0, pluginListSectionIndex + pluginListSection.length);
    const afterSection = rootReadmeContent.substring(endIndex);

    // 重建内容
    rootReadmeContent = beforeSection + '\n\n' + tableContent + afterSection;

    // 写入更新后的内容
    fs.writeFileSync(rootReadmePath, rootReadmeContent);

    console.log(`更新成功! 已找到并更新了 ${plugins.length} 个插件的信息。`);
    
    // 显示更新后的插件列表
    console.log('\n更新后的插件列表:');
    console.log(tableContent);

  } catch (error) {
    console.error('发生错误:', error);
    process.exit(1);
  }
}

main(); 