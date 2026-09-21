import { Head, router, useForm } from "@inertiajs/react"
import { useState } from "react"
import Shell from "../components/Shell"

interface Muscle { name: string; role: string }
interface Exercise {
  id: string; name: string; videoUrl: string | null; instructions: string | null
  needsVideo: boolean; prescription: string; e1rmEligible: boolean
  isUnilateral: boolean; loadType: string; implementCount: number; muscles: Muscle[]
}
interface TypeGroup {
  id: string; name: string; group: string; bodyArea: string | null
  defaultBlock: string; prescription: string; exercises: Exercise[]
}
interface Props {
  filters: { q?: string; type_id?: string; needs_video?: string; muscle_group_id?: string }
  types: TypeGroup[]
  muscleGroups: { id: string; name: string }[]
  allTypes: { id: string; name: string }[]
  totals: { exercises: number; needsVideo: number; e1rm: number }
}

const BLOCK_LABEL: Record<string, string> = {
  movement_prep: "Movement Prep", neural_prep: "Neural Prep", power: "Power",
  strength: "Strength", accessory: "Accessory", aerobic: "Aerobic Output", cool_down: "Cool Down",
}

export default function Library({ filters, types, muscleGroups, allTypes, totals }: Props) {
  const [q, setQ] = useState(filters.q ?? "")
  const [open, setOpen] = useState<string | null>(null)
  const upload = useForm<{ file: File | null }>({ file: null })

  const apply = (next: Partial<Props["filters"]>) =>
    router.get("/exercises", { ...filters, ...next }, { preserveState: true, replace: true })

  return (
    <Shell>
      <Head title="Library" />
      <main className="mx-auto max-w-4xl px-4 py-8">
        <header className="flex flex-wrap items-baseline justify-between gap-2">
          <h1 className="text-2xl font-semibold tracking-tight">Library</h1>
          <p className="text-sm text-neutral-500 dark:text-neutral-400">
            {totals.exercises} exercises · {totals.e1rm} e1RM eligible · {totals.needsVideo} need video
          </p>
        </header>

        {/* Additive and never deletes: adds new exercises and refreshes video links and
            how-to text (EX-7). Open by default when the library is nearly empty. */}
        <details
          open={totals.exercises < 50}
          className="mt-6 rounded-xl border border-neutral-200 p-4 dark:border-neutral-800"
        >
          <summary className="cursor-pointer text-sm font-medium">Import from CSV</summary>
          <form
            className="mt-3 space-y-3"
            onSubmit={(e) => {
              e.preventDefault()
              upload.post("/exercises/import", { forceFormData: true })
            }}
          >
            <p className="text-sm text-neutral-600 dark:text-neutral-300">
              Upload the exercise sheet as a CSV. Running it again is safe: it adds new
              exercises and refreshes video links and how-to text, and never deletes.
            </p>
            <input
              type="file"
              accept=".csv,text/csv"
              aria-label="Exercise CSV"
              onChange={(e) => upload.setData("file", e.target.files?.[0] ?? null)}
              className="block w-full text-sm file:mr-3 file:min-h-11 file:rounded-lg file:border-0
                         file:bg-neutral-900 file:px-4 file:text-sm file:font-medium file:text-white
                         dark:file:bg-neutral-100 dark:file:text-neutral-900"
            />
            {upload.errors.file && (
              <p role="alert" className="text-sm text-red-600 dark:text-red-400">
                {upload.errors.file}
              </p>
            )}
            <button
              type="submit"
              disabled={!upload.data.file || upload.processing}
              className="btn-primary disabled:opacity-50"
            >
              {upload.processing ? "Importing…" : "Import"}
            </button>
          </form>
        </details>

        <form
          className="mt-6 flex flex-wrap gap-2"
          onSubmit={(e) => { e.preventDefault(); apply({ q }) }}
        >
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search exercises"
            aria-label="Search exercises"
            className="min-h-11 flex-1 rounded-lg border border-neutral-300 bg-transparent px-3
                       text-base dark:border-neutral-700"
          />
          <select
            value={filters.type_id ?? ""}
            onChange={(e) => apply({ type_id: e.target.value })}
            aria-label="Filter by exercise type"
            className="min-h-11 rounded-lg border border-neutral-300 bg-transparent px-3 text-sm
                       dark:border-neutral-700"
          >
            <option value="">All types</option>
            {allTypes.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>
          <select
            value={filters.muscle_group_id ?? ""}
            onChange={(e) => apply({ muscle_group_id: e.target.value })}
            aria-label="Filter by muscle group"
            className="min-h-11 rounded-lg border border-neutral-300 bg-transparent px-3 text-sm
                       dark:border-neutral-700"
          >
            <option value="">All muscles</option>
            {muscleGroups.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
          </select>
          <button
            type="button"
            onClick={() => apply({ needs_video: filters.needs_video === "1" ? "" : "1" })}
            aria-pressed={filters.needs_video === "1"}
            className={`min-h-11 rounded-lg border px-3 text-sm ${
              filters.needs_video === "1"
                ? "border-transparent bg-neutral-900 text-white dark:bg-neutral-100 dark:text-neutral-900"
                : "border-neutral-300 dark:border-neutral-700"
            }`}
          >
            Needs video
          </button>
        </form>

        {types.length === 0 && (
          <p className="mt-10 text-sm text-neutral-500 dark:text-neutral-400">
            No exercises match those filters.
          </p>
        )}

        {types.map((type) => (
          <section key={type.id} className="mt-8">
            <h2 className="flex flex-wrap items-baseline gap-x-2 text-sm font-semibold">
              {type.name}
              <span className="font-normal text-neutral-500 dark:text-neutral-400">
                {type.exercises.length} · {BLOCK_LABEL[type.defaultBlock]} · {type.prescription}
              </span>
            </h2>

            {/* Sheet order is progression order, easiest first (spec EX-2). */}
            <ol className="mt-2 divide-y divide-neutral-200 dark:divide-neutral-800">
              {type.exercises.map((ex, i) => (
                <li key={ex.id}>
                  <button
                    onClick={() => setOpen(open === ex.id ? null : ex.id)}
                    aria-expanded={open === ex.id}
                    className="flex w-full items-center gap-3 py-2.5 text-left"
                  >
                    <span className="w-6 shrink-0 text-xs tabular-nums text-neutral-400">{i + 1}</span>
                    <span className="flex-1 text-sm">{ex.name}</span>
                    {ex.e1rmEligible && (
                      <span className="rounded bg-neutral-100 px-1.5 py-0.5 text-[10px] font-medium
                                       text-neutral-600 dark:bg-neutral-800 dark:text-neutral-300">
                        e1RM
                      </span>
                    )}
                    {ex.needsVideo && (
                      <span className="text-[10px] text-amber-700 dark:text-amber-500">no video</span>
                    )}
                  </button>

                  {open === ex.id && (
                    <div className="pb-3 pl-9 text-sm text-neutral-600 dark:text-neutral-300">
                      <p className="flex flex-wrap gap-x-3 text-xs text-neutral-500 dark:text-neutral-400">
                        <span>{ex.prescription}</span>
                        <span>{ex.loadType.replace(/_/g, " ")}</span>
                        {ex.isUnilateral && <span>unilateral</span>}
                        {ex.implementCount > 1 && <span>×{ex.implementCount} implements</span>}
                      </p>
                      {ex.muscles.length > 0 && (
                        <p className="mt-1 text-xs text-neutral-500 dark:text-neutral-400">
                          {ex.muscles.map((m) =>
                            m.role === "primary" ? m.name : `${m.name} (secondary)`).join(", ")}
                        </p>
                      )}
                      {ex.videoUrl && (
                        <a href={ex.videoUrl} target="_blank" rel="noreferrer"
                           className="mt-2 inline-block text-xs underline">
                          Watch video
                        </a>
                      )}
                      {ex.instructions && <p className="mt-2 leading-relaxed">{ex.instructions}</p>}
                    </div>
                  )}
                </li>
              ))}
            </ol>
          </section>
        ))}
      </main>
    </Shell>
  )
}
