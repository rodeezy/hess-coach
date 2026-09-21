import { Head, Link, router, useForm } from "@inertiajs/react"
import { useState } from "react"
import Shell from "../../components/Shell"
import TrendChart from "../../components/TrendChart"

interface Phase {
  id: string; name: string; startedOn: string | null
  weeks: number | null; sweetMin: number | null; sweetMax: number | null
}
interface Note {
  id: string; body: string; tag: string | null; isPinned: boolean; notedAt: string
}
interface Tile {
  id: string; key: string; name: string; group: string; unit: string | null
  direction: string; decimals: number; twoSided: boolean; computed: boolean
  points: { date: string; value: number | null; left: number | null; right: number | null }[]
  latest: { date: string; value: number | null; left: number | null; right: number | null } | null
  change: { value?: number; left?: number; right?: number } | null
}
interface Props {
  client: {
    id: string; name: string; email: string | null; phone: string | null
    status: string; startDate: string | null; age: number | null
    heightCm: string | null; discType: string | null
    usesPowerBlock: boolean; usesVbt: boolean; intakeNotes: string | null
    daysSinceLastSession: number | null
    lastAssessmentOn: string | null; assessmentOverdue: boolean
    nextReportDueOn: string | null
    phase: Phase | null
  }
  pinnedNotes: Note[]
  recentNotes: Note[]
  trackedMetrics: Tile[]
  phases: { id: string; name: string; sweetMin: number | null; sweetMax: number | null }[]
}

// Program, History, Goals and Reports arrive in phases 3-6.
const TABS = ["Overview", "Program", "History", "Metrics", "Goals", "Notes", "Reports"]
const COMING = { Program: 3, History: 4, Goals: 5, Reports: 6 } as const

export default function ClientShow({ client, pinnedNotes, recentNotes, trackedMetrics, phases }: Props) {
  const [tab, setTab] = useState("Overview")
  const [editingPhase, setEditingPhase] = useState(false)

  return (
    <Shell>
      <Head title={client.name} />
      <main className="mx-auto max-w-3xl px-4 py-8">
        <header>
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <h1 className="text-2xl font-semibold tracking-tight">{client.name}</h1>
              <p className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">
                {[
                  client.age && `${client.age}y`,
                  client.daysSinceLastSession == null
                    ? "no sessions yet"
                    : `${client.daysSinceLastSession}d since last session`,
                  client.status === "archived" && "archived",
                ].filter(Boolean).join(" · ")}
              </p>
            </div>
            <div className="flex gap-2">
              <Link href={`/clients/${client.id}/assessment`}
                    className="inline-flex min-h-11 items-center rounded-lg bg-neutral-900 px-4
                               text-sm font-medium text-white dark:bg-neutral-100 dark:text-neutral-900">
                Assessment
              </Link>
              <Link href={`/clients/${client.id}/edit`}
                    className="inline-flex min-h-11 items-center rounded-lg border border-neutral-300
                               px-3 text-sm dark:border-neutral-700">
                Edit
              </Link>
            </div>
          </div>

          <PhaseHeader client={client} phases={phases}
                       editing={editingPhase} setEditing={setEditingPhase} />

          {/* Pinned notes ride at the top of the overview (NT-1). */}
          {pinnedNotes.length > 0 && (
            <ul className="mt-4 space-y-2">
              {pinnedNotes.map((n) => (
                <li key={n.id}
                    className="rounded-lg border border-amber-300 px-3 py-2 text-sm
                               dark:border-amber-800">
                  {n.tag && (
                    <span className="mr-2 text-xs uppercase tracking-wide text-amber-700
                                     dark:text-amber-500">{n.tag}</span>
                  )}
                  {n.body}
                </li>
              ))}
            </ul>
          )}
        </header>

        <nav className="mt-6 flex gap-1 overflow-x-auto border-b border-neutral-200 dark:border-neutral-800">
          {TABS.map((t) => (
            <button key={t} onClick={() => setTab(t)}
                    aria-current={tab === t ? "page" : undefined}
                    className={`shrink-0 border-b-2 px-3 py-2 text-sm ${
                      tab === t
                        ? "border-neutral-900 font-medium dark:border-neutral-100"
                        : "border-transparent text-neutral-500 dark:text-neutral-400"
                    }`}>
              {t}
            </button>
          ))}
        </nav>

        <section className="mt-6">
          {tab === "Overview" && (
            <Overview client={client} tiles={trackedMetrics} notes={recentNotes} />
          )}
          {tab === "Metrics" && (
            <>
              <div className="flex justify-end">
                <Link href={`/clients/${client.id}/metrics`} className="text-sm underline">
                  Manage tracked metrics
                </Link>
              </div>
              <MetricTiles tiles={trackedMetrics} clientId={client.id} />
            </>
          )}
          {tab === "Notes" && <NotesTab clientId={client.id} notes={recentNotes} />}
          {tab in COMING && (
            <p className="rounded-xl border border-dashed border-neutral-300 p-8 text-center text-sm
                          text-neutral-500 dark:border-neutral-700 dark:text-neutral-400">
              {tab} arrives in phase {COMING[tab as keyof typeof COMING]}.
            </p>
          )}
        </section>
      </main>
    </Shell>
  )
}

