export interface LogEntry {
  ts: string;
  dir: string;
  method: string;
  url: string;
  status?: number;
  ms?: number;
  query?: string;
  body?: string;
}

const logs: LogEntry[] = [];
const MAX = 500;

export function pushLog(entry: LogEntry): void {
  logs.unshift(entry);
  if (logs.length > MAX) logs.pop();
}

export function getLogs(): LogEntry[] { return logs; }
