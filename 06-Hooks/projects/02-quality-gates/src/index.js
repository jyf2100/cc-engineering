/**
 * 示例应用入口
 *
 * 注意：此文件故意包含一些格式问题
 * 用于演示 post-edit-format hook 的自动格式化功能
 */

const utils = require('./utils')

// 主函数
async function main() {
  console.log('应用启动...')

  const result=await utils.fetchData()  // 故意缺少空格
  console.log('获取数据:', result)

  const processed = utils.processData(result)
if (processed.length > 0) {  // 故意缩进不正确
    console.log('处理完成')
  }

  return processed
}

// 辅助函数
function formatOutput(data) {
  return {
    timestamp: new Date().toISOString(),
    data: data,
    count: data.length
  }
}

// 导出
module.exports = {
  main,
  formatOutput
}

// 如果直接运行
if (require.main === module) {
  main().catch(console.error)
}
