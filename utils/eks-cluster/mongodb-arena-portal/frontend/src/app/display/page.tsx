'use client'

import { useState, useEffect, useCallback, useMemo } from 'react'

const skillBadgeEnabled = process.env.NEXT_PUBLIC_SKILL_BADGE_ENABLED === 'true'
const skillBadgeBonusPoints = parseInt(process.env.NEXT_PUBLIC_SKILL_BADGE_BONUS_POINTS || '50')

const formatTime = (milliseconds: number): string => {
  if (milliseconds === 0) return '0m'
  const seconds = Math.floor(milliseconds / 1000)
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const remainingSeconds = seconds % 60
  let result = ''
  if (hours > 0) result += `${hours}h `
  if (minutes > 0) result += `${minutes}m`
  else if (hours === 0 && remainingSeconds > 0) result += `${remainingSeconds}s`
  return result.trim()
}

interface TimedResult {
  name?: string
  _id: string
  count?: number
  delta?: { $numberLong?: string } | number
}

interface ScoreResult {
  [username: string]: number
}

interface LeaderboardData {
  results: TimedResult[] | ScoreResult
  leaderboardType: 'timed' | 'score'
}

const REFRESH_INTERVAL = 60000

export default function DisplayLeaderboard() {
  const [data, setData] = useState<LeaderboardData | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [badgeStatuses, setBadgeStatuses] = useState<Record<string, { passed?: boolean; bonus_awarded?: boolean }>>({})

  const fetchBadgeStatuses = useCallback(async () => {
    if (!skillBadgeEnabled) return
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000'
      const res = await fetch(`${apiUrl}/api/skill-badge/statuses`)
      const data = await res.json()
      if (data.statuses) setBadgeStatuses(data.statuses)
    } catch (err) {
      console.error('Error fetching badge statuses:', err)
    }
  }, [])

  const fetchData = useCallback(async () => {
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000'
      const response = await fetch(`${apiUrl}/api/results`)
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const json = await response.json()
      setData({ results: json.results, leaderboardType: json.leaderboardType })
      setLastUpdated(new Date())
    } catch (error) {
      console.error('Error fetching leaderboard:', error)
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchData()
    fetchBadgeStatuses()
    const interval = setInterval(() => {
      fetchData()
      fetchBadgeStatuses()
    }, REFRESH_INTERVAL)
    return () => clearInterval(interval)
  }, [fetchData, fetchBadgeStatuses])

  const sortedData = useMemo(() => {
    if (!data?.results) return []

    const { results, leaderboardType } = data

    if (Array.isArray(results) && results.length === 0) return []
    if (typeof results === 'object' && !Array.isArray(results) && Object.keys(results).length === 0) return []

    if (leaderboardType === 'timed' && Array.isArray(results)) {
      return results
        .map((user: TimedResult) => ({
          user: user.name || user._id,
          _id: user._id,
          count: user.count || 0,
          delta:
            user.delta && typeof user.delta === 'object' && user.delta.$numberLong
              ? parseInt(user.delta.$numberLong)
              : typeof user.delta === 'number'
                ? user.delta
                : 0,
        }))
        .sort((a, b) => {
          if (b.count !== a.count) return b.count - a.count
          return a.delta - b.delta
        })
    }

    return Object.entries(results as ScoreResult)
      .map(([user, points]) => ({ user, _id: user, points }))
      .sort((a, b) => (b.points || 0) - (a.points || 0))
  }, [data])

  const topTen = sortedData.slice(0, 10)
  const leaderboardType = data?.leaderboardType

  if (isLoading) {
    return (
      <div className="fixed inset-0 circuit-bg flex items-center justify-center">
        <div className="animate-spin rounded-full h-16 w-16 border-4 border-arena-neon-green border-t-transparent"></div>
      </div>
    )
  }

  if (sortedData.length === 0) {
    return (
      <div className="fixed inset-0 circuit-bg flex items-center justify-center">
        <h2 className="text-4xl text-white">No results available yet</h2>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 circuit-bg flex flex-col overflow-hidden">
      {/* Header */}
      <div className="text-center py-6 flex-shrink-0">
        <h1 className="text-5xl font-bold text-arena-neon-green neon-glow tracking-tight">
          Leaderboard
        </h1>
        <div className="mt-2">
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-arena-teal/40 text-arena-neon-green border border-arena-neon-green/50">
            {leaderboardType === 'timed' ? 'Timed' : 'Score'} Mode
          </span>
        </div>
      </div>

      {/* Table */}
      <div className="flex-grow flex items-start justify-center px-8">
        <table className="w-full max-w-5xl text-2xl">
          <thead>
            <tr className="border-b-2 border-arena-teal">
              <th className="px-6 py-4 text-left text-arena-neon-green uppercase tracking-wider text-base font-medium" style={{ width: '100px' }}>
                Rank
              </th>
              <th className="px-6 py-4 text-left text-arena-neon-green uppercase tracking-wider text-base font-medium">
                User
              </th>
              {leaderboardType === 'timed' ? (
                <>
                  <th className="px-6 py-4 text-right text-arena-neon-green uppercase tracking-wider text-base font-medium">
                    Exercises
                  </th>
                  {skillBadgeEnabled && (
                    <>
                      <th className="px-6 py-4 text-right text-arena-neon-green uppercase tracking-wider text-base font-medium">
                        Boost
                      </th>
                      <th className="px-6 py-4 text-right text-arena-neon-green uppercase tracking-wider text-base font-medium">
                        Total
                      </th>
                    </>
                  )}
                  <th className="px-6 py-4 text-right text-arena-neon-green uppercase tracking-wider text-base font-medium">
                    Time
                  </th>
                </>
              ) : (
                <>
                  <th className="px-6 py-4 text-right text-arena-neon-green uppercase tracking-wider text-base font-medium">
                    Points
                  </th>
                  {skillBadgeEnabled && (
                    <>
                      <th className="px-6 py-4 text-right text-arena-neon-green uppercase tracking-wider text-base font-medium">
                        Boost
                      </th>
                      <th className="px-6 py-4 text-right text-arena-neon-green uppercase tracking-wider text-base font-medium">
                        Total
                      </th>
                    </>
                  )}
                </>
              )}
            </tr>
          </thead>
          <tbody>
            {topTen.map((row, index) => {
              const rank = index + 1
              return (
                <tr
                  key={row.user}
                  className={rank <= 3 ? 'bg-gradient-to-r from-slate-600/20 to-gray-500/15' : ''}
                  style={{ borderBottom: '1px solid rgba(19, 78, 74, 0.5)' }}
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center justify-start">
                      <div
                        className={`w-12 h-12 rounded-full flex items-center justify-center text-white font-bold text-lg shadow-lg ${
                          rank === 1
                            ? 'bg-gradient-to-br from-yellow-400 to-yellow-600'
                            : rank === 2
                              ? 'bg-gradient-to-br from-gray-300 to-gray-500'
                              : rank === 3
                                ? 'bg-gradient-to-br from-orange-400 to-orange-700'
                                : 'bg-arena-neon-green text-arena-dark'
                        }`}
                      >
                        {rank}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 font-semibold text-white">
                    {row.user}
                  </td>
                  {(() => {
                    const earned = skillBadgeEnabled && badgeStatuses[row._id]?.bonus_awarded === true
                    const count = 'count' in row ? (row.count as number) : 0
                    const points = 'points' in row ? (row.points as number) : 0

                    return leaderboardType === 'timed' ? (
                      <>
                        <td className="px-6 py-4 text-right font-mono text-white">
                          {earned ? count - 1 : count}
                        </td>
                        {skillBadgeEnabled && (
                          <>
                            <td className="px-6 py-4 text-right font-mono">
                              {earned ? (
                                <span className="text-arena-neon-green font-semibold">+1</span>
                              ) : (
                                <span className="text-gray-500">—</span>
                              )}
                            </td>
                            <td className="px-6 py-4 text-right font-mono text-white font-semibold">
                              {count}
                            </td>
                          </>
                        )}
                        <td className="px-6 py-4 text-right font-mono text-white">
                          {formatTime('delta' in row ? (row.delta as number) : 0)}
                        </td>
                      </>
                    ) : (
                      <>
                        <td className="px-6 py-4 text-right font-mono text-arena-neon-green text-3xl">
                          {earned ? points - skillBadgeBonusPoints : points}
                        </td>
                        {skillBadgeEnabled && (
                          <>
                            <td className="px-6 py-4 text-right font-mono">
                              {earned ? (
                                <span className="text-arena-neon-green font-semibold">+{skillBadgeBonusPoints}</span>
                              ) : (
                                <span className="text-gray-500">—</span>
                              )}
                            </td>
                            <td className="px-6 py-4 text-right font-mono text-arena-neon-green text-3xl font-semibold">
                              {points}
                            </td>
                          </>
                        )}
                      </>
                    )
                  })()}
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* Footer */}
      <div className="text-center py-4 flex-shrink-0 text-gray-500 text-sm">
        {lastUpdated && `Last updated: ${lastUpdated.toLocaleTimeString()}`}
        {' · '}
        Auto-refreshes every 60s
      </div>
    </div>
  )
}
