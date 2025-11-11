import './globals.css';
import type { Metadata } from 'next';
import { Providers } from '../components/providers';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Beatmatchr',
  description: 'Frontend for Beatmatchr project editor'
};

export default function RootLayout({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-slate-50 text-slate-900">
        <Providers>
          <div className="min-h-screen flex flex-col">
            <header className="border-b border-slate-200 bg-white">
              <div className="mx-auto flex w-full max-w-5xl items-center justify-between px-6 py-4">
                <Link href="/" className="text-lg font-semibold">
                  Beatmatchr
                </Link>
                <nav className="flex items-center gap-4 text-sm">
                  <Link href="/" className="hover:text-slate-600">
                    Home
                  </Link>
                  <Link href="/projects" className="hover:text-slate-600">
                    Projects
                  </Link>
                </nav>
              </div>
            </header>
            <main className="flex-1">
              <div className="mx-auto w-full max-w-5xl px-6 py-8">{children}</div>
            </main>
          </div>
        </Providers>
      </body>
    </html>
  );
}
