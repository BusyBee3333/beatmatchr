'use client';

import { useQuery } from '@tanstack/react-query';
import { getSourceClips, SourceClip } from '../lib/api';

interface ClipGridProps {
  projectId: string;
}

export function ClipGrid({ projectId }: ClipGridProps) {
  const {
    data: clips,
    isLoading,
    isError,
    error
  } = useQuery<SourceClip[], Error>({
    queryKey: ['projects', projectId, 'source-clips'],
    queryFn: () => getSourceClips(projectId)
  });

  if (isLoading) {
    return <p className="text-sm text-slate-500">Loading source clips...</p>;
  }

  if (isError) {
    return <p className="text-sm text-red-600">{error.message}</p>;
  }

  if (!clips || clips.length === 0) {
    return (
      <div className="rounded-lg border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500">
        No source clips found yet.
      </div>
    );
  }

  return (
    <div className="grid gap-4 sm:grid-cols-2">
      {clips.map((clip) => (
        <div key={clip.id} className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
          <h3 className="text-base font-medium text-slate-900">{clip.name}</h3>
          {clip.duration != null && (
            <p className="text-sm text-slate-500">Duration: {clip.duration.toFixed(1)}s</p>
          )}
          {clip.waveform_url && (
            <p className="truncate text-sm text-indigo-600">Waveform: {clip.waveform_url}</p>
          )}
        </div>
      ))}
    </div>
  );
}
