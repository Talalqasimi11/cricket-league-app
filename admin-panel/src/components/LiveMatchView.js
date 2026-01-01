import React, { useState, useEffect, useCallback } from 'react';
import { adminAPI } from '../services/api';

const LiveMatchView = ({ matchId, onBack, onToast }) => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const fetchLiveData = useCallback(async () => {
        try {
            const response = await adminAPI.getLiveScoreView(matchId);
            setData(response.data);
            if (loading) setLoading(false);
            setError(null);
        } catch (err) {
            console.error('Error fetching live score:', err);
            setError(err.userMessage || 'Failed to fetch live score data');
            if (loading) setLoading(false);
        }
    }, [matchId, loading]);

    useEffect(() => {
        fetchLiveData();
        const interval = setInterval(fetchLiveData, 5000); // Poll every 5 seconds
        return () => clearInterval(interval);
    }, [fetchLiveData]);

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center h-64">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mb-4"></div>
                <p className="text-gray-600 font-medium">Fetching Live Score...</p>
            </div>
        );
    }

    if (error || !data) {
        return (
            <div className="bg-white p-8 rounded-lg shadow-sm border border-gray-200 text-center">
                <div className="text-red-500 mb-4">
                    <svg className="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
                    </svg>
                </div>
                <h2 className="text-xl font-bold text-gray-900 mb-2">Live View Unavailable</h2>
                <p className="text-gray-600 mb-6">{error || 'This match does not have any live data yet.'}</p>
                <button
                    onClick={onBack}
                    className="inline-flex items-center px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 transition"
                >
                    Back to Matches
                </button>
            </div>
        );
    }

    const { innings = [], currentContext = {}, stats = {} } = data;
    const activeInning = innings.find(inn => inn.status === 'in_progress') || (innings.length > 0 ? innings[innings.length - 1] : null);

    if (!activeInning) {
        return (
            <div className="bg-white p-8 rounded-lg shadow-sm border border-gray-200 text-center">
                <h2 className="text-xl font-bold text-gray-900 mb-2">Match Not Started</h2>
                <p className="text-gray-600 mb-6">Live scoring for this match hasn't begun yet.</p>
                <button onClick={onBack} className="text-indigo-600 font-medium hover:underline">Return to Matches</button>
            </div>
        );
    }

    return (
        <div className="w-full space-y-6 animate-in fade-in duration-500">
            {/* Header & Score Card */}
            <div className="bg-indigo-900 text-white rounded-xl shadow-lg overflow-hidden">
                <div className="px-6 py-4 bg-indigo-800 flex justify-between items-center border-b border-indigo-700">
                    <button onClick={onBack} className="flex items-center text-indigo-200 hover:text-white transition">
                        <svg className="w-5 h-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" /></svg>
                        Back
                    </button>
                    <div className="flex items-center space-x-2">
                        <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
                        <span className="text-xs font-bold uppercase tracking-widest text-indigo-300">Live Admin Monitoring</span>
                    </div>
                </div>

                <div className="p-8">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-center text-center md:text-left">
                        {/* Batting Team */}
                        <div className="flex flex-col items-center md:items-start">
                            <span className="text-indigo-300 text-xs font-bold uppercase mb-1">Batting Now</span>
                            <h2 className="text-3xl font-black">{activeInning.batting_team_name}</h2>
                            <div className="mt-4 flex items-baseline">
                                <span className="text-6xl font-black leading-none">{activeInning.runs}/{activeInning.wickets}</span>
                                <span className="ml-4 text-xl text-indigo-200 font-medium tracking-tight">({activeInning.overs_decimal} ov)</span>
                            </div>
                        </div>

                        {/* Match Status / Context */}
                        <div className="flex flex-col items-center">
                            <div className="bg-indigo-800/50 px-4 py-2 rounded-full mb-4">
                                <span className="text-sm font-bold tracking-wide">Inning {activeInning.inning_number}</span>
                            </div>
                            {stats.rrr && stats.rrr !== "0.00" && (
                                <div className="text-center">
                                    <p className="text-indigo-200 text-sm mb-1 uppercase tracking-tighter font-bold">Req. Run Rate</p>
                                    <p className="text-3xl font-black text-yellow-400">{stats.rrr}</p>
                                </div>
                            )}
                            {!stats.rrr && (
                                <div className="text-center">
                                    <p className="text-indigo-200 text-sm mb-1 uppercase tracking-tighter font-bold">Curr. Run Rate</p>
                                    <p className="text-3xl font-black text-white">{stats.crr}</p>
                                </div>
                            )}
                        </div>

                        {/* Bowling Team */}
                        <div className="flex flex-col items-center md:items-end">
                            <span className="text-indigo-300 text-xs font-bold uppercase mb-1">Bowling</span>
                            <h2 className="text-3xl font-black text-white/90">{activeInning.bowling_team_name}</h2>
                            <div className="mt-4 text-sm text-indigo-200 text-right">
                                <p>Status: <span className="text-white font-bold">{data.status?.toUpperCase()}</span></p>
                                <p>Venue: <span className="text-white">{data.venue}</span></p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Detail Sections */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Left Column: Batsmen & Bowler */}
                <div className="lg:col-span-2 space-y-6">
                    {/* Batting List */}
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                        <div className="px-5 py-4 bg-gray-50 border-b border-gray-100 flex justify-between items-center">
                            <h3 className="font-bold text-gray-800 flex items-center">
                                <svg className="w-5 h-5 mr-2 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M12 14l9-5-9-5-9 5 9 5z" /><path d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" /></svg>
                                Current Batting
                            </h3>
                            {stats.partnership && (
                                <span className="text-xs bg-indigo-50 text-indigo-700 px-3 py-1 rounded-full font-bold">
                                    Partnership: {stats.partnership.runs} ({stats.partnership.balls})
                                </span>
                            )}
                        </div>
                        <div className="divide-y divide-gray-50">
                            {currentContext.batsmen?.length > 0 ? (
                                currentContext.batsmen.map((batsman, idx) => (
                                    <div key={batsman.player_id} className="p-5 flex justify-between items-center transition hover:bg-gray-50">
                                        <div>
                                            <div className="font-bold text-gray-900 flex items-center">
                                                {batsman.player_name}
                                                {idx === 0 && <span className="ml-2 w-2 h-2 bg-green-500 rounded-full"></span>}
                                            </div>
                                            <p className="text-xs text-gray-500 font-medium">SR: {batsman.balls_faced > 0 ? ((batsman.runs / batsman.balls_faced) * 100).toFixed(1) : '0.0'}</p>
                                        </div>
                                        <div className="text-right">
                                            <span className="text-2xl font-black text-indigo-600">{batsman.runs}</span>
                                            <span className="ml-2 text-sm text-gray-400 font-bold">({batsman.balls_faced})</span>
                                        </div>
                                    </div>
                                ))
                            ) : (
                                <div className="p-8 text-center text-gray-400 italic">No batsmen currently at the crease</div>
                            )}
                        </div>
                    </div>

                    {/* Bowler Details */}
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                        <div className="px-5 py-4 bg-gray-50 border-b border-gray-100">
                            <h3 className="font-bold text-gray-800 flex items-center">
                                <svg className="w-5 h-5 mr-2 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 2m6-2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                                Current Bowler
                            </h3>
                        </div>
                        {currentContext.bowler ? (
                            <div className="p-6 flex items-center justify-between">
                                <div className="flex items-center space-x-4">
                                    <div className="bg-red-50 p-3 rounded-full">
                                        <svg className="w-8 h-8 text-red-500" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM7 9H5v2h2V9zm8 0h-2v2h2V9zM9 9h2v2H9V9z" clipRule="evenodd" /></svg>
                                    </div>
                                    <div>
                                        <h4 className="font-black text-xl text-gray-900">{currentContext.bowler.player_name}</h4>
                                        <p className="text-xs text-gray-500 font-bold uppercase tracking-widest mt-1">Efficiency: {currentContext.bowler.balls_bowled > 0 ? (currentContext.bowler.runs_conceded / (currentContext.bowler.balls_bowled / 6)).toFixed(2) : '0'}</p>
                                    </div>
                                </div>
                                <div className="text-right bg-red-50 px-6 py-3 rounded-xl">
                                    <span className="block text-xs font-extrabold text-red-400 uppercase tracking-tighter">Figures</span>
                                    <p className="text-2xl font-black text-red-700">
                                        {currentContext.bowler.wickets} - {currentContext.bowler.runs_conceded}
                                        <span className="text-sm ml-2 text-red-400">({(currentContext.bowler.balls_bowled / 6).toFixed(0)}.{currentContext.bowler.balls_bowled % 6})</span>
                                    </p>
                                </div>
                            </div>
                        ) : (
                            <div className="p-8 text-center text-gray-400 italic">No bowler currently active</div>
                        )}
                    </div>
                </div>

                {/* Right Column: Timeline */}
                <div className="space-y-6">
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 h-full overflow-hidden flex flex-col">
                        <div className="px-5 py-4 bg-gray-50 border-b border-gray-100 flex justify-between items-center">
                            <h3 className="font-bold text-gray-800 flex items-center">
                                <svg className="w-5 h-5 mr-2 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                                Recent Balls
                            </h3>
                        </div>
                        <div className="p-5 flex-1 bg-gray-50/30">
                            <div className="flex flex-wrap gap-2">
                                {currentContext.recentBalls?.length > 0 ? (
                                    currentContext.recentBalls.map((ball, i) => (
                                        <div
                                            key={i}
                                            className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-black shadow-sm border-2 ${ball.wicket_type ? 'bg-red-600 border-red-700 text-white animate-bounce' :
                                                    ball.runs === 4 ? 'bg-indigo-600 border-indigo-700 text-white' :
                                                        ball.runs === 6 ? 'bg-purple-600 border-purple-700 text-white animate-pulse' :
                                                            ball.extras ? 'bg-yellow-400 border-yellow-500 text-yellow-900' :
                                                                'bg-white border-gray-200 text-gray-700'
                                                }`}
                                        >
                                            {ball.wicket_type ? 'W' : (ball.extras ? `${ball.runs}ex` : ball.runs)}
                                        </div>
                                    ))
                                ) : (
                                    <div className="w-full text-center py-12 text-gray-400 text-sm italic">Over just beginning...</div>
                                )}
                            </div>

                            {/* Helper Key */}
                            <div className="mt-8 pt-6 border-t border-gray-100 grid grid-cols-2 gap-3 text-[10px] font-bold uppercase tracking-tight text-gray-400">
                                <div className="flex items-center"><span className="w-2 h-2 rounded-full bg-red-600 mr-2"></span> Wicket</div>
                                <div className="flex items-center"><span className="w-2 h-2 rounded-full bg-purple-600 mr-2"></span> Six</div>
                                <div className="flex items-center"><span className="w-2 h-2 rounded-full bg-indigo-600 mr-2"></span> Four</div>
                                <div className="flex items-center"><span className="w-2 h-2 rounded-full bg-yellow-400 mr-2"></span> Extra</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default LiveMatchView;
