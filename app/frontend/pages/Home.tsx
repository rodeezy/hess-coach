import { Head, Link } from "@inertiajs/react"
import Shell from "../components/Shell"

interface HomeProps {
  trainer: { name: string | null; business_name: string | null; email_address: string }
  counts: {
    clients: number
    exercises: number
    muscleGroups: number
    mainPatterns: number
    exerciseTypes: number
  }
}

export default function Home({ trainer, counts }: HomeProps) {
  const tiles = [
    { label: "Active clients", value: counts.clients },
    { label: "Exercises", value: counts.exercises },
    { label: "Exercise types", value: counts.exerciseTypes },
    { label: "Muscle groups", value: counts.muscleGroups },
    { label: "Main patterns", value: counts.mainPatterns },
  ]

  return (
    <Shell>
      <Head title="Home" />
      <main className="mx-auto max-w-3xl px-4 py-10">
        <p className="text-sm text-neutral-500 dark:text-neutral-400">
          {trainer.business_name ?? "Hess Coach"}
        </p>
        <h1 className="mt-1 text-2xl font-semibold tracking-tight text-neutral-900 dark:text-neutral-50">
          {trainer.name ?? trainer.email_address}
        </h1>

        <div className="mt-8 grid grid-cols-2 gap-3 sm:grid-cols-3">
          {tiles.map((t) => (
            <div
              key={t.label}
              className="rounded-xl border border-neutral-200 p-4 dark:border-neutral-800"
            >
              <div className="text-2xl font-semibold tabular-nums text-neutral-900 dark:text-neutral-50">
                {t.value}
              </div>
              <div className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">{t.label}</div>
            </div>
          ))}
        </div>

        <p className="mt-8 text-sm">
          <Link href="/library/import-review" className="underline">Review the library import</Link>
        </p>
      </main>
    </Shell>
  )
}
