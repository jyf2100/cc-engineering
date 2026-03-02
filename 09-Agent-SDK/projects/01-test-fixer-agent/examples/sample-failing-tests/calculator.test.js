/**
 * 示例：失败的测试
 * 用于测试 test-fixer-agent 的功能
 */

const { add, subtract, multiply, divide } = require('./calculator');

describe('Calculator', () => {
  describe('add', () => {
    test('should add two positive numbers', () => {
      expect(add(2, 3)).toBe(5);  // 这个测试会失败
    });

    test('should add negative numbers', () => {
      expect(add(-1, -2)).toBe(-3);  // 这个测试会失败
    });

    test('should add zero', () => {
      expect(add(5, 0)).toBe(5);  // 这个测试会失败
    });
  });

  describe('subtract', () => {
    test('should subtract two numbers', () => {
      expect(subtract(5, 3)).toBe(2);
    });
  });

  describe('multiply', () => {
    test('should multiply two numbers', () => {
      expect(multiply(2, 3)).toBe(6);  // 这个测试会失败
    });

    test('should multiply by zero', () => {
      expect(multiply(5, 0)).toBe(0);  // 这个测试会失败
    });
  });

  describe('divide', () => {
    test('should divide two numbers', () => {
      expect(divide(6, 2)).toBe(3);
    });

    test('should return null for division by zero', () => {
      expect(divide(5, 0)).toBeNull();
    });
  });
});
