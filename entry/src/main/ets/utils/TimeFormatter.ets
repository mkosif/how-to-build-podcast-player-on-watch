export class TimeFormatter {
  static formatMs(totalMs: number): string {
    const safeMs: number = totalMs < 0 ? 0 : totalMs;
    return TimeFormatter.formatSeconds(Math.floor(safeMs / 1000));
  }

  static formatSeconds(totalSec: number): string {
    const safe: number = totalSec < 0 ? 0 : Math.floor(totalSec);
    const minutes: number = Math.floor(safe / 60);
    const seconds: number = safe % 60;
    const mm: string = minutes < 10 ? `0${minutes}` : `${minutes}`;
    const ss: string = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return `${mm}:${ss}`;
  }
}
