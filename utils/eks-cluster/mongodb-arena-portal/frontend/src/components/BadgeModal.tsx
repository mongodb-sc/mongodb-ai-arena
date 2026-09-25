'use client'

import { useState, useEffect, useRef } from 'react'
import { createPortal } from 'react-dom'

interface BadgeModalProps {
  participantId: string
  participantName: string
  onClose: () => void
}

interface BadgeMeta {
  name: string
  description: string
  image_url: string
  skills: string[]
  url: string
}

interface BadgeConfig {
  enabled: boolean
  bonus_points: number
  max_attempts: number
  badge_template_id: string
  badge: BadgeMeta | null
}

interface CredlyInfo {
  accept_badge_url?: string
  badge_url?: string
  state?: string
  issued_at?: string
}

interface BadgeStatus {
  status: string
  passed?: boolean
  score?: number
  points_earned?: number
  points_available?: number
  used_seconds?: number
  bonus_awarded?: boolean
  attempt_number?: number
  max_attempts?: number
  launch_url?: string
  credly?: CredlyInfo | null
  error?: string
}

const formatExamTime = (seconds: number): string => {
  if (!seconds) return '0s'
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  if (m > 0) return `${m}m ${s}s`
  return `${s}s`
}

const FALLBACK_IMAGE = 'https://images.credly.com/images/660bba4a-fb7d-4112-b1c6-2904a420ad25/blob'
const FALLBACK_SKILLS = ['Continuous Training', 'Learning And Development', 'Professional Development', 'Upskilling']

