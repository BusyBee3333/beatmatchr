'use client';

import { useParams } from 'next/navigation';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { getProject, Project } from '../../../lib/api';
import { AudioUpload } from '../../../components/AudioUpload';
import { ClipGrid } from '../../../components/ClipGrid';
import { LyricsEditor } from '../../../components/LyricsEditor';

export default function ProjectDetailPage() {
  const params = useParams<{ id: string }>();
  const projectId = params?.id;
  const queryClient = useQueryClient();

  const {
    data: project,
    isLoading,
    isError,
    error
  } = useQuery<Project, Error>({
    queryKey: ['projects', projectId],
    queryFn: () => getProject(projectId as string),
    enabled: Boolean(projectId)
  });

  if (!projectId) {
    return <p className="text-sm text-red-600">Project ID is missing.</p>;
  }

  return (
    <div className="space-y-8">
      {isLoading && <p className="text-slate-500">Loading project...</p>}
      {isError && <p className="text-red-600">{error.message}</p>}
      {project && (
        <>
          <div className="space-y-2">
            <h1 className="text-3xl font-semibold text-slate-900">{project.name}</h1>
            {project.description && <p className="text-slate-600">{project.description}</p>}
          </div>
          <div className="grid gap-6 lg:grid-cols-2">
            <AudioUpload
              projectId={projectId}
              onSuccess={() =>
                queryClient.invalidateQueries({ queryKey: ['projects', projectId, 'source-clips'] })
              }
            />
            <LyricsEditor projectId={projectId} />
          </div>
          <section className="space-y-4">
            <h2 className="text-xl font-semibold text-slate-900">Source Clips</h2>
            <ClipGrid projectId={projectId} />
          </section>
        </>
      )}
    </div>
  );
}
