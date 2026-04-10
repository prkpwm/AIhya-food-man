// Levenshtein distance — counts min edits to transform a → b
function levenshtein(a: string, b: string): number {
  const m = a.length;
  const n = b.length;
  const dp: number[][] = Array.from({ length: m + 1 }, (_, i) =>
    Array.from({ length: n + 1 }, (_, j) => (i === 0 ? j : j === 0 ? i : 0))
  );
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] === b[j - 1]
        ? dp[i - 1][j - 1]
        : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    }
  }
  return dp[m][n];
}

export interface FuzzyMatch<T> {
  item: T;
  score: number; // 0 = perfect, higher = worse
}

// Find best match from list using:
// 1. exact substring match (score 0)
// 2. levenshtein on each word token (score = distance)
export function fuzzyFind<T>(
  query: string,
  items: T[],
  getText: (item: T) => string,
  maxDistance = 3
): T | null {
  const q = query.toLowerCase().trim();

  const scored: FuzzyMatch<T>[] = items.map((item) => {
    const text = getText(item).toLowerCase();

    // exact substring — best score
    if (text.includes(q) || q.includes(text)) return { item, score: 0 };

    // token-level levenshtein — split by space and find min distance
    const tokens = text.split(/\s+/);
    const qTokens = q.split(/\s+/);

    let minDist = Infinity;
    for (const t of tokens) {
      for (const qt of qTokens) {
        minDist = Math.min(minDist, levenshtein(t, qt));
      }
    }
    // also check full string distance
    minDist = Math.min(minDist, levenshtein(text, q));

    return { item, score: minDist };
  });

  const best = scored.sort((a, b) => a.score - b.score)[0];
  if (!best || best.score > maxDistance) return null;
  return best.item;
}
