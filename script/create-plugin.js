#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// 获取用户输入的函数
function question(query) {
  return new Promise(resolve => {
    rl.question(query, resolve);
  });
}

async function main() {
  try {
    // 交互式获取插件名称
    const pluginName = await question('请输入插件名称 (例如 my-plugin): ');
    
    if (!pluginName) {
      console.error('错误: 插件名称不能为空');
      rl.close();
      process.exit(1);
    }
    
    // 交互式获取插件描述
    const pluginDescription = await question('请输入插件描述: ');
    
    if (!pluginDescription) {
      console.error('错误: 插件描述不能为空');
      rl.close();
      process.exit(1);
    }
    
    const pluginCamelCase = pluginName.replace(/-([a-z])/g, (g) => g[1].toUpperCase());
    const pluginPascalCase = pluginCamelCase.charAt(0).toUpperCase() + pluginCamelCase.slice(1);
    const pluginNamespace = 'Oukek' + pluginPascalCase;

    // 设置路径
    const rootDir = path.resolve(__dirname, '..');
    const templateDir = path.join(rootDir, 'script', 'pluginTpl');
    const targetDir = path.join(rootDir, 'packages', pluginName);

    console.log(`\n正在创建插件: ${pluginName}`);
    console.log(`描述: ${pluginDescription}`);
    console.log(`目标目录: ${targetDir}`);

    // 确保目标目录不存在
    if (fs.existsSync(targetDir)) {
      console.error(`错误: 目标目录已存在: ${targetDir}`);
      rl.close();
      process.exit(1);
    }

    // 复制模板目录到目标目录
    console.log('\n正在复制模板...');
    fs.mkdirSync(targetDir, { recursive: true });
    execSync(`cp -r ${templateDir}/* ${targetDir}/`);

    // 递归处理目录中的所有文件
    async function processDirectory(directory) {
      const items = fs.readdirSync(directory);
      
      for (const item of items) {
        const itemPath = path.join(directory, item);
        const stat = fs.statSync(itemPath);
        
        if (stat.isDirectory()) {
          // 如果文件夹名包含 Clipboard，重命名
          if (item.includes('OukekClipboard')) {
            const newDirName = item.replace('OukekClipboard', pluginNamespace);
            const newDirPath = path.join(directory, newDirName);
            fs.renameSync(itemPath, newDirPath);
            await processDirectory(newDirPath);
          } else {
            await processDirectory(itemPath);
          }
        } else if (stat.isFile()) {
          // 处理文件内容
          let fileContent = fs.readFileSync(itemPath, 'utf8');
          
          // 替换文件内容中的名称
          fileContent = fileContent
            .replace(/@oukek\/capacitor-clipboard/g, `@oukek/capacitor-${pluginName}`)
            .replace(/OukekCapacitorClipboard/g, `OukekCapacitor${pluginPascalCase}`)
            .replace(/OukekClipboard/g, pluginNamespace)
            .replace(/clipboard/g, pluginName)
            .replace(/Clipboard/g, pluginPascalCase);
          
          // 如果是 README.md 或 package.json，替换描述
          if (item === 'README.md') {
            // 替换 README 标题下的描述
            fileContent = fileContent.replace(
              /# @oukek\/capacitor-.*?\n.*?\n/s,
              `# @oukek/capacitor-${pluginName}\n\n${pluginDescription}\n`
            );
          } else if (item === 'package.json') {
            // 替换 package.json 中的描述
            const packageJson = JSON.parse(fileContent);
            packageJson.description = pluginDescription;
            fileContent = JSON.stringify(packageJson, null, 2);
          }
          
          fs.writeFileSync(itemPath, fileContent);
          
          // 如果文件名包含 Clipboard，重命名
          if (item.includes('Clipboard')) {
            const newFileName = item
              .replace('OukekCapacitorClipboard', `OukekCapacitor${pluginPascalCase}`)
              .replace('OukekClipboard', pluginNamespace)
              .replace('Clipboard', pluginPascalCase);
            fs.renameSync(itemPath, path.join(directory, newFileName));
          }
        }
      }
    }

    // 处理文件和目录
    await processDirectory(targetDir);
    
    // 获取版本号
    let version = "0.1.0"; // 默认版本号
    const packageJsonPath = path.join(targetDir, 'package.json');
    if (fs.existsSync(packageJsonPath)) {
      try {
        const packageJsonContent = fs.readFileSync(packageJsonPath, 'utf8');
        const packageJson = JSON.parse(packageJsonContent);
        if (packageJson.version) {
          version = packageJson.version;
        }
      } catch (err) {
        console.log(`警告: 无法读取 package.json 文件获取版本号: ${err.message}`);
      }
    }
    
    // 更新根目录的 README.md 文件，添加新插件到插件列表
    const rootReadmePath = path.join(rootDir, 'README.md');
    if (fs.existsSync(rootReadmePath)) {
      let rootReadmeContent = fs.readFileSync(rootReadmePath, 'utf8');
      
      // 查找插件列表部分
      const pluginListSection = '## 插件列表';
      if (rootReadmeContent.includes(pluginListSection)) {
        const pluginListSectionIndex = rootReadmeContent.indexOf(pluginListSection);
        let insertPosition = rootReadmeContent.indexOf('## ', pluginListSectionIndex + pluginListSection.length);
        
        // 如果没有找到下一个标题，则插入到文件末尾
        if (insertPosition === -1) {
          insertPosition = rootReadmeContent.length;
          // 确保文件末尾有额外的换行符
          rootReadmeContent = rootReadmeContent.endsWith('\n\n') 
            ? rootReadmeContent 
            : (rootReadmeContent.endsWith('\n') ? rootReadmeContent + '\n' : rootReadmeContent + '\n\n');
        }
        
        // 提取插件列表部分
        const beforeSection = rootReadmeContent.substring(0, insertPosition);
        const afterSection = rootReadmeContent.substring(insertPosition);
        
        // 检查是否已经有表格
        const hasTable = beforeSection.includes('| 插件名称 | 描述 | 版本 |');
        
        if (hasTable) {
          // 已有表格，添加一行
          // 找到表格末尾
          const tableEndIndex = beforeSection.lastIndexOf('|');
          if (tableEndIndex !== -1) {
            const beforeTable = beforeSection.substring(0, tableEndIndex + 1);
            const afterTable = beforeSection.substring(tableEndIndex + 1);
            
            // 添加新行
            const newPluginRow = `| [@oukek/capacitor-${pluginName}](./packages/${pluginName}/README.md) | ${pluginDescription} | ${version} |\n`;
            
            rootReadmeContent = beforeTable + '\n' + newPluginRow + afterTable + afterSection;
          } else {
            console.log(`警告: 无法找到表格末尾`);
          }
        } else {
          // 没有表格，需要创建表格
          // 检查是否有旧格式的插件列表
          const oldFormatPlugins = [];
          
          // 使用正则表达式查找所有旧格式的插件条目
          const pluginRegex = /### @oukek\/capacitor-([a-z-]+)\n\n\[查看文档\]\(\.\/packages\/([a-z-]+)\/README\.md\)/g;
          let match;
          let pluginListContent = beforeSection.substring(pluginListSectionIndex + pluginListSection.length);
          
          while ((match = pluginRegex.exec(pluginListContent)) !== null) {
            const pluginName = match[1];
            
            // 尝试获取包版本
            let pluginVersion = "N/A";
            const pluginPackageJsonPath = path.join(rootDir, 'packages', pluginName, 'package.json');
            if (fs.existsSync(pluginPackageJsonPath)) {
              try {
                const packageJsonContent = fs.readFileSync(pluginPackageJsonPath, 'utf8');
                const packageJson = JSON.parse(packageJsonContent);
                if (packageJson.version) {
                  pluginVersion = packageJson.version;
                }
                if (packageJson.description) {
                  oldFormatPlugins.push({
                    name: pluginName,
                    description: packageJson.description,
                    version: pluginVersion
                  });
                  continue;
                }
              } catch (err) {
                console.log(`警告: 无法读取 ${pluginName} 的 package.json 文件: ${err.message}`);
              }
            }
            
            // 如果无法获取描述，则添加一个默认描述
            oldFormatPlugins.push({
              name: pluginName,
              description: `Capacitor 插件 - ${pluginName}`,
              version: pluginVersion
            });
          }
          
          // 创建新的表格内容
          let tableContent = `\n| 插件名称 | 描述 | 版本 |\n| --- | --- | --- |\n`;
          
          // 添加已有的插件
          for (const plugin of oldFormatPlugins) {
            tableContent += `| [@oukek/capacitor-${plugin.name}](./packages/${plugin.name}/README.md) | ${plugin.description} | ${plugin.version} |\n`;
          }
          
          // 添加新插件
          tableContent += `| [@oukek/capacitor-${pluginName}](./packages/${pluginName}/README.md) | ${pluginDescription} | ${version} |\n\n`;
          
          // 删除旧格式的插件列表
          const newBeforeSection = rootReadmeContent.substring(0, pluginListSectionIndex + pluginListSection.length);
          
          // 重建内容
          rootReadmeContent = newBeforeSection + tableContent + afterSection;
        }
        
        fs.writeFileSync(rootReadmePath, rootReadmeContent);
        console.log(`已将新插件添加到根目录的 README.md 文件中的表格中`);
      } else {
        console.log(`警告: 在根目录的 README.md 文件中未找到插件列表部分`);
      }
    } else {
      console.log(`警告: 未找到根目录的 README.md 文件`);
    }

    console.log(`\n插件 ${pluginName} 创建成功!`);
    console.log(`您可以在 packages/${pluginName} 中找到它`);
    
    rl.close();
  } catch (error) {
    console.error('发生错误:', error);
    rl.close();
    process.exit(1);
  }
}

main(); 