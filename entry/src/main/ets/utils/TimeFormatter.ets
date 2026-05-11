export class TimeFormatter {
  static formatSeconds(totalSec: number): string {
    const safe: number = totalSec < 0 ? 0 : Math.floor(totalSec);
    const minutes: number = Math.floor(safe / 60);
    const seconds: number = safe % 60;
    const mm: string = minutes < 10 ? `0${minutes}` : `${minutes}`;
    const ss: string = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return `${mm}:${ss}`;
  }

  static formatClock(timestampMs: number): string {
    const date: Date = new Date(timestampMs);
    const hh: number = date.getHours();
    const mm: number = date.getMinutes();
    const ss: number = date.getSeconds();
    const pad = (n: number): string => (n < 10 ? `0${n}` : `${n}`);
    return `${pad(hh)}:${pad(mm)}:${pad(ss)}`;
  }
}
