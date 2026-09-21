import { Head, Link } from "@inertiajs/react"
import Shell from "../components/Shell"

interface Props {
  trainer: { name: string | null; business_name: string | null } | null
  counts: { clients: number; exercises: number }
  assessmentsDue: { id: string; name: string; lastAssessmentOn: string | null }[]
  notSeen: { id: string; name: string; days: number | null }[]
}

export default function Home({ trainer, counts, assessmentsDue, notSeen }: Props) {
  return (
    <Shell>
      <Head title="Home" />
      <main className="mx-auto max-w-3xl px-4 py-8">
        <p className="text-sm text-neutral-500 dark:text-neutral-400">
          {trainer?.business_name ?? "Hess Coach"}
        </p>
        <h1 className="mt-1 text-2xl font-semibold tracking-tight">
          {trainer?.name ?? "Home"}
        </h1>

        <div className="mt-6 grid grid-cols-2 gap-3">
          <Link href="/clients"
                className="rounded-xl border border-neutral-200 p-4 dark:border-neutral-800">
            <div className="text-2xl font-semibold tabular-nums">{counts.clients}</div>
            <div className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">Active clients</div>
          </Link>
          <Link href="/exercises"
                className="rounded-xl border border-neutral-200 p-4 dark:border-neutral-800">
            <div className="text-2xl font-semibold tabular-nums">{counts.exercises}</div>
            <div className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">Exercises</div>
          </Link>
        </div>

        <Queue title="Assessments due" empty="Everyone is up to date."
               rows={assessmentsDue.map((c) => ({
                 id: c.id, name: c.name,
                 detail: c.lastAssessmentOn ? `last ${c.lastAssessmentOn}` : "never assessed",
                 href: `/clients/${c.id}/assessment`,
               }))} />

        <Queue title="Not seen in 10+ days" empty="Everyone has trained recently."
               rows={notSeen.map((c) => ({
                 id: c.id, name: c.name,
                 detail: c.days == null ? "no sessions yet" : `${c.days}d ago`,
                 href: `/clients/${c.id}`,
               }))} />

        <p className="mt-10 text-sm text-neutral-500 dark:text-neutral-400">
          Today's sessions and report reminders arrive with phases 4 and 6.{" "}
          <Link href="/library/import-review" className="underline">Library import review</Link>
        </p>
      </main>
    </Shell>
  )
}

function Queue({ title, empty, rows }: {
  title: string; empty: string
  rows: { id: string; name: string; detail: string; href: string }[]
}) {
  return (
    <section className="mt-8">
      <h2 className="text-sm font-semibold">{title}</h2>
      {rows.length === 0 ? (
        <p className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">{empty}</p>
      ) : (
        <ul className="mt-2 divide-y divide-neutral-200 dark:divide-neutral-800">
          {rows.map((r) => (
            <li key={r.id}>
              <Link href={r.href} className="flex items-center justify-between gap-2 py-2.5 text-sm">
                <span>{r.name}</span>
                <span className="text-xs text-neutral-500 dark:text-neutral-400">{r.detail}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}
