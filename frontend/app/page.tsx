import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="flex flex-col items-center justify-center gap-6 py-24 text-center">
      <h1 className="text-4xl font-bold text-slate-900">Welcome to Beatmatchr</h1>
      <p className="max-w-xl text-lg text-slate-600">
        Manage your audio projects, organize source clips, and fine-tune lyrics in a clean, focused editor.
      </p>
      <Link
        href="/projects"
        className="rounded-md bg-indigo-600 px-6 py-3 text-white shadow-sm transition hover:bg-indigo-500"
      >
        Create Project
      </Link>
    </div>
  );
}