/** Phase and week count beside the sweet spot. Information only (CL-6). */
function PhaseHeader({ client, phases, editing, setEditing }: {
  client: Props["client"]; phases: Props["phases"]
  editing: boolean; setEditing: (v: boolean) => void
}) {
  const { data, setData, post, processing } = useForm({
    phase_id: client.phase?.id ?? "",
    started_on: client.phase?.startedOn ?? new Date().toISOString().slice(0, 10),
  })

  if (editing) {
    return (
      <form
        onSubmit={(e) => {
          e.preventDefault()
          post(`/clients/${client.id}/change-phase`, { onSuccess: () => setEditing(false) })
        }}
        className="mt-4 flex flex-wrap items-end gap-2 rounded-xl border border-neutral-200 p-3
                   dark:border-neutral-800"
      >
        <label className="text-sm">
          Phase
          <select value={data.phase_id} onChange={(e) => setData("phase_id", e.target.value)}
                  className="mt-1 block min-h-11 rounded-lg border border-neutral-300 bg-transparent
                             px-3 text-sm dark:border-neutral-700">
            <option value="">—</option>
            {phases.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
          </select>
        </label>
        <label className="text-sm">
          Started
          <input type="date" value={data.started_on}
                 onChange={(e) => setData("started_on", e.target.value)}
                 className="mt-1 block min-h-11 rounded-lg border border-neutral-300 bg-transparent
                            px-3 text-sm dark:border-neutral-700" />
        </label>
        <button type="submit" disabled={processing}
                className="min-h-11 rounded-lg bg-neutral-900 px-4 text-sm text-white
                           dark:bg-neutral-100 dark:text-neutral-900">Save</button>
        <button type="button" onClick={() => setEditing(false)}
                className="min-h-11 rounded-lg border border-neutral-300 px-3 text-sm
                           dark:border-neutral-700">Cancel</button>
      </form>
    )
  }

  const p = client.phase
  return (
    <button onClick={() => setEditing(true)}
            className="mt-4 flex w-full items-center justify-between rounded-xl border
                       border-neutral-200 px-3 py-2.5 text-left text-sm dark:border-neutral-800">
      <span>
        {p ? (
          <>
            <span className="font-medium">{p.name}</span>
            {p.weeks && <span>, week {p.weeks}</span>}
            {p.sweetMin && p.sweetMax && (
              <span className="text-neutral-500 dark:text-neutral-400">
                {" "}(sweet spot {p.sweetMin}–{p.sweetMax})
              </span>
            )}
          </>
        ) : (
          <span className="text-neutral-500 dark:text-neutral-400">No phase set</span>
        )}
      </span>
      <span className="text-xs text-neutral-400">Change</span>
    </button>
  )
}

function Overview({ client, tiles, notes }: {
  client: Props["client"]; tiles: Tile[]; notes: Note[]
}) {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        <Stat label="Last assessment"
              value={client.lastAssessmentOn ?? "Never"}
              warn={client.assessmentOverdue} />
        <Stat label="Next report due" value={client.nextReportDueOn ?? "—"} />
        <Stat label="Started" value={client.startDate ?? "—"} />
      </div>

      <MetricTiles tiles={tiles} clientId={client.id} compact />

      {notes.length > 0 && (
        <div>
          <h2 className="text-sm font-semibold">Recent notes</h2>
          <ul className="mt-2 space-y-1.5 text-sm text-neutral-600 dark:text-neutral-300">
            {notes.map((n) => <li key={n.id}>{n.body}</li>)}
          </ul>
        </div>
      )}
    </div>
  )
}

function Stat({ label, value, warn }: { label: string; value: string; warn?: boolean }) {
  return (
    <div className={`rounded-xl border p-3 ${
      warn ? "border-amber-300 dark:border-amber-800" : "border-neutral-200 dark:border-neutral-800"
    }`}>
      <div className="text-sm font-medium tabular-nums">{value}</div>
      <div className="mt-0.5 text-xs text-neutral-500 dark:text-neutral-400">{label}</div>
    </div>
  )
}

