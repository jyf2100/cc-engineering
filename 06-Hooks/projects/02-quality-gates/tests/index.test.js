/**
 * index.js 测试文件
 */

const { main, formatOutput } = require('../src/index');
const utils = require('../src/utils');

describe('main function', () => {
  test('should return processed data', async () => {
    const result = await main();
    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
  });
});

describe('formatOutput function', () => {
  test('should format data correctly', () => {
    const data = [{ id: 1, name: 'test' }];
    const output = formatOutput(data);

    expect(output).toHaveProperty('timestamp');
    expect(output).toHaveProperty('data', data);
    expect(output).toHaveProperty('count', 1);
  });

  test('should handle empty data', () => {
    const output = formatOutput([]);
    expect(output.count).toBe(0);
  });
});

describe('utils module', () => {
  describe('fetchData', () => {
    test('should return array of items', async () => {
      const data = await utils.fetchData();
      expect(Array.isArray(data)).toBe(true);
      expect(data.length).toBeGreaterThan(0);
    });
  });

  describe('processData', () => {
    test('should add processed flag', () => {
      const input = [{ id: 1, name: 'test', value: 100 }];
      const result = utils.processData(input);

      expect(result[0]).toHaveProperty('processed', true);
      expect(result[0]).toHaveProperty('timestamp');
    });

    test('should return empty array for non-array input', () => {
      expect(utils.processData(null)).toEqual([]);
      expect(utils.processData(undefined)).toEqual([]);
      expect(utils.processData({})).toEqual([]);
    });
  });

  describe('validateItem', () => {
    test('should return true for valid item', () => {
      const item = { id: 1, name: 'test', value: 100 };
      expect(utils.validateItem(item)).toBe(true);
    });

    test('should return false for invalid item', () => {
      expect(utils.validateItem({ id: 1 })).toBe(false);
      expect(utils.validateItem({})).toBe(false);
    });
  });

  describe('calculateSum', () => {
    test('should calculate correct sum', () => {
      const data = [
        { id: 1, value: 100 },
        { id: 2, value: 200 },
        { id: 3, value: 300 },
      ];
      expect(utils.calculateSum(data)).toBe(600);
    });

    test('should handle missing values', () => {
      const data = [{ id: 1 }, { id: 2, value: 50 }];
      expect(utils.calculateSum(data)).toBe(50);
    });

    test('should return 0 for empty array', () => {
      expect(utils.calculateSum([])).toBe(0);
    });
  });
});