const BadgeModal: React.FC<BadgeModalProps> = ({ participantId, participantName, onClose }) => {
  const [config, setConfig] = useState<BadgeConfig | null>(null)
  const [status, setStatus] = useState<BadgeStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [starting, setStarting] = useState(false)
  const [error, setError] = useState('')
  const [launchUrl, setLaunchUrl] = useState<string | null>(null)
  const pollRef = useRef<NodeJS.Timeout | null>(null)

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000'

  const fetchConfig = async () => {
    try {
      const res = await fetch(`${apiUrl}/api/skill-badge/config`)
      const data = await res.json()
      setConfig(data)
    } catch (err) {
      setError('Failed to load badge configuration')
    }
  }

  const fetchStatus = async () => {
    try {
      const res = await fetch(`${apiUrl}/api/skill-badge/status/${encodeURIComponent(participantId)}`)
      const data = await res.json()
      setStatus(data)

      const finished = data.status === 'scored' || data.status === 'completed' || data.status === 'complete' || data.bonus_awarded
      if (finished) {
        stopPolling()
        setLaunchUrl(null)
      }
    } catch (err) {
      console.error('Error fetching badge status:', err)
    }
  }

  const startPolling = () => {
    stopPolling()
    pollRef.current = setInterval(fetchStatus, 10000)
  }

  const stopPolling = () => {
    if (pollRef.current) {
      clearInterval(pollRef.current)
      pollRef.current = null
    }
  }

  useEffect(() => {
    const init = async () => {
      setLoading(true)
      await fetchConfig()
      await fetchStatus()
      setLoading(false)
    }
    init()
    return () => stopPolling()
  }, [participantId])

  useEffect(() => {
    if (status && !isNotStarted && !isFinished && !status.bonus_awarded) {
      startPolling()
    }
    return () => stopPolling()
  }, [status?.status])

  const handleStartExam = async () => {
    setStarting(true)
    setError('')
    try {
      const res = await fetch(`${apiUrl}/api/skill-badge/start`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ participant_id: participantId })
      })
      const data = await res.json()

      if (!res.ok || !data.success) {
        setError(data.error || 'Failed to start exam')
        setStarting(false)
        return
      }

      setLaunchUrl(data.launch_url)
      await fetchStatus()
      startPolling()
    } catch (err) {
      setError('Failed to start exam: ' + (err as Error).message)
    } finally {
      setStarting(false)
    }
  }

  const bonusPoints = config?.bonus_points ?? parseInt(process.env.NEXT_PUBLIC_SKILL_BADGE_BONUS_POINTS || '50')
  const badgeMeta = config?.badge
  const badgeName = badgeMeta?.name || 'Skill Badge'
  const badgeDesc = badgeMeta?.description || ''
  const badgeImage = badgeMeta?.image_url || FALLBACK_IMAGE
  const badgeSkills = badgeMeta?.skills?.length ? badgeMeta.skills : FALLBACK_SKILLS

  const isPassed = status?.passed === true
  const isFinished = status?.status === 'scored' || status?.status === 'completed' || status?.status === 'complete'
  const isFailed = isFinished && status?.passed === false
  const isNotStarted = !status || status.status === 'not_started' || status.status === 'fresh' || status.status === 'created'
  const isInProgress = !isFinished && !status?.bonus_awarded && !isNotStarted && !isFailed
  const canRetry = isFailed && (status?.attempt_number || 1) < (status?.max_attempts || config?.max_attempts || 1)
  const showExamIframe = !!launchUrl && !isFinished && !isFailed && !isPassed

  const credly = status?.credly
  const credlyState = credly?.state
  const credlyClaimUrl = credly?.accept_badge_url
  const credlyBadgeUrl = credly?.badge_url

  const borderColor = isPassed ? 'border-arena-neon-green' : showExamIframe ? 'border-blue-500' : 'border-amber-500'

  if (typeof document === 'undefined') return null

  if (loading) {
    return createPortal(
      <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 99999, display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: 'rgba(0,0,0,0.75)' }}>
        <div className="bg-arena-dark border-2 border-arena-neon-green rounded-lg shadow-2xl p-6 max-w-lg w-full mx-4" onClick={e => e.stopPropagation()}>
          <div className="text-center py-8">
            <div className="animate-spin rounded-full h-12 w-12 border-4 border-arena-neon-green border-t-transparent mx-auto"></div>
            <p className="text-gray-300 mt-4">Loading badge info...</p>
          </div>
        </div>
      </div>,
      document.body
    )
  }

  // Exam iframe mode — fullscreen modal with embedded Scorpion exam
  if (showExamIframe) {
    return createPortal(
      <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 99999, display: 'flex', flexDirection: 'column', background: '#0b1120' }}>
        {/* Compact header bar */}
        <div className="flex items-center justify-between px-4 py-2 bg-arena-dark-light border-b border-blue-500/50">
          <div className="flex items-center gap-3">
            <img src={badgeImage} alt={badgeName} className="w-8 h-8 rounded" />
            <div>
              <span className="text-white font-semibold text-sm">{badgeName}</span>
              <span className="text-gray-400 text-xs ml-2">— {participantName}</span>
            </div>
            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-semibold bg-blue-500/15 text-blue-400 border border-blue-500/30">
              <div className="animate-spin rounded-full h-3 w-3 border-2 border-blue-400 border-t-transparent"></div>
              Exam in progress — polling for results
            </span>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-red-400 text-sm font-medium px-3 py-1 border border-gray-600 rounded hover:border-red-400 transition-colors"
          >
            Close
          </button>
        </div>

        {/* Scorpion exam iframe */}
        <iframe
          src={launchUrl}
          className="flex-1 w-full border-0"
          allow="camera; microphone"
          title="Skill Badge Exam"
        />
      </div>,
      document.body
    )
  }

  // Standard modal — before exam, results, or retry
  return createPortal(
    <div onClick={onClose} style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 99999, display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: 'rgba(0,0,0,0.75)' }}>
      <div
        className={`bg-arena-dark border-2 ${borderColor} rounded-lg shadow-2xl p-6 max-w-2xl w-full mx-4 max-h-[85vh] overflow-y-auto`}
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex justify-between items-start mb-6">
          <div className="flex gap-4 items-center">
            <img
              src={badgeImage}
              alt={badgeName}
              className="w-20 h-20 rounded-lg border-2 border-gray-600"
            />
            <div>
              <h3 className="text-xl font-bold text-white">{badgeName}</h3>
              {badgeDesc && <p className="text-sm text-gray-400">{badgeDesc}</p>}
              <p className="text-sm text-arena-neon-green mt-1">Issued by MongoDB</p>
              {isPassed && (
                <span className="inline-flex items-center gap-1.5 mt-2 px-3 py-1 rounded-lg text-sm font-bold bg-arena-neon-green/15 text-arena-neon-green border border-arena-neon-green/40">
                  &#10003; Credential Earned &middot; +{bonusPoints} Bonus Applied
                </span>
              )}
              {(isNotStarted || canRetry) && (
                <span className="inline-flex items-center gap-1.5 mt-2 px-3 py-1 rounded-lg text-sm font-bold bg-amber-500/12 text-amber-400 border border-amber-500/30">
                  &#128640; Available to Earn &middot; +{bonusPoints} Bonus Points
                </span>
              )}
              {isFailed && !canRetry && (
                <span className="inline-flex items-center gap-1.5 mt-2 px-3 py-1 rounded-lg text-sm font-bold bg-red-500/12 text-red-400 border border-red-500/30">
                  Not Passed &middot; No Retries Remaining
                </span>
              )}
            </div>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-arena-neon-green text-3xl leading-none transition-colors">
            &times;
          </button>
        </div>

        {/* Participant name */}
        <p className="text-sm text-gray-400 mb-4">
          Participant: <span className="text-white font-medium">{participantName}</span>
        </p>

        {/* Score tiles (shown after exam completes) */}
        {(isPassed || isFailed) && status && (
          <div className={`grid grid-cols-2 ${isPassed ? 'sm:grid-cols-5' : 'sm:grid-cols-4'} gap-3 mb-5`}>
            <div className="text-center p-3 bg-arena-dark-light/60 border border-gray-700 rounded-lg">
              <div className="text-[0.65rem] uppercase text-gray-500 tracking-wider mb-1">Score</div>
              <div className={`text-lg font-bold ${isPassed ? 'text-arena-neon-green' : 'text-red-400'}`}>
                {status.points_earned ?? '—'} / {status.points_available ?? '—'}
              </div>
            </div>
            <div className="text-center p-3 bg-arena-dark-light/60 border border-gray-700 rounded-lg">
              <div className="text-[0.65rem] uppercase text-gray-500 tracking-wider mb-1">Result</div>
              <div className={`text-lg font-bold ${isPassed ? 'text-arena-neon-green' : 'text-red-400'}`}>
                {isPassed ? 'PASSED' : 'NOT PASSED'}
              </div>
            </div>
            <div className="text-center p-3 bg-arena-dark-light/60 border border-gray-700 rounded-lg">
              <div className="text-[0.65rem] uppercase text-gray-500 tracking-wider mb-1">Time</div>
              <div className="text-lg font-bold text-gray-200">
                {status.used_seconds != null ? formatExamTime(status.used_seconds) : '—'}
              </div>
            </div>
            <div className="text-center p-3 bg-arena-dark-light/60 border border-gray-700 rounded-lg">
              <div className="text-[0.65rem] uppercase text-gray-500 tracking-wider mb-1">Attempt</div>
              <div className="text-lg font-bold text-gray-200">
                {status.attempt_number ?? 1} / {status.max_attempts ?? config?.max_attempts ?? 1}
              </div>
            </div>
            {isPassed && (
              <div className="text-center p-3 bg-arena-dark-light/60 border border-gray-700 rounded-lg">
                <div className="text-[0.65rem] uppercase text-gray-500 tracking-wider mb-1">Credly Status</div>
                <div className={`text-lg font-bold ${credlyState === 'accepted' ? 'text-arena-neon-green' : credlyState ? 'text-amber-400' : 'text-gray-500'}`}>
                  {credlyState === 'accepted' ? 'Claimed' : credlyState === 'pending' ? 'Issued' : credlyState || 'Pending'}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Skill tags */}
        <div className="flex flex-wrap gap-2 mb-5">
          {badgeSkills.map(skill => (
            <span key={skill} className="px-2.5 py-1 bg-purple-500/15 text-purple-400 border border-purple-500/30 rounded-full text-xs font-medium">
              {skill}
            </span>
          ))}
        </div>

        {/* Error */}
        {error && (
          <div className="mb-4 p-3 bg-red-900/30 border border-red-500 text-red-300 rounded-lg text-sm">
            {error}
          </div>
        )}

        {/* Exam in progress but no iframe (reopened modal) */}
        {isInProgress && !showExamIframe && (
          <div className="text-center py-4 mb-4">
            <div className="flex items-center justify-center gap-2 mb-3">
              <div className="animate-spin rounded-full h-5 w-5 border-3 border-blue-400 border-t-transparent"></div>
              <p className="text-white font-medium">Exam in progress — polling for results</p>
            </div>
            {status && status.launch_url && (
              <a
                href={status.launch_url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg font-bold text-arena-dark bg-gradient-to-r from-blue-400 to-blue-600 hover:from-blue-300 hover:to-blue-500 transition-all mt-2"
              >
                &#128221; Resume Exam in New Tab
              </a>
            )}
            <p className="text-gray-500 text-xs mt-3">Results will appear here automatically when the exam is complete.</p>
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-3 justify-center mt-6">
          {(isNotStarted || canRetry) && (
            <button
              onClick={handleStartExam}
              disabled={starting}
              className="inline-flex items-center gap-2 px-6 py-3 rounded-lg font-bold text-arena-dark bg-gradient-to-r from-amber-400 to-amber-600 hover:from-amber-300 hover:to-amber-500 transition-all disabled:opacity-50"
            >
              {starting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-2 border-arena-dark border-t-transparent"></div>
                  Creating Delivery...
                </>
              ) : (
                <>
                  &#127941; {canRetry ? 'Retry Exam' : 'Start Skill Badge Exam'}
                </>
              )}
            </button>
          )}

          {isPassed && (
            <>
              {credlyClaimUrl ? (
                <a
                  href={credlyClaimUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-lg font-bold bg-arena-neon-green text-arena-dark hover:bg-arena-bright-green transition-colors"
                >
                  {credlyState === 'accepted' ? 'View Your Badge on Credly' : 'Claim Your Badge on Credly'}
                </a>
              ) : credlyBadgeUrl ? (
                <a
                  href={credlyBadgeUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-lg font-bold bg-arena-neon-green text-arena-dark hover:bg-arena-bright-green transition-colors"
                >
                  View Your Badge on Credly
                </a>
              ) : (
                <span className="inline-flex items-center gap-2 px-6 py-3 rounded-lg font-bold bg-gray-700 text-gray-400 cursor-default">
                  Credly badge pending issuance...
                </span>
              )}
              <button
                onClick={onClose}
                className="inline-flex items-center px-6 py-3 rounded-lg font-semibold text-gray-200 border border-gray-600 hover:border-arena-neon-green hover:text-arena-neon-green transition-colors"
              >
                Close
              </button>
            </>
          )}

          {isFailed && !canRetry && (
            <button
              onClick={onClose}
              className="px-6 py-3 bg-arena-neon-green text-arena-dark rounded-lg hover:bg-arena-bright-green transition-colors font-medium"
            >
              Close
            </button>
          )}
        </div>
      </div>
    </div>,
    document.body
  )
}

export default BadgeModal
