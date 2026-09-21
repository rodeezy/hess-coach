import { Head, Link, router, useForm } from "@inertiajs/react"
import { useState } from "react"
import Shell from "../../components/Shell"
import TrendChart from "../../components/TrendChart"

interface Available {
  id: string; key: string; name: string; group: string; unit: string | null
  twoSided: boolean; bestOfThree: boolean; computed: boolean
  decimals: number; custom: boolean
}
interface Tile {
  id: string; key: string; name: string; group: string; unit: string | null
  decimals: number; twoSided: boolean; computed: boolean
  points: { id: string | null; date: string; value: number | null
            left: number | null; right: number | null; note: string | null
            source: string | null }[]
}
interface Props {
  client: { id: string; name: string; heightCm: string | null }
  tiles: Tile[]
  available: Available[]
  tracked: string[]
  dexaKeys: string[]
}

const GROUP_LABEL: Record<string, string> = {
  biometric: "Biometrics", performance: "Performance", movement: "Movement",
}

export default function Metrics({ client, tiles, available, tracked }: Props) {
  const [picking, setPicking] = useState(false)
  const [selected, setSelected] = useState<string[]>(tracked)

  const toggle = (id: string) =>
    setSelected((s) => (s.includes(id) ? s.filter((x) => x !== id) : [...s, id]))

  const save = () =>
    router.put(`/clients/${client.id}/metrics/tracked`,
      { metric_type_ids: selected },
      { onSuccess: () => setPicking(false) })

  return (
    <Shell>
      <Head title={`Metrics · ${client.name}`} />
      <main className="mx-auto max-w-3xl px-4 py-8">
        <Link href={`/clients/${client.id}`} className="text-sm underline">← {client.name}</Link>

        <header className="mt-2 flex flex-wrap items-center justify-between gap-3">
          <h1 className="text-2xl font-semibold tracking-tight">Metrics</h1>
          <div className="flex gap-2">
            <Link href={`/clients/${client.id}/assessment`}
                  className="inline-flex min-h-11 items-center rounded-lg bg-neutral-900 px-4
                             text-sm font-medium text-white dark:bg-neutral-100 dark:text-neutral-900">
              Assessment
            </Link>
            <button onClick={() => setPicking(!picking)}
                    className="min-h-11 rounded-lg border border-neutral-300 px-3 text-sm
                               dark:border-neutral-700">
              {picking ? "Done" : "Choose metrics"}
            </button>
          </div>
        </header>

        {/* Only what matters to this client's goal (MT-4). */}
        {picking && (
          <div className="mt-6 rounded-xl border border-neutral-200 p-4 dark:border-neutral-800">
            <p className="text-sm text-neutral-600 dark:text-neutral-300">
              Pick the metrics that matter for {client.name}. Everything else stays hidden.
            </p>
            {["biometric", "performance", "movement"].map((group) => (
              <section key={group} className="mt-4">
                <h2 className="text-xs font-semibold uppercase tracking-wide text-neutral-500
                               dark:text-neutral-400">
                  {GROUP_LABEL[group]}
                </h2>
                <div className="mt-2 flex flex-wrap gap-2">
                  {available.filter((a) => a.group === group).map((a) => (
                    <button key={a.id} onClick={() => toggle(a.id)}
                            aria-pressed={selected.includes(a.id)}
                            className={`min-h-9 rounded-lg border px-2.5 text-xs ${
                              selected.includes(a.id)
                                ? "border-transparent bg-neutral-900 text-white dark:bg-neutral-100 dark:text-neutral-900"
                                : "border-neutral-300 dark:border-neutral-700"
                            }`}>
                      {a.name}
                      {a.computed && " ·auto"}
                    </button>
                  ))}
                </div>
              </section>
            ))}
            <button onClick={save}
                    className="mt-4 min-h-11 w-full rounded-lg bg-neutral-900 px-4 text-sm
                               font-medium text-white dark:bg-neutral-100 dark:text-neutral-900">
              Save tracked metrics
            </button>
          </div>
        )}

        {!client.heightCm && tiles.some((t) => t.key === "ffmi") && (
          <p className="mt-6 rounded-lg border border-amber-300 px-3 py-2 text-sm dark:border-amber-800">
            FFMI needs a height on file.{" "}
            <Link href={`/clients/${client.id}/edit`} className="underline">Add one</Link>.
          </p>
        )}

        <div className="mt-6 space-y-4">
          {tiles.map((t) => (
            <MetricCard key={t.id} tile={t} clientId={client.id} />
          ))}
          {tiles.length === 0 && (
            <p className="rounded-xl border border-dashed border-neutral-300 p-8 text-center text-sm
                          text-neutral-500 dark:border-neutral-700 dark:text-neutral-400">
              No metrics tracked yet. Choose some above.
            </p>
          )}
        </div>
      </main>
    </Shell>
  )
}

