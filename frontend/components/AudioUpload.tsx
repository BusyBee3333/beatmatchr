'use client';

import { useMutation } from '@tanstack/react-query';
import { FormEvent, useState } from 'react';
import { uploadProjectAudio } from '../lib/api';

interface AudioUploadProps {
  projectId: string;
  onSuccess?: () => void;
}

export function AudioUpload({ projectId, onSuccess }: AudioUploadProps) {
  const [file, setFile] = useState<File | null>(null);

  const mutation = useMutation({
    mutationFn: async () => {
      if (!file) {
        throw new Error('Please select an audio file to upload.');
      }
      await uploadProjectAudio(projectId, file);
    },
    onSuccess
  });

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    mutation.mutate();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-3 rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div>
        <h2 className="text-lg font-semibold text-slate-900">Upload Audio</h2>
        <p className="text-sm text-slate-600">Attach a new audio track to this project.</p>
      </div>
      <input
        type="file"
        accept="audio/*"
        onChange={(event) => setFile(event.target.files?.[0] ?? null)}
        className="block w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
      />
      <button
        type="submit"
        disabled={mutation.isPending}
        className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {mutation.isPending ? 'Uploading...' : 'Upload'}
      </button>
      {mutation.isError && (
        <p className="text-sm text-red-600">{(mutation.error as Error).message}</p>
      )}
      {mutation.isSuccess && <p className="text-sm text-green-600">Audio uploaded successfully!</p>}
    </form>
  );
}