function MetricTiles({ tiles, clientId, compact }: {
  tiles: Tile[]; clientId: string; compact?: boolean
}) {
  if (tiles.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-neutral-300 p-6 text-center text-sm
                    text-neutral-500 dark:border-neutral-700 dark:text-neutral-400">
        No metrics tracked yet.{" "}
        <Link href={`/clients/${clientId}/metrics`} className="underline">Choose which to track</Link>.
      </p>
    )
  }

  return (
    <div className="space-y-4">
      {tiles.map((t) => {
        const hasData = t.points.length > 0
        // Colour by the metric's own direction; neutral metrics get no colour (6.6).
        const delta = t.change?.value
        const good = delta == null || t.direction === "neutral"
          ? null
          : (t.direction === "up" ? delta > 0 : delta < 0)

        return (
          <div key={t.id} className="rounded-xl border border-neutral-200 p-4 dark:border-neutral-800">
            <div className="flex items-baseline justify-between gap-2">
              <h3 className="text-sm font-medium">
                {t.name}
                {t.computed && (
                  <span className="ml-2 text-xs font-normal text-neutral-400">computed</span>
                )}
              </h3>
              {hasData && t.latest && (
                <span className="text-sm tabular-nums">
                  {t.twoSided
                    ? `L ${t.latest.left ?? "—"} · R ${t.latest.right ?? "—"}`
                    : t.latest.value}
                  {t.unit && <span className="text-neutral-400"> {t.unit}</span>}
                  {delta != null && (
                    <span className={
                      good === null ? "ml-2 text-xs text-neutral-500"
                        : good ? "ml-2 text-xs text-emerald-600 dark:text-emerald-400"
                               : "ml-2 text-xs text-red-600 dark:text-red-400"
                    }>
                      {delta > 0 ? "+" : ""}{delta}
                    </span>
                  )}
                </span>
              )}
            </div>

            {hasData ? (
              <div className="mt-2">
                <TrendChart points={t.points} twoSided={t.twoSided} unit={t.unit}
                            decimals={t.decimals} height={compact ? 120 : 160} />
              </div>
            ) : (
              <p className="mt-1 text-xs text-neutral-500 dark:text-neutral-400">
                No entries yet.
              </p>
            )}
          </div>
        )
      })}
    </div>
  )
}

function NotesTab({ clientId, notes }: { clientId: string; notes: Note[] }) {
  const { data, setData, post, processing, reset } = useForm({ body: "", tag: "", is_pinned: false })

  return (
    <div className="space-y-4">
      <form
        onSubmit={(e) => {
          e.preventDefault()
          post(`/clients/${clientId}/notes`, { onSuccess: () => reset() })
        }}
        className="space-y-2 rounded-xl border border-neutral-200 p-3 dark:border-neutral-800"
      >
        <textarea
          value={data.body} rows={2} required placeholder="Add a note"
          aria-label="Note"
          onChange={(e) => setData("body", e.target.value)}
          className="w-full rounded-lg border border-neutral-300 bg-transparent px-3 py-2 text-base
                     dark:border-neutral-700"
        />
        <div className="flex flex-wrap items-center gap-2">
          <select value={data.tag} onChange={(e) => setData("tag", e.target.value)}
                  aria-label="Tag"
                  className="min-h-11 rounded-lg border border-neutral-300 bg-transparent px-3 text-sm
                             dark:border-neutral-700">
            <option value="">No tag</option>
            {["injury", "preference", "lifestyle", "program", "general"].map((t) => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={data.is_pinned} className="size-4"
                   onChange={(e) => setData("is_pinned", e.target.checked)} />
            Pin
          </label>
          <button type="submit" disabled={processing}
                  className="ml-auto min-h-11 rounded-lg bg-neutral-900 px-4 text-sm text-white
                             dark:bg-neutral-100 dark:text-neutral-900">
            Add
          </button>
        </div>
      </form>

      <div className="flex justify-end">
        <Link href={`/clients/${clientId}/notes`} className="text-sm underline">
          All notes and search
        </Link>
      </div>

      <ul className="divide-y divide-neutral-200 dark:divide-neutral-800">
        {notes.map((n) => (
          <li key={n.id} className="flex items-start gap-2 py-2.5 text-sm">
            <span className="flex-1">
              {n.tag && (
                <span className="mr-2 text-xs uppercase tracking-wide text-neutral-400">{n.tag}</span>
              )}
              {n.body}
            </span>
            <button
              onClick={() => router.delete(`/clients/${clientId}/notes/${n.id}`)}
              className="text-xs text-neutral-400 underline"
            >
              Delete
            </button>
          </li>
        ))}
      </ul>
    </div>
  )
}
