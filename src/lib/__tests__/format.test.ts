import { formatTime } from '../format';

describe('formatTime', () => {
  it('formats seconds as m:ss', () => {
    expect(formatTime(0)).toBe('0:00');
    expect(formatTime(59)).toBe('0:59');
    expect(formatTime(61)).toBe('1:01');
    expect(formatTime(754)).toBe('12:34');
  });

  it('floors fractional seconds', () => {
    expect(formatTime(89.9)).toBe('1:29');
  });

  it('returns placeholder for unknown durations', () => {
    expect(formatTime(null)).toBe('--:--');
    expect(formatTime(undefined)).toBe('--:--');
    expect(formatTime(NaN)).toBe('--:--');
    expect(formatTime(-5)).toBe('--:--');
  });
});
