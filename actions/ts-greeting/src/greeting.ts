export type Style = 'plain' | 'shout' | 'emoji';

const STYLES: readonly Style[] = ['plain', 'shout', 'emoji'];

export function parseStyle(value: string | undefined): Style {
  const v = (value ?? 'plain').trim().toLowerCase();
  if ((STYLES as readonly string[]).includes(v)) return v as Style;
  throw new Error(`style must be one of ${STYLES.join(', ')} (got "${value}")`);
}

export function buildGreeting(name: string, style: Style = 'plain'): string {
  const who = name.trim();
  if (!who) throw new Error('who-to-greet must not be empty');
  const base = `Hello, ${who}!`;
  switch (style) {
    case 'shout':
      return base.toUpperCase();
    case 'emoji':
      return `:wave: ${base}`;
    default:
      return base;
  }
}
