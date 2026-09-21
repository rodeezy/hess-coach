import { Head, Link, router } from "@inertiajs/react"
import { useState } from "react"
import Shell from "../../components/Shell"

interface ClientRow {
  id: string; name: string; status: string
  daysSinceLastSession: number | null
  lastSessionOn: string | null
  nextReportDueOn: string | null
  assessmentOverdue: boolean
  phase: string | null
  weeksInPhase: number | null
}
interface Props {
  filters: { q?: string; status?: string }
  clients: ClientRow[]
  counts: { active: number; archived: number }
}

export default function ClientsIndex({ filters, clients, counts }: Props) {
  const [q, setQ] = useState(filters.q ?? "")
  const showingArchived = filters.status === "archived"

  const go = (next: Record<string, string>) =>
    router.get("/clients", { ...filters, ...next }, { preserveState: true, replace: true })

  return (
    <Shell>
      <Head title="Clients" />
      <main className="mx-auto max-w-3xl px-4 py-8">
        <header className="flex flex-wrap items-center justify-between gap-3">
          <h1 className="text-2xl font-semibold tracking-tight">Clients</h1>
          <Link
            href="/clients/new"
            className="inline-flex min-h-11 items-center rounded-lg bg-neutral-900 px-4 text-sm
                       font-medium text-white dark:bg-neutral-100 dark:text-neutral-900"
          >
            Add client
          </Link>
        </header>

        <form className="mt-6 flex gap-2" onSubmit={(e) => { e.preventDefault(); go({ q }) }}>
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search clients"
            aria-label="Search clients"
            className="min-h-11 flex-1 rounded-lg border border-neutral-300 bg-transparent px-3
                       text-base dark:border-neutral-700"
          />
          <button
            type="button"
            onClick={() => go({ status: showingArchived ? "" : "archived" })}
            aria-pressed={showingArchived}
            className={`min-h-11 rounded-lg border px-3 text-sm ${
              showingArchived
                ? "border-transparent bg-neutral-900 text-white dark:bg-neutral-100 dark:text-neutral-900"
                : "border-neutral-300 dark:border-neutral-700"
            }`}
          >
            Archived ({counts.archived})
          </button>
        </form>

        {clients.length === 0 && (
          <div className="mt-10 rounded-xl border border-dashed border-neutral-300 p-8 text-center
                          dark:border-neutral-700">
            <p className="text-sm text-neutral-600 dark:text-neutral-300">
              {showingArchived ? "No archived clients." : "No clients yet."}
            </p>
            {!showingArchived && (
              <Link href="/clients/new" className="mt-2 inline-block text-sm underline">
                Add your first client
              </Link>
            )}
          </div>
        )}

        {/* Sorted by last session date (CL-2). */}
        <ul className="mt-4 divide-y divide-neutral-200 dark:divide-neutral-800">
          {clients.map((c) => (
            <li key={c.id}>
              <Link href={`/clients/${c.id}`} className="flex items-center gap-3 py-3">
                <span className="flex-1">
                  <span className="block text-sm font-medium">{c.name}</span>
                  <span className="mt-0.5 block text-xs text-neutral-500 dark:text-neutral-400">
                    {c.daysSinceLastSession == null
                      ? "No sessions yet"
                      : c.daysSinceLastSession === 0
                        ? "Trained today"
                        : `${c.daysSinceLastSession}d since last session`}
                    {c.phase && ` · ${c.phase}${c.weeksInPhase ? `, week ${c.weeksInPhase}` : ""}`}
                  </span>
                </span>
                {c.assessmentOverdue && (
                  <span className="rounded bg-amber-100 px-1.5 py-0.5 text-[10px] font-medium
                                   text-amber-800 dark:bg-amber-950 dark:text-amber-300">
                    assessment due
                  </span>
                )}
              </Link>
            </li>
          ))}
        </ul>
      </main>
    </Shell>
  )
}
