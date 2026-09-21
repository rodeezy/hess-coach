import { useId, useState } from "react"

export interface TrendPoint {
  date: string
  value: number | null
  left?: number | null
  right?: number | null
}

interface Props {
  points: TrendPoint[]
  twoSided?: boolean
  unit?: string | null
  decimals?: number
  height?: number
}

/**
 * Change over time for one metric. A single-sided metric is one line and needs
 * no legend; a two-sided metric charts left and right as two lines (MT-2), which
 * are legended and direct-labelled so identity is never colour alone.
 *
 * Palette slots 1 and 2 from the validated categorical set, stepped per mode.
 */
const SERIES = [
  { key: "left" as const, label: "Left", css: "var(--series-1)" },
  { key: "right" as const, label: "Right", css: "var(--series-2)" },
]

export default function TrendChart({
  points, twoSided = false, unit, decimals = 1, height = 160,
}: Props) {
  const gradId = useId()
  const [hover, setHover] = useState<number | null>(null)

  const rows = points.filter((p) =>
    twoSided ? p.left != null || p.right != null : p.value != null)
  if (rows.length === 0) return null

  const series = twoSided
    ? SERIES.map((s) => ({ ...s, values: rows.map((r) => r[s.key] ?? null) }))
    : [{ key: "value" as const, label: "", css: "var(--series-1)",
         values: rows.map((r) => r.value ?? null) }]

  const all = series.flatMap((s) => s.values).filter((v): v is number => v != null)
  const min = Math.min(...all)
  const max = Math.max(...all)
  const pad = (max - min) * 0.12 || Math.abs(max || 1) * 0.12 || 1
  const lo = min - pad
  const hi = max + pad

  const W = 600
  const H = height
  const M = { top: 10, right: 10, bottom: 22, left: 40 }
  const iw = W - M.left - M.right
  const ih = H - M.top - M.bottom

  const x = (i: number) => M.left + (rows.length === 1 ? iw / 2 : (i / (rows.length - 1)) * iw)
  const y = (v: number) => M.top + ih - ((v - lo) / (hi - lo)) * ih

  const path = (values: (number | null)[]) => {
    let d = ""
    let open = false
    values.forEach((v, i) => {
      if (v == null) { open = false; return }
      d += `${open ? "L" : "M"}${x(i).toFixed(1)} ${y(v).toFixed(1)} `
      open = true
    })
    return d.trim()
  }

  const fmt = (v: number) => v.toFixed(decimals)
  const active = hover != null ? rows[hover] : null

  return (
    <figure className="viz m-0">
      <svg
        viewBox={`0 0 ${W} ${H}`}
        className="w-full"
        style={{ height }}
        role="img"
        aria-label={`Trend over ${rows.length} measurements`}
        onMouseLeave={() => setHover(null)}
      >
        <defs>
          <linearGradient id={gradId} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor="var(--series-1)" stopOpacity="0.16" />
            <stop offset="100%" stopColor="var(--series-1)" stopOpacity="0" />
          </linearGradient>
        </defs>

        {/* Recessive gridlines and axis labels. */}
        {[lo, (lo + hi) / 2, hi].map((v, i) => (
          <g key={i}>
            <line x1={M.left} x2={W - M.right} y1={y(v)} y2={y(v)}
                  stroke="var(--viz-grid)" strokeWidth="1" />
            <text x={M.left - 6} y={y(v) + 3} textAnchor="end"
                  fontSize="10" fill="var(--viz-muted)">{fmt(v)}</text>
          </g>
        ))}

        {!twoSided && (
          <path d={`${path(series[0].values)} L${x(rows.length - 1)} ${M.top + ih} L${x(0)} ${M.top + ih} Z`}
                fill={`url(#${gradId})`} stroke="none" />
        )}

        {series.map((s) => (
          <g key={s.key}>
            <path d={path(s.values)} fill="none" stroke={s.css}
                  strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            {s.values.map((v, i) =>
              v == null ? null : (
                <circle key={i} cx={x(i)} cy={y(v)} r={hover === i ? 5 : 3.5}
                        fill={s.css} stroke="var(--surface)" strokeWidth="2" />
              ))}
          </g>
        ))}

        {/* Hit targets wider than the marks. */}
        {rows.map((_, i) => (
          <rect key={i} x={x(i) - iw / rows.length / 2} y={M.top}
                width={iw / rows.length || 20} height={ih}
                fill="transparent" onMouseEnter={() => setHover(i)} />
        ))}

        {hover != null && (
          <line x1={x(hover)} x2={x(hover)} y1={M.top} y2={M.top + ih}
                stroke="var(--viz-grid)" strokeWidth="1" />
        )}

        <text x={M.left} y={H - 6} fontSize="10" fill="var(--viz-muted)">{rows[0].date}</text>
        {rows.length > 1 && (
          <text x={W - M.right} y={H - 6} textAnchor="end" fontSize="10"
                fill="var(--viz-muted)">{rows[rows.length - 1].date}</text>
        )}
      </svg>

      <figcaption className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs">
        {twoSided && series.map((s) => (
          <span key={s.key} className="flex items-center gap-1.5 text-neutral-500 dark:text-neutral-400">
            <span className="inline-block h-2 w-2 rounded-full" style={{ background: s.css }} />
            {s.label}
          </span>
        ))}
        {active && (
          <span className="text-neutral-600 dark:text-neutral-300">
            {active.date}
            {twoSided
              ? ` · L ${active.left ?? "—"} · R ${active.right ?? "—"}`
              : ` · ${active.value}`}
            {unit ? ` ${unit}` : ""}
          </span>
        )}
      </figcaption>
    </figure>
  )
}