/** Trend chart and table per metric, with edit and delete on entries (MT-5). */
function MetricCard({ tile, clientId }: { tile: Tile; clientId: string }) {
  const [showTable, setShowTable] = useState(false)
  const { data, setData, post, processing, reset } = useForm({
    metric_type_id: tile.id, measured_on: new Date().toISOString().slice(0, 10),
    value: "", value_left: "", value_right: "", note: "",
  })

  const cell = "min-h-11 rounded-lg border border-neutral-300 bg-transparent px-2 text-base " +
               "tabular-nums dark:border-neutral-700"

  return (
    <div className="rounded-xl border border-neutral-200 p-4 dark:border-neutral-800">
      <div className="flex items-baseline justify-between gap-2">
        <h3 className="text-sm font-medium">
          {tile.name}
          {tile.unit && <span className="ml-1 text-neutral-400">({tile.unit})</span>}
        </h3>
        {tile.points.length > 0 && (
          <button onClick={() => setShowTable(!showTable)} className="text-xs underline">
            {showTable ? "Chart" : "Table"}
          </button>
        )}
      </div>

      {tile.points.length === 0 ? (
        <p className="mt-1 text-xs text-neutral-500 dark:text-neutral-400">No entries yet.</p>
      ) : showTable ? (
        <table className="mt-3 w-full text-sm">
          <thead>
            <tr className="text-left text-xs text-neutral-500 dark:text-neutral-400">
              <th className="py-1 font-medium">Date</th>
              <th className="py-1 font-medium">{tile.twoSided ? "Left" : "Value"}</th>
              {tile.twoSided && <th className="py-1 font-medium">Right</th>}
              <th />
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-200 dark:divide-neutral-800">
            {[...tile.points].reverse().map((p, i) => (
              <tr key={p.id ?? i}>
                <td className="py-1.5">{p.date}</td>
                <td className="py-1.5 tabular-nums">{tile.twoSided ? p.left ?? "—" : p.value}</td>
                {tile.twoSided && <td className="py-1.5 tabular-nums">{p.right ?? "—"}</td>}
                <td className="py-1.5 text-right">
                  {p.id && (
                    <button
                      onClick={() => router.delete(`/clients/${clientId}/metric-entries/${p.id}`)}
                      className="text-xs text-neutral-400 underline"
                    >
                      Delete
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <div className="mt-2">
          <TrendChart points={tile.points} twoSided={tile.twoSided}
                      unit={tile.unit} decimals={tile.decimals} />
        </div>
      )}

      {/* FFMI is derived and never typed in (MT-5). */}
      {!tile.computed && (
        <form
          onSubmit={(e) => {
            e.preventDefault()
            post(`/clients/${clientId}/metric-entries`, { onSuccess: () => reset() })
          }}
          className="mt-3 flex flex-wrap items-center gap-2"
        >
          <input type="date" value={data.measured_on} required aria-label="Date"
                 onChange={(e) => setData("measured_on", e.target.value)} className={cell} />
          {tile.twoSided ? (
            <>
              <input type="number" step="any" inputMode="decimal" placeholder="L"
                     aria-label="Left" value={data.value_left}
                     onChange={(e) => setData("value_left", e.target.value)}
                     className={`${cell} w-20`} />
              <input type="number" step="any" inputMode="decimal" placeholder="R"
                     aria-label="Right" value={data.value_right}
                     onChange={(e) => setData("value_right", e.target.value)}
                     className={`${cell} w-20`} />
            </>
          ) : (
            <input type="number" step="any" inputMode="decimal" placeholder="Value"
                   aria-label="Value" value={data.value}
                   onChange={(e) => setData("value", e.target.value)}
                   className={`${cell} w-28`} />
          )}
          <button type="submit" disabled={processing}
                  className="min-h-11 rounded-lg border border-neutral-300 px-3 text-sm
                             dark:border-neutral-700">
            Add
          </button>
        </form>
      )}
    </div>
  )
}
