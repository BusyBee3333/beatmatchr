const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:8000/api';

export interface Project {
  id: string;
  name: string;
  description?: string | null;
  created_at?: string;
}

export interface SourceClip {
  id: string;
  name: string;
  duration?: number;
  waveform_url?: string;
}

export interface Lyrics {
  raw_text: string;
  updated_at?: string;
}

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(errorText || response.statusText);
  }
  if (response.status === 204) {
    return undefined as T;
  }
  return (await response.json()) as T;
}

export async function getProjects(): Promise<Project[]> {
  const response = await fetch(`${API_BASE_URL}/projects`, { cache: 'no-store' });
  return handleResponse<Project[]>(response);
}

export async function getProject(projectId: string): Promise<Project> {
  const response = await fetch(`${API_BASE_URL}/projects/${projectId}`, { cache: 'no-store' });
  return handleResponse<Project>(response);
}

export async function uploadProjectAudio(projectId: string, file: File): Promise<void> {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch(`${API_BASE_URL}/projects/${projectId}/audio`, {
    method: 'POST',
    body: formData
  });

  await handleResponse<void>(response);
}

export async function getSourceClips(projectId: string): Promise<SourceClip[]> {
  const response = await fetch(`${API_BASE_URL}/projects/${projectId}/source-clips`, {
    cache: 'no-store'
  });
  return handleResponse<SourceClip[]>(response);
}

export async function getLyrics(projectId: string): Promise<Lyrics> {
  const response = await fetch(`${API_BASE_URL}/projects/${projectId}/lyrics`, {
    cache: 'no-store'
  });
  return handleResponse<Lyrics>(response);
}

export async function updateLyrics(projectId: string, lyrics: Lyrics): Promise<Lyrics> {
  const response = await fetch(`${API_BASE_URL}/projects/${projectId}/lyrics`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(lyrics)
  });
  return handleResponse<Lyrics>(response);
}
