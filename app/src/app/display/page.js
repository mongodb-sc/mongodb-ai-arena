"use client";

import React, { useEffect, useState, useCallback } from 'react';

const medalImages = {
  0: `${process.env.BASE_PATH}/win-first.png`,
  1: `${process.env.BASE_PATH}/win-second.png`,
  2: `${process.env.BASE_PATH}/win-third.png`
};

const winImage = `${process.env.BASE_PATH}/win.png`;

const formatTime = (milliseconds) => {
  if (milliseconds === 0) return '0m';
  const seconds = Math.floor(milliseconds / 1000);
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = seconds % 60;
  let result = '';
  if (hours > 0) result += `${hours}h `;
  if (minutes > 0) result += `${minutes}m`;
  else if (hours === 0 && remainingSeconds > 0) result += `${remainingSeconds}s`;
  return result.trim();
};

const REFRESH_INTERVAL = 60000;

const DisplayLeaderboard = () => {
  const [results, setResults] = useState(null);
  const [leaderboardType, setLeaderboardType] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(null);

  const fetchData = useCallback(() => {
    fetch(`${process.env.BASE_URL}/api/results`)
      .then(response => response.json())
      .then(data => {
        setResults(data.results);
        setLeaderboardType(data.leaderboardType);
        setLastUpdated(new Date());
        setIsLoading(false);
      })
      .catch(error => {
        console.error('Error fetching data:', error);
        setIsLoading(false);
      });
  }, []);

  useEffect(() => {
    const header = document.querySelector('header');
    const footer = document.querySelector('footer');
    if (header) header.style.display = 'none';
    if (footer) footer.style.display = 'none';
    document.body.style.background = '#0f172a';

    return () => {
      if (header) header.style.display = '';
      if (footer) footer.style.display = '';
      document.body.style.background = '';
    };
  }, []);

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, REFRESH_INTERVAL);
    return () => clearInterval(interval);
  }, [fetchData]);

  if (isLoading) {
    return (
      <div className="fixed inset-0 flex items-center justify-center" style={{ background: '#0f172a' }}>
        <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-b-4 border-emerald-400"></div>
      </div>
    );
  }

  if (!results || (Array.isArray(results) && results.length === 0) || (typeof results === 'object' && Object.keys(results).length === 0)) {
    return (
      <div className="fixed inset-0 flex items-center justify-center" style={{ background: '#0f172a' }}>
        <h2 className="text-4xl text-white">No results available</h2>
      </div>
    );
  }

  let sortedData;
  if (leaderboardType === 'timed') {
    sortedData = results.map(user => ({
      user: user.name || user._id,
      count: user.count || 0,
      delta: user.delta?.$numberLong ? parseInt(user.delta.$numberLong) : (user.delta || 0)
    }))
    .sort((a, b) => {
      if (b.count !== a.count) return b.count - a.count;
      return a.delta - b.delta;
    });
  } else {
    sortedData = Object.entries(results)
      .map(([user, points]) => ({ user, points }))
      .sort((a, b) => b.points - a.points);
  }

  const topTen = sortedData.slice(0, 10);

  return (
    <div className="fixed inset-0 flex flex-col" style={{ background: '#0f172a', color: '#f1f5f9' }}>
      <div className="text-center py-6">
        <h1 className="text-5xl font-bold tracking-tight" style={{ color: '#4ade80' }}>
          Leaderboard
        </h1>
      </div>

      <div className="flex-grow flex items-start justify-center px-8 overflow-hidden">
        <table className="w-full max-w-5xl text-2xl">
          <thead>
            <tr style={{ borderBottom: '2px solid #334155' }}>
              <th className="px-6 py-4 text-left" style={{ color: '#94a3b8', width: '80px' }}>#</th>
              <th className="px-6 py-4 text-left" style={{ color: '#94a3b8' }}>User</th>
              {leaderboardType === 'timed' ? (
                <>
                  <th className="px-6 py-4 text-right" style={{ color: '#94a3b8' }}>Exercises</th>
                  <th className="px-6 py-4 text-right" style={{ color: '#94a3b8' }}>Time</th>
                </>
              ) : (
                <th className="px-6 py-4 text-right" style={{ color: '#94a3b8' }}>Points</th>
              )}
            </tr>
          </thead>
          <tbody>
            {topTen.map((row, index) => (
              <tr
                key={row.user}
                style={{
                  borderBottom: '1px solid #1e293b',
                  background: index === 0 ? 'rgba(74, 222, 128, 0.08)' : 'transparent'
                }}
              >
                <td className="px-6 py-4 text-center">
                  {index < 3 ? (
                    <img
                      src={medalImages[index]}
                      alt={`${index + 1}`}
                      className="inline"
                      style={{ width: '36px', height: '36px' }}
                    />
                  ) : (
                    <span className="flex items-center justify-center gap-2">
                      <img
                        src={winImage}
                        alt="win"
                        className="inline"
                        style={{ width: '28px', height: '28px' }}
                      />
                      <span style={{ color: '#64748b' }}>{index + 1}</span>
                    </span>
                  )}
                </td>
                <td className="px-6 py-4 font-semibold">
                  {row.user}
                </td>
                {leaderboardType === 'timed' ? (
                  <>
                    <td className="px-6 py-4 text-right font-mono">{row.count}</td>
                    <td className="px-6 py-4 text-right font-mono">{formatTime(row.delta)}</td>
                  </>
                ) : (
                  <td className="px-6 py-4 text-right font-mono" style={{ color: '#4ade80' }}>{row.points}</td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-center py-4" style={{ color: '#475569', fontSize: '0.875rem' }}>
        {lastUpdated && `Last updated: ${lastUpdated.toLocaleTimeString()}`}
        {' · '}
        Refreshes every 60s
      </div>
    </div>
  );
};

export default DisplayLeaderboard;
