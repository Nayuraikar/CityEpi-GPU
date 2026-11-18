// Single source for colours used in charts, SVG and the canvas map layers.
// Keep in sync with tailwind.config.js.
export const C = {
  teal: '#2f9a93', tealDeep: '#23807a',
  glacier: '#5b9bc4', glacierDeep: '#3f7fa8',
  sage: '#6ea47a', coral: '#e0735e', amber: '#d9982a', lavender: '#8d82cc',
  terracotta: '#d38a5c', slate: '#8696a6',
  grid: '#e6ebf0', axis: '#5f7285', ink: '#1a2632', line: '#e1e7ed',
} as const

/** Epidemic compartments */
export const SEIR = { S: C.glacier, E: C.amber, I: C.coral, R: C.sage } as const
export const SEIR_NAMES = { S: 'Susceptible', E: 'Exposed', I: 'Infectious', R: 'Recovered' } as const

/** GPU / CPU backends */
export const BACKEND: Record<string, string> = {
  V0: C.slate, V1: C.lavender, V2_1T: C.glacier, V2_maxT: C.glacierDeep, V3_simd: C.amber, V5: C.sage, V6: C.teal,
}
