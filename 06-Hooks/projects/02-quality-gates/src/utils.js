/**
 * 工具函数模块
 */

/**
 * 模拟异步数据获取
 * @returns {Promise<Array>} 数据数组
 */
async function fetchData() {
  // 模拟网络延迟
  await new Promise((resolve) => setTimeout(resolve, 100));

  return [
    { id: 1, name: 'Item 1', value: 100 },
    { id: 2, name: 'Item 2', value: 200 },
    { id: 3, name: 'Item 3', value: 300 },
  ];
}

/**
 * 处理数据
 * @param {Array} data - 原始数据
 * @returns {Array} 处理后的数据
 */
function processData(data) {
  if (!Array.isArray(data)) {
    return [];
  }

  return data.map((item) => ({
    ...item,
    processed: true,
    timestamp: Date.now(),
  }));
}

/**
 * 验证数据格式
 * @param {Object} item - 数据项
 * @returns {boolean} 是否有效
 */
function validateItem(item) {
  const requiredFields = ['id', 'name', 'value'];
  return requiredFields.every((field) => item.hasOwnProperty(field));
}

/**
 * 计算总和
 * @param {Array} data - 数据数组
 * @returns {number} 总和
 */
function calculateSum(data) {
  return data.reduce((sum, item) => sum + (item.value || 0), 0);
}

module.exports = {
  fetchData,
  processData,
  validateItem,
  calculateSum,
};
