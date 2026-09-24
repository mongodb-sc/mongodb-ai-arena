import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Leaderboard Display',
  description: 'Live leaderboard display for venue monitors',
}

export default function DisplayLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return children
}
