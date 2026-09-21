import { Head, Link } from "@inertiajs/react"
import Shell from "../components/Shell"

interface Group { why: string; action: string; rows: { name: string; type: string }[] }
interface Props {
  available: boolean
  summary?: { created: number; updated: number; exceptions: number }
  groups: Group[]
  unmatched: { type: string; count: number }[]
}

const ACTION_COPY: Record<string, { label: string; note: string }> = {
  overridden: {
    label: "Changed on import",
    note: "The exercise type's defaults were wrong for these, so the import applied a named override. Check the reasoning.",
  },
  skipped: {
    label: "Not imported",
    note: "Kept out of the library on purpose.",
  },
  flag: {
    label: "Worth a look",
    note: "Nothing was changed. Your sheet disagrees with itself here.",
  },
}

export default function ImportReview({ available, summary, groups, unmatched }: Props) {
  if (!available) {
    return (
      <Shell>
        <Head title="Import review" />
        <main className="mx-auto max-w-3xl px-4 py-8">
          <h1 className="text-2xl font-semibold tracking-tight">Import review</h1>
          <p className="mt-4 text-sm text-neutral-500 dark:text-neutral-400">
            There is no import to review. The review appears right after you import a CSV
            from the{" "}
            <Link href="/exercises" className="underline">Library</Link>.
          </p>
        </main>
      </Shell>
    )
  }

  const byAction = ["overridden", "flag", "skipped"]
    .map((a) => ({ action: a, groups: groups.filter((g) => g.action === a) }))
    .filter((s) => s.groups.length > 0)

  return (
    <Shell>
      <Head title="Import review" />
      <main className="mx-auto max-w-3xl px-4 py-8">
        <h1 className="text-2xl font-semibold tracking-tight">Import review</h1>
        <p className="mt-2 max-w-prose text-sm text-neutral-600 dark:text-neutral-300">
          Your sheet imported as-is. These {summary?.exceptions} rows are where the import either
          overrode a type default or noticed something inconsistent. Read it once, then get on with it.
        </p>

        {unmatched.length > 0 && (
          <div className="mt-6 rounded-xl border border-amber-300 p-4 dark:border-amber-800">
            <h2 className="text-sm font-semibold">Unrecognised exercise types</h2>
            <p className="mt-1 text-sm text-neutral-600 dark:text-neutral-300">
              These rows were not imported because their type is not in the app.
            </p>
            <ul className="mt-2 text-sm">
              {unmatched.map((u) => (
                <li key={u.type}>{u.type || "(blank)"} — {u.count} rows</li>
              ))}
            </ul>
          </div>
        )}

        {byAction.map(({ action, groups: list }) => (
          <section key={action} className="mt-8">
            <h2 className="text-sm font-semibold">{ACTION_COPY[action].label}</h2>
            <p className="mt-1 max-w-prose text-sm text-neutral-500 dark:text-neutral-400">
              {ACTION_COPY[action].note}
            </p>

            <div className="mt-3 space-y-3">
              {list.map((g) => (
                <div key={g.why} className="rounded-xl border border-neutral-200 p-4 dark:border-neutral-800">
                  <p className="text-sm font-medium">{g.why}</p>
                  <ul className="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-sm text-neutral-600 dark:text-neutral-300">
                    {g.rows.map((r) => (
                      <li key={`${r.type}-${r.name}`}>
                        {r.name}
                        <span className="text-neutral-400 dark:text-neutral-500"> · {r.type}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          </section>
        ))}

        <p className="mt-10 text-sm">
          <Link href="/exercises" className="underline">Go to the library</Link>
        </p>
      </main>
    </Shell>
  )
}
