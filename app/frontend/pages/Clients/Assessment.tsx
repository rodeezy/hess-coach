import { Head, Link, useForm } from "@inertiajs/react"
import Shell from "../../components/Shell"

interface Row {
  id: string; key: string; name: string; unit: string | null
  twoSided: boolean; bestOfThree: boolean; decimals: number
  last: { date: string; value: number | null; left: number | null; right: number | null } | null
}
interface Props {
  client: { id: string; name: string; lastAssessmentOn: string | null; assessmentOverdue: boolean }
  today: string
  dexaKeys: string[]
  groups: { group: string; metrics: Row[] }[]
}

interface EntryDraft {
  metric_type_id: string
  value: string; value_left: string; value_right: string
  attempts: string[]; attempts_right: string[]
}

const GROUP_LABEL: Record<string, string> = {
  biometric: "Biometrics", performance: "Performance", movement: "Movement",
}
const cell =
  "min-h-11 w-full rounded-lg border border-neutral-300 bg-transparent px-2 text-base " +
  "tabular-nums dark:border-neutral-700"

/** One screen, all tracked metrics, last value beside each input (MT-6). */
export default function Assessment({ client, today, dexaKeys, groups }: Props) {
  const all = groups.flatMap((g) => g.metrics)

  const { data, setData, post, processing } = useForm<{
    measured_on: string; source: string; entries: EntryDraft[]
  }>({
    measured_on: today,
    source: "",
    entries: all.map((m) => ({
      metric_type_id: m.id, value: "", value_left: "", value_right: "",
      attempts: ["", "", ""], attempts_right: ["", "", ""],
    })),
  })

  const patch = (i: number, changes: Partial<EntryDraft>) =>
    setData("entries", data.entries.map((e, j) => (j === i ? { ...e, ...changes } : e)))

  const showsDexa = all.some((m) => dexaKeys.includes(m.key))
  let index = -1

  return (
    <Shell>
      <Head title={`Assessment · ${client.name}`} />
      <main className="mx-auto max-w-2xl px-4 py-8">
        <Link href={`/clients/${client.id}`} className="text-sm underline">← {client.name}</Link>
        <h1 className="mt-2 text-2xl font-semibold tracking-tight">Assessment</h1>
        <p className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">
          {client.lastAssessmentOn
            ? `Last assessed ${client.lastAssessmentOn}.`
            : "No previous assessment."}{" "}
          Leave anything blank that you are not retesting.
        </p>

        <form onSubmit={(e) => { e.preventDefault(); post(`/clients/${client.id}/assessment`) }}
              className="mt-6">
          <div className="flex flex-wrap gap-3">
            <label className="text-sm">
              Date
              <input type="date" value={data.measured_on} required
                     onChange={(e) => setData("measured_on", e.target.value)}
                     className={`${cell} mt-1`} />
            </label>
            {showsDexa && (
              <label className="text-sm">
                Body composition source
                <select value={data.source} onChange={(e) => setData("source", e.target.value)}
                        className={`${cell} mt-1`}>
                  <option value="">—</option>
                  <option value="DEXA">DEXA</option>
                  <option value="BIA">BIA</option>
                  <option value="Calipers">Calipers</option>
                </select>
              </label>
            )}
          </div>

          {groups.map((g) => (
            <section key={g.group} className="mt-8">
              <h2 className="text-sm font-semibold">{GROUP_LABEL[g.group] ?? g.group}</h2>

              <div className="mt-2 divide-y divide-neutral-200 dark:divide-neutral-800">
                {g.metrics.map((m) => {
                  index += 1
                  const i = index
                  const entry = data.entries[i]

                  return (
                    <div key={m.id} className="py-3">
                      <div className="flex items-baseline justify-between gap-2">
                        <label className="text-sm font-medium">
                          {m.name}
                          {m.unit && (
                            <span className="ml-1 font-normal text-neutral-400">({m.unit})</span>
                          )}
                        </label>
                        {m.last && (
                          <span className="text-xs tabular-nums text-neutral-500 dark:text-neutral-400">
                            last{" "}
                            {m.twoSided
                              ? `L ${m.last.left ?? "—"} · R ${m.last.right ?? "—"}`
                              : m.last.value}
                            <span className="text-neutral-400"> · {m.last.date}</span>
                          </span>
                        )}
                      </div>

                      {/* Best of 3 per hand; the best attempt is saved (MT-8). */}
                      {m.bestOfThree ? (
                        <div className="mt-2 space-y-2">
                          {(m.twoSided ? ["left", "right"] : ["only"]).map((side) => (
                            <div key={side} className="flex items-center gap-2">
                              {m.twoSided && (
                                <span className="w-10 shrink-0 text-xs text-neutral-500
                                                 dark:text-neutral-400">
                                  {side === "left" ? "Left" : "Right"}
                                </span>
                              )}
                              {[0, 1, 2].map((n) => {
                                const key = side === "right" ? "attempts_right" : "attempts"
                                return (
                                  <input
                                    key={n} type="number" inputMode="decimal" step="any"
                                    aria-label={`${m.name} ${side} attempt ${n + 1}`}
                                    placeholder={`${n + 1}`}
                                    value={entry[key][n]}
                                    onChange={(ev) => {
                                      const next = [...entry[key]]
                                      next[n] = ev.target.value
                                      patch(i, { [key]: next } as Partial<EntryDraft>)
                                    }}
                                    className={cell}
                                  />
                                )
                              })}
                            </div>
                          ))}
                          <p className="text-xs text-neutral-500 dark:text-neutral-400">
                            Best of three is saved as the value.
                          </p>
                        </div>
                      ) : m.twoSided ? (
                        <div className="mt-2 flex gap-2">
                          <input type="number" inputMode="decimal" step="any" placeholder="Left"
                                 aria-label={`${m.name} left`} value={entry.value_left}
                                 onChange={(e) => patch(i, { value_left: e.target.value })}
                                 className={cell} />
                          <input type="number" inputMode="decimal" step="any" placeholder="Right"
                                 aria-label={`${m.name} right`} value={entry.value_right}
                                 onChange={(e) => patch(i, { value_right: e.target.value })}
                                 className={cell} />
                        </div>
                      ) : (
                        <input type="number" inputMode="decimal" step="any"
                               aria-label={m.name} value={entry.value}
                               onChange={(e) => patch(i, { value: e.target.value })}
                               className={`${cell} mt-2`} />
                      )}
                    </div>
                  )
                })}
              </div>
            </section>
          ))}

          {all.length === 0 && (
            <p className="mt-8 rounded-xl border border-dashed border-neutral-300 p-6 text-center
                          text-sm text-neutral-500 dark:border-neutral-700 dark:text-neutral-400">
              No metrics tracked for {client.name} yet.{" "}
              <Link href={`/clients/${client.id}/metrics`} className="underline">Pick some</Link>.
            </p>
          )}

          {all.length > 0 && (
            <div className="sticky bottom-20 mt-8 sm:bottom-4">
              <button type="submit" disabled={processing}
                      className="min-h-12 w-full rounded-lg bg-neutral-900 px-4 text-sm font-medium
                                 text-white shadow-lg disabled:opacity-60
                                 dark:bg-neutral-100 dark:text-neutral-900">
                Save assessment
              </button>
            </div>
          )}
        </form>
      </main>
    </Shell>
  )
}
