'use client';

import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { getProjects, Project } from '../../lib/api';

export default function ProjectsPage() {
  const {
    data: projects,
    isLoading,
    isError,
    error
  } = useQuery<Project[], Error>({
    queryKey: ['projects'],
    queryFn: getProjects
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Projects</h1>
          <p className="text-sm text-slate-600">Browse and open your existing audio projects.</p>
        </div>
        <Link
          href="/"
          className="rounded-md border border-indigo-200 px-3 py-2 text-sm text-indigo-600 hover:bg-indigo-50"
        >
          New Project
        </Link>
      </div>

      {isLoading && <p className="text-slate-500">Loading projects...</p>}
      {isError && <p className="text-red-600">{error.message}</p>}

      {projects && projects.length === 0 && (
        <div className="rounded-lg border border-dashed border-slate-300 bg-white p-8 text-center text-slate-500">
          No projects yet. Create one from the backend or CLI.
        </div>
      )}

      {projects && projects.length > 0 && (
        <ul className="grid gap-4 sm:grid-cols-2">
          {projects.map((project) => (
            <li key={project.id} className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <h2 className="text-lg font-medium text-slate-900">{project.name}</h2>
              {project.description && <p className="mt-1 text-sm text-slate-600">{project.description}</p>}
              <div className="mt-4 flex items-center justify-between text-sm text-slate-500">
                {project.created_at && <span>Created {new Date(project.created_at).toLocaleDateString()}</span>}
                <Link href={`/projects/${project.id}`} className="text-indigo-600 hover:text-indigo-500">
                  Open
                </Link>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
