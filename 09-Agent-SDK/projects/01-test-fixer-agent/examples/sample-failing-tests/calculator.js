/**
 * 示例：包含 Bug 的代码
 * 用于测试 test-fixer-agent 的功能
 */

function add(a, b) {
  // Bug: 返回错误的结果
  return a - b;
}

function subtract(a, b) {
  return a - b;
}

function multiply(a, b) {
  // Bug: 返回错误的结果
  return a + b;
}

function divide(a, b) {
  if (b === 0) {
    return null;
  }
  return a / b;
}

module.exports = {
  add,
  subtract,
  multiply,
  divide,
};
