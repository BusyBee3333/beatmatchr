'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { getLyrics, Lyrics, updateLyrics } from '../lib/api';
import { useEffect, useState } from 'react';

interface LyricsEditorProps {
  projectId: string;
}

export function LyricsEditor({ projectId }: LyricsEditorProps) {
  const queryClient = useQueryClient();
  const { data, isLoading, isError, error } = useQuery<Lyrics, Error>({
    queryKey: ['projects', projectId, 'lyrics'],
    queryFn: () => getLyrics(projectId)
  });

  const [text, setText] = useState('');

  useEffect(() => {
    if (data) {
      setText(data.raw_text ?? '');
    }
  }, [data]);

  const mutation = useMutation({
    mutationFn: () => updateLyrics(projectId, { raw_text: text }),
    onSuccess: (updated) => {
      queryClient.setQueryData(['projects', projectId, 'lyrics'], updated);
    }
  });

  return (
    <div className="space-y-3 rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div>
        <h2 className="text-lg font-semibold text-slate-900">Lyrics</h2>
        <p className="text-sm text-slate-600">Review and edit the current lyrics.</p>
      </div>
      {isLoading && <p className="text-sm text-slate-500">Loading lyrics...</p>}
      {isError && <p className="text-sm text-red-600">{error.message}</p>}
      {!isLoading && !isError && (
        <>
          <textarea
            value={text}
            onChange={(event) => setText(event.target.value)}
            rows={8}
            className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
          <button
            type="button"
            onClick={() => mutation.mutate()}
            disabled={mutation.isPending}
            className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {mutation.isPending ? 'Saving...' : 'Save Lyrics'}
          </button>
          {mutation.isError && (
            <p className="text-sm text-red-600">{(mutation.error as Error).message}</p>
          )}
          {mutation.isSuccess && <p className="text-sm text-green-600">Lyrics saved.</p>}
        </>
      )}
    </div>
  );
}
