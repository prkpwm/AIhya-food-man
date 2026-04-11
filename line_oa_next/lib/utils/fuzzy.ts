function levenshtein(a: string, b: string): number {
  const m = a.length, n = b.length;
  const dp: number[][] = Array.from({ length: m + 1 }, (_, i) =>
    Array.from({ length: n + 1 }, (_, j) => (i === 0 ? j : j === 0 ? i : 0))
  );
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = a[i-1] === b[j-1] ? dp[i-1][j-1] : 1 + Math.min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]);
  return dp[m][n];
}

export function fuzzyFind<T>(query: string, items: T[], getText: (item: T) => string, maxDistance = 3): T | null {
  const q = query.toLowerCase().trim();
  const scored = items.map((item) => {
    const text = getText(item).toLowerCase();
    if (text.includes(q) || q.includes(text)) return { item, score: 0 };
    const tokens = text.split(/\s+/), qTokens = q.split(/\s+/);
    let minDist = levenshtein(text, q);
    for (const t of tokens) for (const qt of qTokens) minDist = Math.min(minDist, levenshtein(t, qt));
    return { item, score: minDist };
  });
  const best = scored.sort((a, b) => a.score - b.score)[0];
  return (!best || best.score > maxDistance) ? null : best.item;
}
